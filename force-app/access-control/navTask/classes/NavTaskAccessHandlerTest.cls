@IsTest
private class NavTaskAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        TestDataFactory.getPublicGroup('HMS Agder', 'group_47001');
    }

    @IsTest
    private static void grantAccess_whenUgradertAndNotNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task to be shared with group 41001'
        );
    }

    @IsTest
    private static void grantAccess_whenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task not to be shared'
        );
    }

    @IsTest
    private static void grantAccess_whenIsNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task not to be shared'
        );
    }

    @IsTest
    private static void grantAccess_whenRelatedAccointIsCompany() {
        Account company = TestDataFactory.getAccounts(1, true)[0];
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = company.Id);
        insert task;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task not to be shared'
        );
    }

    @IsTest
    private static void grantAccess_whenTaskRelatedToPersonAndAccountInSameTransaction() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id personAccountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Account company = TestDataFactory.getAccounts(1, true)[0];
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        List<NavTask__c> tasks = new List<NavTask__c>();
        tasks.add(new NavTask__c(CRM_Account__c = personAccountId));
        tasks.add(new NavTask__c(CRM_Account__c = company.Id));
        insert tasks;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected one task to be shared with group 41001'
        );
    }

    @IsTest
    private static void grantAccess_whenThmeIsServiceklager() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        Test.startTest();
        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task not to be shared'
        );
    }

}
