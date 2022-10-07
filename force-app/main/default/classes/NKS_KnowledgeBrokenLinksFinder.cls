public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<Id, List<String>> finalList = new Map<Id, List<String>>();
    private List<String> links = new List<String>{
        'afp.no',
        'akan.no',
        'altinn.no',
        'anskaffelser.no',
        'arbeidsmiljoportalen.no',
        'arbeidsplassen.no',
        'arbeidstilsynet.no',
        'behandlingshjelpemidler.no',
        'brreg.no',
        'bufdir.no',
        'deterdinpensjon.no',
        'doffin.no',
        'domstol.no',
        'ehelse.no',
        'eid.difi.no',
        'facebook.com',
        'garantikassen.no',
        'helfo.no',
        'helsedirektoratet.no',
        'helsenorge.no',
        'husbanken.no',
        'huseieren.no',
        'idebanken.org',
        'imdi.no',
        'jobbmesse.no',
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
                        Matcher matcher = linksPattern.matcher(
                            str.replaceAll('ø', 'o').replaceAll('æ', 'ae').replaceAll('å', 'a')
                        );
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
                    if (Test.isRunningTest()) {
                        System.debug('Running tests.');
                    } else {
                        for (String link : links) {
                            if (str.contains(link)) {
                                String endpoint = 'callout:' + link.replace('.', '_') + str.substringAfter(link);
                                try {
                                    HttpRequest req = new HttpRequest();
                                    HttpResponse res = calloutHttpReq(req, endpoint);
                                    Integer statusCode = res.getStatusCode();

                                    if (str.contains('.no') || statusCode == 301) {
                                        statusCode = detectRedirect(req, res);
                                    }
                                    if (statusCode != 200 && statusCode != 500 && statusCode.format().left(1) != '3') {
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
            Integer statusCode = res.getStatusCode();
            if (statusCode >= 300 && statusCode <= 307 && statusCode != 306) {
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
                    if (statusCode != 500) {
                        // 500 = fail
                        if (statusCode >= 300 && statusCode <= 307 && statusCode != 306) {
                            redirect = true;
                        }
                    }
                } while (redirect && Limits.getCallouts() != Limits.getLimitCallouts());
            }
            return statusCode;
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
                body += 'Artikkel: "' + article.Title + ' " har følgende døde lenker:<br/>';
                for (String str : links) {
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
