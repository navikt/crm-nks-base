@IsTest
private class NKS_ThreadPersonAccessHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Veileder', NKS_GroupVariables.VEILEDER_GROUP_NAME);
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
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId,  CRM_Thread_Type__c = 'STO');
        insert thread;

        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410099'
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

        Thread__c thread = new Thread__c(CRM_Account__c = accountId,  CRM_Thread_Type__c = 'STO');
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
    @isTest
    private static void grantAccess_whenPersonIsConfEmployee(){
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1].Id;
        Id fortroligGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1].Id;
        Id fortroligSkjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c='STO');
        insert thread;
        
        Test.startTest();
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 41002'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 410099'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 999908'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 999905'
        );
    }

    @isTest
    private static void grantAccess_onThreadCreate(){
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1].Id;
        Id fortroligGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1].Id;
        Id fortroligSkjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME LIMIT 1].Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 41002'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 410099'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 999908'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 999905'
        );
    }
}
