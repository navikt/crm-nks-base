@IsTest
private class NKS_ConversationNoteAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('Veiledere', 'group_41003');
        TestDataFactory.getPublicGroup('Fortrolig Adresse', 'group_999909');
        TestDataFactory.getPublicGroup('Skjermet', 'group_410097');

        TestDataFactory.getPublicGroup('NKS Veiledere', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Adresse', NKS_GroupVariables.FORTROLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Skjermet', NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('Tema BID', NKS_GroupVariables.TEMA_BID_NAME);
        TestDataFactory.getPublicGroup('Fortrolig BID', NKS_GroupVariables.FORTROLIG_BID_NAME);
        TestDataFactory.getPublicGroup('Skjermet BID', NKS_GroupVariables.SKJERMET_BID_NAME);
        TestDataFactory.getPublicGroup('Fortrolig Skjermet BID', NKS_GroupVariables.FORTROLIG_SKJERMET_BID_NAME);


        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
    }

    @IsTest
    private static void grantAccess_whenUgradertAndNotNavEmployee() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id dialogVeileder = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Test.startTest();
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogVeileder
            ],
            'Expected conversation note to be shared with group dialog'
        );
    }

    private static void grantAccess_BIDUgradertAndNotNavEmployee() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id dialogVeileder = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Id temaBID = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.TEMA_BID_NAME LIMIT 1]
        .Id;
        Common_Code__c cc = new Common_Code__c(Name = 'Bidrag', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'BID');

        insert cc;

        Test.startTest();
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId,CRM_Theme__c = cc.Id);
        insert note;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogVeileder
            ],
            'Expected conversation note not to be shared with group dialog'
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :temaBID
            ],
            'Expected conversation note to be shared with group Tema BID'
        );
    }

    @IsTest
    private static void grantAccess_whenIncorrectlySentIsSetToFalse() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id dialogVeileder = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;

        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        note.CRM_Incorrectly_Sent__c = true;
        insert note;

        Test.startTest();
        note.CRM_Incorrectly_Sent__c = false;
        update note;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogVeileder
            ],
            'Expected conversation note to be shared with group dialog'
        );
    }

    @IsTest
    private static void grantAccess_whenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id dialogVeileder = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1]
        .Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1]
        .Id;
        Id fortroligSkjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME LIMIT 1]
        .Id;

        Test.startTest();
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogVeileder
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
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected conversation notes not to be shared with fortrolig skjermet'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Conversation_Note__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
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
        Id dialogVeileder = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogVeileder
            ],
            'Expected conversation notes not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected conversation notes to be shared with skjermet group'
        );
    }

    @IsTest
    private static void grantAccess_whenConfEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id dialogVeileder = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1]
        .Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1]
        .Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1]
        .Id;
        Id fortroligSkjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME LIMIT 1]
        .Id;

        Test.startTest();
        Conversation_Note__c note = new Conversation_Note__c(CRM_Account__c = accountId);
        insert note;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Conversation_Note__Share
                WHERE RowCause = 'Manual' AND UserOrGroupId = :dialogVeileder
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
            'Expected conversation notes to be shared with code 7 group'
        );
    }
}
