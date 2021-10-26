@IsTest
private class NKS_ThreadSharingActivation_BatchTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('NKS Dialog', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup(' Dialog Fortrolig Adresse', NKS_GroupVariables.FORTOLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('Dialog Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
    }

    @IsTest
    private static void activateSharingThreadForPersonWithoutGradering() {
        //we don't want handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NKS_ThreadAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;

        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Test.startTest();
        NKS_ThreadSharingActivation_Batch batch = new NKS_ThreadSharingActivation_Batch();
        Database.executeBatch(batch, 2000);
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 41002'
        );
    }

    @IsTest
    private static void activateSharingThreadForPersonWhoIsNameEmplyee() {
        //we don't want handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NKS_ThreadAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;

        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1].Id;

        Test.startTest();
        NKS_ThreadSharingActivation_Batch batch = new NKS_ThreadSharingActivation_Batch();
        Database.executeBatch(batch, 2000);
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410099'
        );
    }

    @IsTest
    private static void activateSharingThreadForPersonsWithFortroligAddress() {
        //we don't want handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(NKS_ThreadAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId);
        insert thread;

        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTOLIG_GROUP_NAME LIMIT 1].Id;

        Test.startTest();
        NKS_ThreadSharingActivation_Batch batch = new NKS_ThreadSharingActivation_Batch();
        Database.executeBatch(batch, 2000);
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 999908'
        );
    }
}
