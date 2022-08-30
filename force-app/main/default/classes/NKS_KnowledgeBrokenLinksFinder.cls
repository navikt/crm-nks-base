global with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts {
    //private String articleId;
    private Map<Id, List<String>> finalList = new Map<Id, List<String>>();

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
                        System.debug(ex.getMessage());
                    }
                }
            }
            /**
             * endpoint must be registered in remote site setting otherwise must define name credential
             */
            if (matches.size() > 0) {
                for (String str : matches) {
                    if (str.contains('www.nav.no')) {
                        String path = str.substringAfter('www.nav.no');
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint('callout:nav_no' + path);

                        req.setMethod('HEAD');
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        if (res.getStatusCode() != 200) {
                            resultList.add(str);
                        }
                    }
                }
            }

            if (resultList.size() > 0) {
                finalList.put(article.Id, resultList);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        //Messaging.reserveSingleEmailCapacity(2);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String[] toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
        String[] ccAddresses = new List<String>{ 'sara.mohammadi@nav.no' };

        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setSenderDisplayName('Knowledge Broken Links Finder');
        mail.setSubject('Broken Links Raport');
        mail.setBccSender(false);
        mail.setUseSignature(false);

        // Specify the text content of the email.
        String body = '';

        for (Id key : finalList.keySet()) {
            List<String> links = finalList.get(key);
            body += 'Article: ' + key + ' has the following dead links:\n';
            for (String str : links) {
                body += str + ', ';
            }
            body += '\n';
        }
        mail.setPlainTextBody(body);
        /*
        mail.setHtmlBody(
            'Your case:<b> ' +
            case.Id +
            ' </b>has been created.<p>' +
            'To view your case <a href=https://MyDomainName.my.salesforce.com/' +
            case.Id +
            '>click here.</a>'
        );
        */

        // Send the email you have created.
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    @invocableMethod(label='Find Broken Links')
    public static void findBrokenLinks() {
        NKS_KnowledgeBrokenLinksFinder finder = new NKS_KnowledgeBrokenLinksFinder();
    }
}
