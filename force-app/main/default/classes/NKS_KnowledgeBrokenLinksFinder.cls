public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    // map to return: string: title of article, map: list of dead links per field
    public Map<String, Map<String, List<String>>> finalList = new Map<String, Map<String, List<String>>>();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Knowledge__kav WHERE PublishStatus = \'Online\' AND IsLatestVersion = TRUE';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        for (Knowledge__kav article : [
            SELECT
                Title,
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
            Map<String, List<String>> res = NKS_KnowledgeController.getBrokenLinks(article);
            if (res.size() > 0) {
                finalList.put(article.Title, res);
            }
        }
        //System.debug('Number of articles with dead links: ' + finalList.size());
        //System.debug(finalList);
    }

    public void finish(Database.BatchableContext bc) {
        if (finalList.size() > 0) {
            List<String> toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
            try {
                NKS_KnowledgeController.sendEmail(finalList, toAddresses);
            } catch (Exception ex) {
                System.debug('Problem sending email: ' + ex.getMessage());
            }
        }

        // This part is for test
        AsyncApexJob a = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
        mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Sharing Recalculation ' + a.Status);
        mail.setPlainTextBody(
            'The batch Apex job processed ' +
            a.TotalJobItems +
            ' batches with ' +
            a.NumberOfErrors +
            ' failures.'
        );
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}
