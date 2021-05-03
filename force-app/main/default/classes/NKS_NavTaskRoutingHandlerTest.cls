@IsTest
private class NKS_NavTaskRoutingHandlerTest {
    @TestSetup
    private static void setupTestData() {
        TestDataFactory.getQueue('NAV Arendal', 'queue_906', 'NavTask__c');
    }

    @IsTest
    private static void insertNavTask() {
        NavUnit__c navUnit = TestDataFactory.getNavUnits(1, false)[0];
        navUnit.INT_UnitNumber__c = '0906';
        insert navUnit;

        Account account = TAG_TestDataFactory.createAccounts(1)[0];
        account.INT_MunicipalityNumber__c = '4203'; //Arendal
        update account;
        List<Id> accountIds = new List<Id>{ account.Id };
        Test.startTest();
        List<String> queueIds = NKS_NavTaskRoutingHandler.getQueueIds(accountIds);
        Test.stopTest();

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'queue_906'];
        System.assertEquals(queue.Id, queueIds[0]);
    }
}
