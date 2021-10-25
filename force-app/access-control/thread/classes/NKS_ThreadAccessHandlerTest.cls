@IsTest
private class NKS_ThreadAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Dialog', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Fortrolig Adresse', NKS_GroupVariables.FORTOLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);

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
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Test.startTest();
        Thread thread = new Thread(CRM_Account__c = accountId);
        insert thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 41001'
        );
    }

    @IsTest
    private static void grantAccess_whenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTOLIG_GROUP_NAME LIMIT 1]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected thread to be shared with code 7 group'
        );
    }

    @IsTest
    private static void grantAccess_whenNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be shared with skjermet group'
        );
    }
}
