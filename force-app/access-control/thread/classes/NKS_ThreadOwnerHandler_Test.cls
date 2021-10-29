@IsTest
private class NKS_ThreadOwnerHandler_Test {
    @TestSetup
    private static void setupTestData() {
        TestDataFactory.getQueue('Oslo', 'queue_391', 'Thread__c');
        TestDataFactory.getPublicGroup('NKS Dialog', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Fortrolig Adresse', NKS_GroupVariables.FORTOLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
    }

    @IsTest
    private static void testInseertNewThread() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        Group queue = TestDataFactory.getQueue('Oslo', 'queue_391', 'Thread__c');

        //mock custom settings for default owner
        insert new DefaultRecordOwner__c(SetupOwnerId = UserInfo.getProfileId(), UserOrQueueId__c = queue.Id);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();

        Thread__c thread = new Thread__c(CRM_Account__c = acc.Id);
        insert thread;
        Test.stopTest();

        Thread__c newThread = [SELECT OwnerId FROM Thread__c LIMIT 1];
        System.assertEquals(queue.Id, newThread.OwnerId);
    }

    @IsTest
    private static void testInseertNewThread_whenDefaultOwnerIsNotSet() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = acc.Id);
        insert thread;
        Test.stopTest();

        Thread__c newThread = [SELECT OwnerId FROM Thread__c LIMIT 1];
        System.assertEquals(UserInfo.getUserId(), newThread.OwnerId);
    }
}
