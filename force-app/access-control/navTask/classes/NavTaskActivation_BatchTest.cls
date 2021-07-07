@IsTest
private class NavTaskActivation_BatchTest {
    @TestSetup
    static void makeData() {
        Group publicGroup = TestDataFactory.getPublicGroup('NKS Skjermet', 'group_410098');
        //we don't want to run triggers on test data creating
        myTriggers.disable(PersonHandler.class);
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NavTaskAccessHandler.class);

        List<Person__c> persons = TestDataFactory.getPersons(2000, false);
        persons[0].INT_IsNavEmployee__c =true;
        insert persons;

        Person__c person=[SELECT CRM_Account__c FROM Person__c LIMIT 1];
        NavTask__c task=new NavTask__c();
        task.CRM_Account__c=person.CRM_Account__c;
        insert task;
    }

    @IsTest
    private static void activateMunicipalityRuleWith2000Persons() {
        Group publicGroup = TestDataFactory.getPublicGroup('NKS Skjermet', 'group_410098');
        ApexSharingRule__mdt apexSharingRule = [
            SELECT Id
            FROM ApexSharingRule__mdt
            WHERE DeveloperName = 'NavTask_Skjermede_Personer'
            LIMIT 1
        ];

        Test.startTest();
        String conditionExpression = 'INT_IsNavEmployee__c=TRUE';
        NavTaskActivation_Batch batch = new NavTaskActivation_Batch (apexSharingRule.Id,  conditionExpression);
        Database.executeBatch(batch, 2000);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual']);
        
    }
}
