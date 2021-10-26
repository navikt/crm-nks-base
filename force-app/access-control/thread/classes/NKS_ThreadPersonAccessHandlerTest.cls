@IsTest
private class NKS_ThreadPersonAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Dialog', NKS_GroupVariables.VEILEDER_GROUP_NAME);
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
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 41002'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to not be shared with group 41002'
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
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to not be shared with group 41002'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = false;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 41002'
        );
    }
}
