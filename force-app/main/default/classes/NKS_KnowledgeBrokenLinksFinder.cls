public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<Id, List<String>> finalList = new Map<Id, List<String>>();
    private List<String> links = new List<String>{
        'afp.no',
        'akan.no',
        'altinn.no',
        'anskaffelser.no',
        'arbeidsmiljoportalen.no', // returns 200 for invalid links
        'arbeidsplassen.no',
        'arbeidstilsynet.no',
        'behandlingshjelpemidler.no',
        'brreg.no',
        'bufdir.no',
        'deterdinpensjon.no',
        'doffin.no',
        'domstol.no',
        'ehelse.no',
        'eid.difi.no', // returns 200 for invalid links
        'facebook.com',
        'garantikassen.no',
        'helfo.no',
        'helsedirektoratet.no',
        'helsenorge.no',
        'husbanken.no',
        'huseieren.no',
        'idebanken.org',
        'imdi.no',
        'jobbmesse.no', // returns 200 for invalid links
        'karriereveiledning.no',
        'klp.no',
        'konkursradet.no',
        'lovdata.no',
        'nav.no',
        'nav.sabacloud.com',
        'norskpensjon.no',
        'politiet.no',
        'skatteetaten.no',
        'spk.no',
        'norge.no',
        'register.helsedirektoratet.no',
        'regjeringen.no',
        'udi.no',
        'utdanning.no',
        'veiviseren.no',
        'vilbli.no',
        'vimeo.com',
        'youtube.com'
    };

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Knowledge__kav WHERE PublishStatus = \'Online\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        String regex1 = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        Pattern linksPattern = Pattern.compile(regex1);

        for (Knowledge__kav article : [
            SELECT
                AdvisorInformation__c,
                AdvisorInformationInternal__c,
                Article__c,
                EmployerInformation__c,
                EmployerInformationInternal__c,
                NKS_English__c,
                InternationalInformation__c,
                InternationalInformationInternal__c,
                NKS_Legislation__c,
                NKS_Nav_no__c,
                NKS_Nynorsk__c,
                NKS_Resources__c,
                NKS_Summary__c,
                NKS_UserInformation__c,
                WhoDoesWhat__c
            FROM Knowledge__kav
            WHERE Id IN :scope
        ]) {
            Set<String> matches = new Set<String>();
            List<String> resultList = new List<String>();

            // get all text fields for each article
            List<String> strList = new List<String>{
                article.AdvisorInformation__c,
                article.AdvisorInformationInternal__c,
                article.Article__c,
                article.EmployerInformation__c,
                article.EmployerInformationInternal__c,
                article.NKS_English__c,
                article.InternationalInformation__c,
                article.InternationalInformationInternal__c,
                article.NKS_Legislation__c,
                article.NKS_Nav_no__c,
                article.NKS_Nynorsk__c,
                article.NKS_Resources__c,
                article.NKS_Summary__c,
                article.NKS_UserInformation__c,
                article.WhoDoesWhat__c
            };

            if (strList.size() > 0) {
                // find all links
                for (String str : strList) {
                    try {
                        Matcher matcher = linksPattern.matcher(str);
                        while (matcher.find()) {
                            String groupValue = matcher.group();
                            matches.add(groupValue);
                        }
                    } catch (Exception ex) {
                        //System.debug(ex.getMessage());
                    }
                }
            }
            //System.debug('Matches: ' + matches);

            /**
             * Endpoints defined as named credentials
             */
            if (matches.size() > 0) {
                for (String str : matches) {
                    HttpRequest req = new HttpRequest();

                    if (Test.isRunningTest()) {
                        System.debug('Running tests.');
                    } else {
                        Integer statusCode = 0;
                        for (String link : links) {
                            if (str.contains(link)) {
                                try {
                                    HttpResponse res = calloutHttpReq(
                                        req,
                                        'callout:' +
                                        link.replace('.', '_') +
                                        str.substringAfter(link)
                                    );
                                    statusCode = detectRedirect(req, res);
                                    if (statusCode != 200 && statusCode != 500) {
                                        resultList.add(str);
                                    }
                                } catch (Exception ex) {
                                    //System.debug('It is possbile this link is broken, check the link.');
                                }
                            }
                        }
                    }
                }
            }
            if (resultList.size() > 0) {
                finalList.put(article.Id, resultList);
            }
        }
        System.debug('Number of articles with dead links: ' + finalList.size());
        System.debug(finalList);
    }

    public void finish(Database.BatchableContext bc) {
        // toAddress: nav.kontaktsenter.fag.og.kvalitet@nav.no
        String[] toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
        sendEmail(finalList, toAddresses);
    }

    @TestVisible
    private static Integer detectRedirect(HttpRequest req, HttpResponse res) {
        Boolean redirect;

        if (Test.isRunningTest()) {
            System.debug('Running tests.');
            return null;
        } else {
            if (res.getStatusCode() >= 300 && res.getStatusCode() <= 307 && res.getStatusCode() != 306) {
                do {
                    redirect = false; // reset the value each time
                    String loc = res.getHeader('Location'); // get location of the redirect
                    if (loc == null) {
                        redirect = false;
                        continue;
                    }
                    req = new HttpRequest();
                    req.setEndpoint(loc);
                    req.setMethod('GET');
                    Http http = new Http();
                    res = http.send(req);
                    if (res.getStatusCode() != 500) {
                        // 500 = fail
                        if (res.getStatusCode() >= 300 && res.getStatusCode() <= 307 && res.getStatusCode() != 306) {
                            redirect = true;
                        }
                    }
                } while (redirect && Limits.getCallouts() != Limits.getLimitCallouts());
            }
            //System.debug(res.getStatusCode());
            return res.getStatusCode();
        }
    }

    @TestVisible
    private static HttpResponse calloutHttpReq(HttpRequest req, String endpoint) {
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }

    @TestVisible
    private static void sendEmail(Map<Id, List<String>> listToSend, List<String> toAddresses) {
        if (listToSend.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(toAddresses);
            //mail.setCcAddresses(ccAddresses);
            mail.setSenderDisplayName('Døde lenker i kunnskapsbasen');
            mail.setSubject('Rapport om døde lenker');
            mail.setBccSender(false);
            mail.setUseSignature(false);

            // Specify the text content of the email.
            String body = '';
            for (Id key : listToSend.keySet()) {
                Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav WHERE Id = :key];
                List<String> links = listToSend.get(key);
                String recordlink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + article.Id;
                body +=
                    'Artikkel: "' +
                    '<a href="' +
                    recordlink +
                    '">' +
                    article.Title +
                    '</a>' +
                    '" har følgende døde lenker:<br/>';
                for (String str : links) {
                    //body += '<a href="' + str + '">' + str + '</a><br/>';
                    body += str + '<br/>';
                }
                body += '<br/>';
            }
            mail.setHtmlBody(body);
            try {
                // Send the email you have created.
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            } catch (Exception ex) {
                System.debug('Problem sending email: ' + ex.getMessage());
            }
        } else {
            System.debug('List is empty!');
        }
    }
}
