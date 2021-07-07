@IsTest
private class NKS_ConvNoteSharingActivation_BatchTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        TestDataFactory.getPublicGroup('Fortrolig Adresse', 'group_999907');
        TestDataFactory.getPublicGroup('NKS Skjermet', 'group_410098');    
    }

    @IsTest
    private static void activateSharingConversationNoteForPersonWithoutGradering() {
        //we don't want handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NKS_ConversationNoteAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        NKS_ConvNoteSharingActivation_Batch batch = new NKS_ConvNoteSharingActivation_Batch ();
        Database.executeBatch(batch, 2000);
        Test.stopTest();
        
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected conversation note to be shared with group 41001'
        );
    }

    @IsTest
    private static void activateSharingConversationNoteForPersonWhoIsNameEmplyee() {
        //we don't want handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NKS_ConversationNoteAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_410098' LIMIT 1].Id;

        Test.startTest();
        NKS_ConvNoteSharingActivation_Batch batch = new NKS_ConvNoteSharingActivation_Batch ();
        Database.executeBatch(batch, 2000);
        Test.stopTest();
        
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected conversation note to be shared with group 410098'
        );
    }

    @IsTest
    private static void activateSharingConversationNoteForPersonsWithFortroligAddress() {
        //we don't want handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NKS_ConversationNoteAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_999907' LIMIT 1].Id;

        Test.startTest();
        NKS_ConvNoteSharingActivation_Batch batch = new NKS_ConvNoteSharingActivation_Batch ();
        Database.executeBatch(batch, 2000);
        Test.stopTest();
        
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected conversation note to be shared with group 999907'
        );
    }
    
}
