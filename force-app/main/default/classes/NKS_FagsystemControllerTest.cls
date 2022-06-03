@IsTest
public with sharing class NKS_FagsystemControllerTest {
    @TestSetup
    static void makeData() {
        Person__c person = new Person__c(
            Name = '12345678901',
            INT_MunicipalityNumber__c = '0301',
            INT_LastName__c = 'Test1',
            INT_Confidential__c = 'UGRADERT',
            INT_MaritalStatus__c = 'UOPPGITT',
            INT_ActorId__c = '12345678905'
        );
        insert person;
        String personAccountRecordType = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account acc = new Account(
            FirstName = 'Harry',
            LastName = 'Potter',
            INT_PersonIdent__c = '12345678901',
            RecordTypeId = personAccountRecordType,
            CRM_Person__c = person.Id
        );
        insert acc;
        person.CRM_Account__c = acc.Id;
        update person;
        System.debug(person.CRM_Account__c);
        Case caseWithAccount = new Case(AccountId = person.CRM_Account__c, Status = 'New', Origin = 'Web');
        insert caseWithAccount;
    }

    @IsTest
    static void testGetPersonId() {
        Person__c pers = [SELECT Id, CRM_Account__c FROM Person__c WHERE INT_ActorId__c = '12345678905'][0];
        Id accountId = pers.CRM_Account__c;
        Case c = [SELECT Id FROM Case WHERE AccountId = :accountId];
        Test.startTest();
        String personIdFromAccount = NKS_FagsystemController.getPersonId(accountId, 'Id', 'Account');
        String personIdFromCase = NKS_FagsystemController.getPersonId(c.Id, 'Account', 'Case');
        Test.stopTest();
        System.assertEquals(pers.Id, personIdFromCase);
        System.assertEquals(pers.Id, personIdFromAccount);
    }
}
