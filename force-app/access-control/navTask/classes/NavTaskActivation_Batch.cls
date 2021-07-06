global class NavTaskActivation_Batch implements Database.Batchable<sObject> {
    private Id apexSharingRuleId;
    private String objectType;
    private String conditionExpression;

    global NavTaskActivation_Batch (Id apexSharingRuleId, String conditionExpression) {
        this.apexSharingRuleId = apexSharingRuleId;
        this.conditionExpression = conditionExpression;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT CRM_Account__c From Person__c WHERE ' + conditionExpression;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Person__c> scope) {
        List<ApexSharingRule__mdt> sharingRules = new ApexSharingRulesSelector()
            .selectById(new Set<Id>{ apexSharingRuleId });
        if (sharingRules.size() == 0)
            return;
        Integer unitNumber = Integer.valueOf(sharingRules[0].UnitNumber__c);
        Map<String, Id> publicGroupIdByDeveloperName = RecordShareService.getPublicGroups(
            new Set<Integer>{ unitNumber }
        );
        Id publicGroupId;
        for (String devloperName : publicGroupIdByDeveloperName.keySet()) {
            publicGroupId = publicGroupIdByDeveloperName.get(devloperName);
        }

        Set<Id> accountIds=new Set<Id>();
        for (Person__c person : scope) {
           accountIds.add(person.CRM_Account__c);
        }

        List<NavTask__Share> shareRecords = new List<NavTask__Share>();
        for(NavTask__c task:[SELECT Id FROM NavTask__c WHERE CRM_Account__c in:accountIds]){
            NavTask__Share share = new NavTask__Share();
            share.ParentId = task.Id;
            share.UserOrGroupId = publicGroupId;
            share.AccessLevel = 'Edit';
            share.RowCause = 'Manual';
            shareRecords.add(share);
        }
        
       
        Database.insert(shareRecords, false);
    }

    global void finish(Database.BatchableContext bc) {
    
    }
}
