global with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts {
    //private String articleId;
    global Map<Id, List<String>> finalList = new Map<Id, List<String>>();

    global NKS_KnowledgeBrokenLinksFinder() {
        //this.articleId = articleId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,AdvisorInformation__c,AdvisorInformationInternal__c,Article__c,EmployerInformation__c,EmployerInformationInternal__c,NKS_English__c,InternationalInformation__c,InternationalInformationInternal__c,NKS_Legislation__c,NKS_Nav_no__c,NKS_Nynorsk__c,NKS_Resources__c,NKS_Summary__c,NKS_UserInformation__c,WhoDoesWhat__c,OwnerId FROM Knowledge__kav';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        String regex1 = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        Pattern linksPattern = Pattern.compile(regex1);
        //String regex = '<a.+<\\/a>';
        //Pattern pattern = Pattern.compile(regex);

        for (Knowledge__kav article : scope) {
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
             * endpoint must be registered in remote site setting otherwise must define named credential
             */
            if (matches.size() > 0) {
                for (String str : matches) {
                    HttpRequest req = new HttpRequest();
                    String path;

                    if (str.contains('nav.no')) {
                        path = str.substringAfter('nav.no');
                        req.setEndpoint('callout:nav_no' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('helsenorge.no')) {
                        path = str.substringAfter('helsenorge.no');
                        req.setEndpoint('callout:helsenorge_no' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('arbeidsplassen.no')) {
                        path = str.substringAfter('arbeidsplassen.no');
                        req.setEndpoint('callout:arbeidsplassen_no' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('karriereveiledning.no')) {
                        path = str.substringAfter('karriereveiledning.no');
                        req.setEndpoint('callout:karriereveiledning_no' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('utdanning.no')) {
                        path = str.substringAfter('utdanning.no');
                        req.setEndpoint('callout:utdanning_no' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('google.no')) {
                        path = str.substringAfter('google.no');
                        req.setEndpoint('callout:google_no' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('vimeo.com')) {
                        path = str.substringAfter('vimeo.com');
                        req.setEndpoint('callout:vimeo_com' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('facebook.com')) {
                        path = str.substringAfter('facebook.com');
                        req.setEndpoint('callout:facebook_com' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
                        }
                    } else if (str.contains('youtube.com')) {
                        path = str.substringAfter('youtube.com');
                        req.setEndpoint('callout:youtube_com' + path);

                        req.setMethod('GET');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() > 400) {
                            resultList.add(str);
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

    global void finish(Database.BatchableContext bc) {
        if (finalList.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            String[] toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
            //String[] ccAddresses = new List<String>{ '' };

            mail.setToAddresses(toAddresses);
            //mail.setCcAddresses(ccAddresses);
            mail.setSenderDisplayName('Knowledge Broken Links Finder');
            mail.setSubject('Broken Links Raport');
            mail.setBccSender(false);
            mail.setUseSignature(false);

            // Specify the text content of the email.
            String body = '';

            for (Id key : finalList.keySet()) {
                Knowledge__kav article = [SELECT Id, Title FROM Knowledge__kav WHERE Id = :key];
                List<String> links = finalList.get(key);
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
