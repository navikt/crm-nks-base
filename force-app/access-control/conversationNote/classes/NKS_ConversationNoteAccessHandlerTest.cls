@IsTest
private class NKS_ConversationNoteAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        TestDataFactory.getPublicGroup('Fortrolig Adresse', 'group_999907');
        TestDataFactory.getPublicGroup('NKS Skjermet', 'group_410098');
        
        
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

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

    @IsTest
    private static void grantAccess_whenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_999907' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected conversation notes not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected conversation notes to be shared with code 7 group'
        );       
    }

    @IsTest
    private static void grantAccess_whenNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_410098' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected conversation notes not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected conversation notes to be shared with skjermet group'
        );

        
    }
}
