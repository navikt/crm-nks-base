@IsTest
private class NKS_ConversationNoteOwnerHandler_Test {
    @TestSetup
    private static void setupTestData() {
        TestDataFactory.getQueue('Oslo', 'queue_391', 'Conversation_Note__c');
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        TestDataFactory.getPublicGroup('Fortrolig Adresse', 'group_999907');
        TestDataFactory.getPublicGroup('NKS Skjermet', 'group_410098');

        TestDataFactory.getPublicGroup('NKS Dialog', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Fortrolig Adresse', NKS_GroupVariables.FORTOLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
    }

    @IsTest
    private static void testInseertNewConvNote() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        Group queue = TestDataFactory.getQueue('Oslo', 'queue_391', 'Conversation_Note__c');

        //mock custom settings for default owner
        insert new DefaultRecordOwner__c(SetupOwnerId = UserInfo.getProfileId(), UserOrQueueId__c = queue.Id);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();

        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = acc.Id);
        insert note;
        Test.stopTest();

        Conversation_Note__c newNote = [SELECT OwnerId FROM Conversation_Note__c LIMIT 1];
        System.assertEquals(queue.Id, newNote.OwnerId);
    }

    @IsTest
    private static void testInseertNewConvNote_whenDefaultOwnerIsNotSet() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = acc.Id);
        insert note;
        Test.stopTest();

        Conversation_Note__c newNote = [SELECT OwnerId FROM Conversation_Note__c LIMIT 1];
        System.assertEquals(UserInfo.getUserId(), newNote.OwnerId);
    }
}
