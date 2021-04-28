@IsTest
private with sharing class NKSNavTaskWorkAllocationControllerTest {
    @isTest
    static void getWorkAllocations_Success() {
        String unitJSON =
            '[' +
            '	{' +
            '		"enhetId": 100000770,' +
            '		"navn": "Test Unit",' +
            '		"enhetNr": "1234",' +
            '		"antallRessurser": 0,' +
            '		"status": "Aktiv",' +
            '		"orgNivaa": "EN",' +
            '		"type": "YTA",' +
            '		"organisasjonsnummer": null,' +
            '		"underEtableringDato": "1970-01-01",' +
            '		"aktiveringsdato": "1970-01-01",' +
            '		"underAvviklingDato": null,' +
            '		"nedleggelsesdato": null,' +
            '		"oppgavebehandler": true,' +
            '		"versjon": 2,' +
            '		"sosialeTjenester": null,' +
            '		"kanalstrategi": null,' +
            '		"orgNrTilKommunaltNavKontor": null' +
            '	}' +
            ']';
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));

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
        NavUnit__c unit1 = (NavUnit__c) UTIL_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit', INT_UnitNumber__c = '1234'),
            true
        );
        NavUnit__c unit2 = (NavUnit__c) UTIL_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit2', INT_UnitNumber__c = '4321'),
            true
        );

        NKS_NorgNavUnitService.WorkAllocationResponse result;

        Test.startTest();
        result = NKSNavTaskWorkAllocationController.getWorkAllocations(
            p.Id,
            'themeGroupCode',
            'themeCode',
            'themeSubThemeCode',
            'taskType'
        );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Excpected a successful result');
        System.assertEquals(true, String.isBlank(result.errorMessage), 'Excpected blank value in error message');
        System.assertNotEquals(null, result.units, 'Did not eexcpect the result NULL in units.');
        System.assertEquals(1, result.units.size(), 'Expected one unit');
        System.assertEquals(unit1.Id, result.units[0].sfId, 'Expected to the sf id populated with the correct Id');
    }

    @isTest
    static void getWorkAllocations_NoPerson() {
        String unitJSON =
            '[' +
            '	{' +
            '		"enhetId": 100000770,' +
            '		"navn": "Test Unit",' +
            '		"enhetNr": "1234",' +
            '		"antallRessurser": 0,' +
            '		"status": "Aktiv",' +
            '		"orgNivaa": "EN",' +
            '		"type": "YTA",' +
            '		"organisasjonsnummer": null,' +
            '		"underEtableringDato": "1970-01-01",' +
            '		"aktiveringsdato": "1970-01-01",' +
            '		"underAvviklingDato": null,' +
            '		"nedleggelsesdato": null,' +
            '		"oppgavebehandler": true,' +
            '		"versjon": 2,' +
            '		"sosialeTjenester": null,' +
            '		"kanalstrategi": null,' +
            '		"orgNrTilKommunaltNavKontor": null' +
            '	}' +
            ']';
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', unitJSON, null));

        NavUnit__c unit1 = (NavUnit__c) UTIL_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit', INT_UnitNumber__c = '1234'),
            true
        );
        NavUnit__c unit2 = (NavUnit__c) UTIL_TestDataFactory.createRecord(
            new NavUnit__c(Name = 'Test Unit2', INT_UnitNumber__c = '4321'),
            true
        );

        NKS_NorgNavUnitService.WorkAllocationResponse result;

        Test.startTest();
        result = NKSNavTaskWorkAllocationController.getWorkAllocations(
            null,
            'themeGroupCode',
            'themeCode',
            'themeSubThemeCode',
            'taskType'
        );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Excpected a successful result');
        System.assertEquals(true, String.isBlank(result.errorMessage), 'Excpected blank value in error message');
        System.assertNotEquals(null, result.units, 'Did not eexcpect the result NULL in units.');
        System.assertEquals(1, result.units.size(), 'Expected one unit');
        System.assertEquals(unit1.Id, result.units[0].sfId, 'Expected to the sf id populated with the correct Id');
    }

    @isTest
    static void testGetUserNavUnitId() {
        UTIL_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '0701'));

        Test.startTest();
        String unitId = NKSNavTaskWorkAllocationController.getUserNavUnitId('0701');
        Test.stopTest();

        System.assert(String.isNotBlank(unitId));
    }
}
