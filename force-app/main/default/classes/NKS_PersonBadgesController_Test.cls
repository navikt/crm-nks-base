@IsTest
private with sharing class NKS_PersonBadgesController_Test {
    
    @IsTest static void getPersonBadgesAndInfo_FromAccount() {
        Account acc = (Account) UTIL_TestDataFactory.createRecord(new Account(Name = 'Harry Potter'), true);
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(CRM_Account__c = acc.Id, INT_IsNavEmployee__c = true, INT_SpokenLanguageIntepreter__c = 'AM;EN', INT_IsDeceased__c = true), true);
        acc.CRM_Person__c = p.Id;
        update acc;

        SecurityMeasure__c sm = (SecurityMeasure__c) UTIL_TestDataFactory.createRecord(new SecurityMeasure__c(INT_Person__c = p.Id), true);

        NKS_PersonBadgesController.PersonBadgeData pbd = NKS_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c','Account',acc.Id);

        System.assertEquals(1, pbd.securityMeasures.size(), 'Expected one');
        System.assertEquals(5, pbd.badges.size(), 'Expected five');
        System.assertEquals(2, pbd.spokenLanguagesIntepreter.size(), 'Expected two');
    }

    @IsTest static void getPersonBadgesAndInfo_FromCase() {
        Account acc = (Account) UTIL_TestDataFactory.createRecord(new Account(Name = 'Harry Potter'), true);
        
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(CRM_Account__c = acc.Id, INT_IsNavEmployee__c = true, INT_SpokenLanguageIntepreter__c = 'AM;EN', INT_IsDeceased__c = true), true);
        
        acc.CRM_Person__c = p.Id;
        update acc;
        
        SecurityMeasure__c sm = (SecurityMeasure__c) UTIL_TestDataFactory.createRecord(new SecurityMeasure__c(INT_Person__c = p.Id), true);

        Case c = (Case) UTIL_TestDataFactory.createRecord(new Case(AccountId = acc.Id), true);


        NKS_PersonBadgesController.PersonBadgeData pbd = NKS_PersonBadgesController.getPersonBadgesAndInfo('Account.CRM_Person__c','Case',c.Id);

        System.assertEquals(1, pbd.securityMeasures.size(), 'Expected one');
        System.assertEquals(5, pbd.badges.size(), 'Expected five');
        System.assertEquals(2, pbd.spokenLanguagesIntepreter.size(), 'Expected two');
    }
}
