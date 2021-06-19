@IsTest
private class NKS_ConversationNoteAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        
        //we don't want person trigger access handlers to be run on test data insert
        //myTriggers.disable(PersonHandler.class);
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NavTaskPersonAccessHandler.class);
        myTriggers.disable(UserNotificationPersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
    }

    @IsTest
    private static void grantAccess_whenUgradertAndNotNavEmployee() {
      
        Id accountId = [SELECT Id FROM Account  LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        Conversation_Note__c note= new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected conversation note to be shared with group 41001'
        );
    }

    @IsTest
    private static void removeAccess_whenIncorrectlySentIsTrue() {
      
        Id accountId = [SELECT Id FROM Account  LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Conversation_Note__c note= new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        Test.startTest();
        note.NKS_Incorrectly_Sent__c=true;
        update note;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected conversation note sharing to be removed'
        );
    }

    @IsTest
    private static void grantAccess_whenIncorrectlySentIsSetToFalse() {
      
        Id accountId = [SELECT Id FROM Account  LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Conversation_Note__c note= new Conversation_Note__c(CRM_Account__c = accountId);
        note.NKS_Incorrectly_Sent__c=true;
        insert note;

        Test.startTest();
        note.NKS_Incorrectly_Sent__c=false;
        update note;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected conversation note to be shared with group 41001'
        );
    }
}
