@IsTest
private with sharing class NKS_NavUnitSingleControllerTest {
    @IsTest static void findUnit_PersonLocationSuccess() {
        String unitJSON = '{'
        +'    "enhetId": 100000048,'
        +'    "navn": "NAV TEST",'
        +'    "enhetNr": "1234",'
        +'    "antallRessurser": 1,'
        +'    "status": "Aktiv",'
        +'    "orgNivaa": "EN",'
        +'    "type": "LOKAL",'
        +'    "organisasjonsnummer": "999999999",'
        +'    "underEtableringDato": "1970-01-01",'
        +'    "aktiveringsdato": "1970-01-01",'
        +'    "underAvviklingDato": null,'
        +'    "nedleggelsesdato": null,'
        +'    "oppgavebehandler": true,'
        +'    "versjon": 37,'
        +'    "sosialeTjenester": "sosialeTjenester",'
        +'    "kanalstrategi": "kanalstrategi",'
        +'    "orgNrTilKommunaltNavKontor": "999999999"'
        +'}';
        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));

        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(Name = '1234567890', INT_LastName__c = 'Potter', INT_IsNavEmployee__c = false, INT_Confidential__c = 'UGRADERT', INT_GTMunicipalityNumber__c = '1234'), true);
        Account pAccount = [SELECT Id FROM Account WHERE CRM_Person__c = :p.Id];
        Case c = (Case) UTIL_TestDataFactory.createRecord(new Case(AccountId = pAccount.Id),true);
        
        NKS_NorgNavUnitService.NavUnitResponse result;

        Test.startTest();
        result = NKS_NavUnitSingleController.findUnit('Account.CRM_Person__c', 'Case', c.Id, 'PERSON_LOCATION');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals(true, String.isBlank(result.errorMessage), 'Expected blank errorMessage');
        System.assertEquals('1234', result.unit.enhetNr, 'Expected the same unit number as in the mock');
    }
 
    @IsTest static void findUnit_UnitNumberSuccess() {
        String unitJSON = '[{'
        +'    "enhetId": 100000048,'
        +'    "navn": "NAV TEST",'
        +'    "enhetNr": "1234",'
        +'    "antallRessurser": 1,'
        +'    "status": "Aktiv",'
        +'    "orgNivaa": "EN",'
        +'    "type": "LOKAL",'
        +'    "organisasjonsnummer": "999999999",'
        +'    "underEtableringDato": "1970-01-01",'
        +'    "aktiveringsdato": "1970-01-01",'
        +'    "underAvviklingDato": null,'
        +'    "nedleggelsesdato": null,'
        +'    "oppgavebehandler": true,'
        +'    "versjon": 37,'
        +'    "sosialeTjenester": "sosialeTjenester",'
        +'    "kanalstrategi": "kanalstrategi",'
        +'    "orgNrTilKommunaltNavKontor": "999999999"'
        +'}]';
        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));

        NavUnit__c unit = (NavUnit__c) UTIL_TestDataFactory.createRecord(new NavUnit__c(Name = 'NAV TEST', INT_UnitNumber__c = '1234'), true);

        NKS_NorgNavUnitService.NavUnitResponse result;

        Test.startTest();
        result = NKS_NavUnitSingleController.findUnit('INT_UnitNumber__c', 'NavUnit__c', unit.Id, 'UNIT_NUMBER');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals(true, String.isBlank(result.errorMessage), 'Expected blank errorMessage');
        System.assertEquals('1234', result.unit.enhetNr, 'Expected the same unit number as in the mock');
    }

    @IsTest static void findUnit_IncorrectType() {
        NKS_NorgNavUnitService.NavUnitResponse result;

        Test.startTest();
        result = NKS_NavUnitSingleController.findUnit('INT_UnitNumber__c', 'NavUnit__c', '', 'TEST');
        Test.stopTest();

        System.assertEquals(null, result, 'Expected NULL in response');
    }

    @IsTest static void getContactInformation_Success() {
        String unitJSON = '{'
        +'  "id": 100000048,'
        +'  "enhetNr": "1234",'
        +'  "telefonnummer": "12345678",'
        +'  "telefonnummerKommentar": "kl. 08.00–15.30",'
        +'  "faksnummer": null,'
        +'  "epost": null,'
        +'  "postadresse": {'
        +'    "type": "postboksadresse",'
        +'    "postnummer": "0001",'
        +'    "poststed": "OSLO",'
        +'    "postboksnummer": "1",'
        +'    "postboksanlegg": null'
        +'  },'
        +'  "besoeksadresse": {'
        +'    "type": "stedsadresse",'
        +'    "postnummer": "0001",'
        +'    "poststed": "OSLO",'
        +'    "gatenavn": "Storgata",'
        +'    "husnummer": "8",'
        +'    "husbokstav": null,'
        +'    "adresseTilleggsnavn": null'
        +'  }'
        +'}';
        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));

        NKS_NorgNavUnitService.NavUnitContactInformationResponse result;

        Test.startTest();
        result = NKS_NavUnitSingleController.getContactInformation('1234');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals(true, String.isBlank(result.errorMessage), 'Expected blank errorMessage');
        System.assertEquals('1234', result.contactInformation.enhetNr, 'Expected the same unit number as in the mock');
    }

}
