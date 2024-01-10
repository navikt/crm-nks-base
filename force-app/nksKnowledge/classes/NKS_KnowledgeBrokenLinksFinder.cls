public with sharing class NKS_KnowledgeBrokenLinksFinder implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    // map to return: string: title of article, map: list of dead links per field
    public Map<String, Map<String, List<String>>> finalList = new Map<String, Map<String, List<String>>>();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Knowledge__kav WHERE PublishStatus = \'Online\' AND IsLatestVersion = TRUE';
        // Set regex pattern only once to avoid "Regex too complicated" err
        NKS_KnowledgeController.setCompiledRegexPattern();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        // Retrieve the compiled regex pattern
        Pattern linksPattern = NKS_KnowledgeController.getCompiledRegexPattern();        
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
            if (Test.isRunningTest()) {
                Map<String, List<String>> testMap = new Map<String, List<String>>();
                List<String> testList = new List<String>{ 'TestUrl1', 'TestUrl2' };
                testMap.put('TestField', testList);
                finalList.put(article.Title, testMap);
            }
            Map<String, List<String>> res = NKS_KnowledgeController.getBrokenLinks(article, linksPattern);
            if (res.size() > 0) {
                finalList.put(article.Title, res);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (finalList.size() > 0) {
            List<String> toAddresses = new List<String>{ 'nav.kontaktsenter.fag.og.kvalitet@nav.no' };
            List<String> bccAddresses = new List<String>{ 'sara.mohammadi@nav.no' };
            try {
                NKS_KnowledgeController.sendEmail(finalList, toAddresses, bccAddresses);
            } catch (Exception ex) {
                System.debug('Problem sending email: ' + ex.getMessage());
            }
        }
    }
}
