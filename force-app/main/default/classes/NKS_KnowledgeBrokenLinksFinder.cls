public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<Id, List<String>> finalList = new Map<Id, List<String>>();

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
             * Endpoints are urls which their domains are defined as named credentials
             */
            if (matches.size() > 0) {
                for (String str : matches) {
                    HttpRequest req = new HttpRequest();

                    if (Test.isRunningTest()) {
                        System.debug('Running tests.');
                    } else {
                        if (str.contains('nav.no')) {
                            HttpResponse res = calloutHttpReq(req, 'callout:nav_no' + str.substringAfter('nav.no'));

                            detectRedirect(req, res);
                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('helsenorge.no')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:helsenorge_no' + str.substringAfter('helsenorge.no')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('arbeidsplassen.no')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:arbeidsplassen_no' + str.substringAfter('arbeidsplassen.no')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('karriereveiledning.no')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:karriereveiledning_no' + str.substringAfter('karriereveiledning.no')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('utdanning.no')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:utdanning_no' + str.substringAfter('utdanning.no')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('google.no')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:google_no' + str.substringAfter('google.no')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('vimeo.com')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:vimeo_com' + str.substringAfter('vimeo.com')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('facebook.com')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:facebook_com' + str.substringAfter('facebook.com')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        } else if (str.contains('youtube.com')) {
                            HttpResponse res = calloutHttpReq(
                                req,
                                'callout:youtube_com' + str.substringAfter('youtube.com')
                            );

                            if (res.getStatusCode() > 400) {
                                resultList.add(str);
                            }
                        }
                    }
                }
            }

            if (resultList.size() > 0) {
                finalList.put(article.Id, resultList);
            }
        }
        System.debug('Final list: ' + finalList);
    }

    public void finish(Database.BatchableContext bc) {
        String[] toAddresses = new List<String>{ 'navnnavnesen@nav.no' };
        String[] ccAddresses = new List<String>{ 'navnnavnesen@nav.no' };
        sendEmail(finalList, toAddresses, ccAddresses);
    }

    @TestVisible
    private static Boolean detectRedirect(HttpRequest req, HttpResponse res) {
        Boolean redirect;

        if (Test.isRunningTest()) {
            System.debug('Running tests.');
            return true;
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
            //system.debug(res.getBody());
            return redirect;
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
    private static void sendEmail(
        Map<Id, List<String>> listToSend,
        List<String> toAddresses,
        List<String> ccAddresses
    ) {
        if (listToSend.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setSenderDisplayName('Knowledge Broken Links Finder');
            mail.setSubject('Broken Links Raport');
            mail.setBccSender(false);
            mail.setUseSignature(false);

            // Specify the text content of the email.
            String body = '';

            for (Id key : listToSend.keySet()) {
                Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav WHERE Id = :key];
                List<String> links = listToSend.get(key);
                body += 'Article: "' + article.Title + '" has the following dead links:\n';
                for (String str : links) {
                    body += str + ', ';
                }
                body += '\n';
            }
            mail.setPlainTextBody(body);

            // Send the email you have created.
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
}
