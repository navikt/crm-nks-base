@IsTest
private with sharing class NKS_PersonBadgesController_Test {
    
    @IsTest static void getPersonBadgesAndInfo_FromAccount() {
        Account acc = (Account) UTIL_TestDataFactory.createRecord(new Account(Name = 'Harry Potter'), true);
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(CRM_Account__c = acc.Id, INT_IsNavEmployee__c = true, INT_SpokenLanguageIntepreter__c = 'AM;EN', INT_IsDeceased__c = true, INT_Confidential__c = 'FORTROLIG'), true);
        acc.CRM_Person__c = p.Id;
        update acc;

        SecurityMeasure__c sm = (SecurityMeasure__c) UTIL_TestDataFactory.createRecord(new SecurityMeasure__c(INT_Person__c = p.Id), true);

        NKS_PersonBadgesController.PersonBadgeData pbd = NKS_PersonBadgesController.getPersonBadgesAndInfo('CRM_Person__c','Account',acc.Id);

        System.assertEquals(1, pbd.securityMeasures.size(), 'Expected one');
        System.assertEquals(5, pbd.badges.size(), 'Expected four');
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
        System.assertEquals(4, pbd.badges.size(), 'Expected four');
        System.assertEquals(2, pbd.spokenLanguagesIntepreter.size(), 'Expected two');
    }

    @IsTest static void setBadgeData_GuardianshipOrFuturePowerOfAttorney() {
        String jsonString = '[{"type":"midlertidigForVoksen","omfangetErInnenPersonligOmraade":true,"omfang":"personligeOgOekonomiskeInteresser","navn":null,"motpartsPersonident":"01098130094","embete":"fylkesmannenITromsOgFinnmark"}]';

        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(INT_GuardianshipOrFuturePowerOfAttorney__c = jsonString));

        NKS_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = NKS_PersonBadgesController.setBadgeData(p);
        Test.stopTest();

        System.assertEquals(1, result.guardianships.size(), 'Expected one guardianship');
        System.assertEquals(1, result.badges.size(), 'Expected one guardianship');
    }

    @IsTest static void setBadgeData_PowerOfAttorney() {
        String jsonString = '{"motpartsRolle": "FULLMEKTIG","motpartsPersonident": "40000000000","omraader": ["*"],"gyldigFraOgMed": "2020-02-05","gyldigTilOgMed": "2021-02-05"}';

        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(INT_PowerOfAttorney__c = jsonString));

        NKS_PersonBadgesController.PersonBadgeData result;
        Test.startTest();
        result = NKS_PersonBadgesController.setBadgeData(p);
        Test.stopTest();

        System.assertNotEquals(null, result.powerOfAttorney, 'Expected one guardianship');
        System.assertEquals('40000000000', result.powerOfAttorney.motpartsPersonident, 'Expected 40000000000');
        System.assertEquals('Fullmektig', result.powerOfAttorney.motpartsRolle, 'Expected Fullmektig');
        System.assertEquals('Gjelder alle ytelser', result.powerOfAttorney.omraade, 'Expected Gjelder alle ytelser');
        System.assertEquals(1, result.badges.size(), 'Expected one guardianship');
    }
}
