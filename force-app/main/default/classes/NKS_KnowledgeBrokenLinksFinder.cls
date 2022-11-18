public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<String, List<String>> finalList = new Map<String, List<String>>();

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
            List<String> res = NKS_KnowledgeController.findBrokenLinks(article);
            if (res.size() > 0) {
                finalList.put(article.Title, res);
            }
        }
        System.debug('Number of articles with dead links: ' + finalList.size());
        System.debug(finalList);
    }

    public void finish(Database.BatchableContext bc) {
        List<String> toAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
        NKS_KnowledgeController.sendEmail(finalList, toAddresses);
    }

    @invocableMethod(label='Find Broken Links')
    public static void findDeadLinks() {
        Database.executeBatch(new NKS_KnowledgeBrokenLinksFinder(), 1);
    }
}
