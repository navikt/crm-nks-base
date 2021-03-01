@IsTest
private with sharing class NKS_NavUnitPersonUtilityTest {
    @IsTest
    static void getNavUnitFromPerson_Success() {
        NKS_NorgNavUnitService.NavUnitResponse result;

        String unitJSON =
            '{' +
            '    "enhetId": 100000048,' +
            '    "navn": "NAV TEST",' +
            '    "enhetNr": "1234",' +
            '    "antallRessurser": 1,' +
            '    "status": "Aktiv",' +
            '    "orgNivaa": "EN",' +
            '    "type": "LOKAL",' +
            '    "organisasjonsnummer": "999999999",' +
            '    "underEtableringDato": "1970-01-01",' +
            '    "aktiveringsdato": "1970-01-01",' +
            '    "underAvviklingDato": null,' +
            '    "nedleggelsesdato": null,' +
            '    "oppgavebehandler": true,' +
            '    "versjon": 37,' +
            '    "sosialeTjenester": "sosialeTjenester",' +
            '    "kanalstrategi": "kanalstrategi",' +
            '    "orgNrTilKommunaltNavKontor": "999999999"' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', unitJSON, null)
        );

        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(
                Name = '1234567890',
                INT_LastName__c = 'Potter',
                INT_IsNavEmployee__c = false,
                INT_Confidential__c = 'UGRADERT',
                INT_MunicipalityNumber__c = '1234'
            ),
            true
        );

        Test.startTest();
        result = util.getNavUnitFromPerson(p.id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success');
        System.assertEquals(
            true,
            String.isBlank(result.errorMessage),
            'Expected blank errorMessage'
        );
        System.assertEquals(
            '1234',
            result.unit.enhetNr,
            'Expected the same unit number as in the mock'
        );
    }

    @IsTest
    static void getNavUnitFromPerson_NoLocation() {
        NKS_NorgNavUnitService.NavUnitResponse result;

        String unitJSON =
            '{' +
            '    "enhetId": 100000048,' +
            '    "navn": "NAV TEST",' +
            '    "enhetNr": "1234",' +
            '    "antallRessurser": 1,' +
            '    "status": "Aktiv",' +
            '    "orgNivaa": "EN",' +
            '    "type": "LOKAL",' +
            '    "organisasjonsnummer": "999999999",' +
            '    "underEtableringDato": "1970-01-01",' +
            '    "aktiveringsdato": "1970-01-01",' +
            '    "underAvviklingDato": null,' +
            '    "nedleggelsesdato": null,' +
            '    "oppgavebehandler": true,' +
            '    "versjon": 37,' +
            '    "sosialeTjenester": "sosialeTjenester",' +
            '    "kanalstrategi": "kanalstrategi",' +
            '    "orgNrTilKommunaltNavKontor": "999999999"' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', unitJSON, null)
        );

        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(
                Name = '1234567890',
                INT_LastName__c = 'Potter',
                INT_IsNavEmployee__c = false,
                INT_Confidential__c = 'UGRADERT'
            ),
            true
        );

        Test.startTest();
        result = util.getNavUnitFromPerson(p.id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals(
            Label.NAV_Unit_Error_person_location_missing,
            result.errorMessage,
            'Expected the NAV_Unit_Error_person_location_missing label'
        );
        System.assertEquals(null, result.unit, 'Expected no units');
    }

    @IsTest
    static void getIsShielded_true() {
        Boolean result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_IsNavEmployee__c = true);
        Test.startTest();
        result = util.getIsShielded(p);
        Test.stopTest();

        System.assertEquals(true, result, 'Expected true');
    }

    @IsTest
    static void getIsShielded_false() {
        Boolean result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_IsNavEmployee__c = false);
        Test.startTest();
        result = util.getIsShielded(p);
        Test.stopTest();

        System.assertEquals(false, result, 'Expected false');
    }

    @IsTest
    static void getIsShielded_nullInput() {
        Boolean result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_IsNavEmployee__c = null);
        Test.startTest();
        result = util.getIsShielded(p);
        Test.stopTest();

        System.assertEquals(false, result, 'Expected false');
    }

    @IsTest
    static void getDiscretionaryCode_STRENGT_FORTROLIG_UTLAND() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(
            INT_Confidential__c = 'STRENGT_FORTROLIG_UTLAND'
        );
        Test.startTest();
        result = util.getDiscretionaryCode(p);
        Test.stopTest();

        System.assertEquals('SPSF', result, 'Expected 1234');
    }

    @IsTest
    static void getDiscretionaryCode_STRENGT_FORTROLIG() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_Confidential__c = 'STRENGT_FORTROLIG');
        Test.startTest();
        result = util.getDiscretionaryCode(p);
        Test.stopTest();

        System.assertEquals('SPSF', result, 'Expected SPSF');
    }

    @IsTest
    static void getDiscretionaryCode_FORTROLIG() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_Confidential__c = 'FORTROLIG');
        Test.startTest();
        result = util.getDiscretionaryCode(p);
        Test.stopTest();

        System.assertEquals('SPFO', result, 'Expected SPFO');
    }

    @IsTest
    static void getDiscretionaryCode_UGRADERT() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_Confidential__c = 'UGRADERT');
        Test.startTest();
        result = util.getDiscretionaryCode(p);
        Test.stopTest();

        System.assertEquals('ANY', result, 'Expected ANY');
    }

    @IsTest
    static void getDiscretionaryCode_NULL() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(INT_Confidential__c = null);
        Test.startTest();
        result = util.getDiscretionaryCode(p);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected empty string');
    }

    @IsTest
    static void testGetLocation_MunicipalityNumberWithoutDistrictNumber() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(
            INT_MunicipalityNumber__c = '1234',
            INT_DistrictNumber__c = ''
        );
        Test.startTest();
        result = util.getLocation(p);
        Test.stopTest();

        System.assertEquals('1234', result, 'Expected 1234');
    }

    @IsTest
    static void testGetLocation_MunicipalityNumberWithDistrictNumber() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c(
            INT_MunicipalityNumber__c = '1234',
            INT_DistrictNumber__c = '123456'
        );
        Test.startTest();
        result = util.getLocation(p);
        Test.stopTest();

        System.assertEquals('123456', result, 'Expected 123456');
    }

    @IsTest
    static void testGetLocation_Null() {
        String result;
        NKS_NavUnitPersonUtility util = new NKS_NavUnitPersonUtility(
            new NKS_NorgNavUnitService()
        );
        Person__c p = new Person__c();
        Test.startTest();
        result = util.getLocation(p);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null in response');
    }
}
