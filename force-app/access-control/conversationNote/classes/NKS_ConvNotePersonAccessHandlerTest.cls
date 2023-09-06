@IsTest
private class NKS_ConvNotePersonAccessHandlerTest {
    @TestSetup
    static void makeData() {
    
        TestDataFactory.getPublicGroup('NKS Veiledere', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Adresse', NKS_GroupVariables.FORTROLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Skjermet', NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME);
    }

    @IsTest
    private static void grantAccess_whePersonIsChagnedToNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id dialogGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogGroupId],
            'Expected conversation note to be shared with group dialog'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogGroupId],
            'Expected conversation note to not be shared with group dialog'
        );
    }

    @IsTest
    private static void grantAccess_whePersonIsChagnedFromNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id dialogGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogGroupId],
            'Expected conversation note to not be shared with group dialog'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = false;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogGroupId],
            'Expected conversation note to be shared with group dialog'
        );
    }
    @IsTest
    private static void grantAccess_whePersonIsChagnedConfEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id dialogGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1]
        .Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1]
        .Id;
        Id fortroligSkjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME LIMIT 1]
        .Id;

        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogGroupId
            ],
            'Expected conversation notes to be shared with veiledere'
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected conversation notes not to be shared with skjermet'
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected conversation notes not to be shared with fortrolig skjermet'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected conversation notes not to be shared with code 7 group'
        );

        Test.startTest();
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogGroupId
            ],
            'Expected conversation notes not to be shared with veiledere'
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected conversation notes not to be shared with skjermet'
        );

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected conversation notes to be shared with fortrolig skjermet'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected conversation notes not to be shared with code 7 group'
        );
    }
}