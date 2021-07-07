@IsTest
private class NavTaskPersonAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        TestDataFactory.getPublicGroup('HMS Agder', 'group_47001');
    }

    @IsTest
    private static void grantAccess_whePersonIsChagnedToNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;

        System.assertEquals(
            1,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task to be shared with group 41001'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task to not be shared with group 41001'
        );
    }

    @IsTest
    private static void grantAccess_whePersonIsChagnedFromNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;

        NavTask__c task = new NavTask__c(CRM_Account__c = accountId);
        insert task;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task to not be shared with group 41001'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = false;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM NavTask__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected task to be shared with group 41001'
        );
    }
}
