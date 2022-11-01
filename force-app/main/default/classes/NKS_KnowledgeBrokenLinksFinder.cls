public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<Id, List<String>> finalList = new Map<Id, List<String>>();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Knowledge__kav WHERE PublishStatus = \'Online\' AND IsLatestVersion = TRUE';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
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
            List<String> res = NKS_KnowledgeController.findBrokenLinks(article);
            if (res.size() > 0) {
                finalList.put(article.Id, res);
            }
        }
        System.debug('Number of articles with dead links: ' + finalList.size());
        System.debug(finalList);
    }

    public void finish(Database.BatchableContext bc) {
        String[] toAddresses = new List<String>{ 'nav.kontaktsenter.fag.og.kvalitet@nav.no' };
        sendEmail(finalList, toAddresses);
    }

    @TestVisible
    private static void sendEmail(Map<Id, List<String>> listToSend, List<String> toAddresses) {
        if (listToSend.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(toAddresses);
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

    @invocableMethod(label='Find Broken Links')
    public static void findDeadLinks() {
        Database.executeBatch(new NKS_KnowledgeBrokenLinksFinder(), 5);
    }
}
