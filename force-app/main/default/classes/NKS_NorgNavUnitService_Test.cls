@IsTest
private with sharing class NKS_NorgNavUnitService_Test {
    
    
    @IsTest static void getNavUnitFromGeographicLocation_TestResponseOneParameter() {
        NKS_NavUnit unit = new NKS_NavUnit();
        unit.enhetNr = '12345';
        unit.navn = 'Test Enhet';
        unit.underEtableringDato= Date.newInstance(1970, 1, 1);

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', JSON.serialize(unit),
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitResponse result;
        
        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitFromGeographicLocation('0573');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(unit.enhetNr, result.unit.enhetNr, 'Expected to get the unit same unit as in the mock');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');
    }

    @IsTest static void getNavUnitFromGeographicLocation_TestResponse() {
        NKS_NavUnit unit = new NKS_NavUnit();
        unit.enhetNr = '12345';
        unit.navn = 'Test Enhet';
        unit.underEtableringDato= Date.newInstance(1970, 1, 1);

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', JSON.serialize(unit),
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitResponse result;
        
        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitFromGeographicLocation('0573', null, null);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(unit.enhetNr, result.unit.enhetNr, 'Expected to get the unit same unit as in the mock');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');
    }

    @IsTest static void getNavUnitFromGeographicLocation_TestFailure() {
        SingleRequestMock httpMock = new SingleRequestMock(400, 'Bad Request', '',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitResponse result;
        
        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitFromGeographicLocation('0573', null, null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected to get a failure');
        System.assertEquals(null, result.unit, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }

    @IsTest static void getNavUnitContactInformation_TestResponse() {
        NKS_NAvUnitContactInformation unit = new NKS_NAvUnitContactInformation();
        unit.enhetNr = '12345';
        unit.epost = new NKS_NAvUnitContactInformation.Epost();
        unit.epost.adresse = 'test@test.no';
        unit.postadresse = new NKS_NAvUnitContactInformation.Adresse('TESTVEIEN TEST', '12', 'B', 'TEST', '0001');
        unit.publikumsmottak = new List<NKS_NAvUnitContactInformation.Publikumsmottak>();
        unit.publikumsmottak.add(new NKS_NAvUnitContactInformation.Publikumsmottak());
        unit.publikumsmottak[0].id = 123456;
        unit.publikumsmottak[0].besoeksadresse = new NKS_NAvUnitContactInformation.Adresse('TESTVEIEN TEST', '12', 'B', 'TEST', '0001');
        unit.publikumsmottak[0].aapningstider = new List<NKS_NAvUnitContactInformation.Aapningstider>();
        unit.publikumsmottak[0].aapningstider.add(new NKS_NAvUnitContactInformation.Aapningstider(123456, Date.newInstance(2020, 12, 20), '10:00', '12:00', 'Test utføres'));
        unit.publikumsmottak[0].aapningstider.add(new NKS_NAvUnitContactInformation.Aapningstider(1234567, 'MANDAG', '08:00', '16:00', ''));
        unit.publikumsmottak.add(new NKS_NAvUnitContactInformation.Publikumsmottak());
        unit.publikumsmottak[1].id = 1234567;
        unit.publikumsmottak[1].stedsbeskrivelse = 'Test mottaket';
        unit.publikumsmottak[1].besoeksadresse = new NKS_NAvUnitContactInformation.Adresse('SFVEIEN', '1', null, 'SF', '2323');
        unit.publikumsmottak[1].aapningstider = new List<NKS_NAvUnitContactInformation.Aapningstider>();
        unit.publikumsmottak[1].aapningstider.add(new NKS_NAvUnitContactInformation.Aapningstider(123456, Date.newInstance(2020, 12, 20), '10:00', '12:00', 'Test utføres'));
        unit.publikumsmottak[1].aapningstider.add(new NKS_NAvUnitContactInformation.Aapningstider(1234567, 'MANDAG', '08:00', '16:00', ''));

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', JSON.serialize(unit),
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitContactInformationResponse result;

        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitContactInformation('12345');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(unit.enhetNr, result.contactInformation.enhetNr, 'Expected to get the same enhetNr as in the mock');
        System.assertEquals('TESTVEIEN TEST 12 B, 0001 TEST', unit.postadresse.concatenatedAddress, 'Expected to have a formatted address');
        System.assertEquals(2, result.contactInformation.publikumsmottak.size(), 'Expected to have two publikums mottak');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');
    }

    @IsTest static void getNavUnitContactInformation_TestFailure() {
        SingleRequestMock httpMock = new SingleRequestMock(400, 'Bad Request', '',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitContactInformationResponse result;

        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitContactInformation('12345');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected to get a failure');
        System.assertEquals(null, result.contactInformation, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }
    
    @IsTest static void getNavUnitFilteredList_TestResponse() {
        NKS_NavUnit unit1 = new NKS_NavUnit();
        unit1.enhetNr = '12345';
        unit1.navn = 'Test Enhet1';
        unit1.underEtableringDato= Date.newInstance(1970, 1, 1);

        NKS_NavUnit unit2 = new NKS_NavUnit();
        unit2.enhetNr = '12346';
        unit2.navn = 'Test Enhet2';
        unit2.underEtableringDato= Date.newInstance(1970, 1, 1);

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', JSON.serialize(new List<NKS_NavUnit>{ unit1, unit2 }),
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitsResponse result;
        
        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitFilteredList(new List<String>{'1234'}, new List<String>{'1234'}, 'Test');
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(2, result.units.size(), 'Expected to get two units back');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');

    }

    @IsTest static void getNavUnitFilteredList_TestFailure() {
        SingleRequestMock httpMock = new SingleRequestMock(400, 'Bad Request', '',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.NavUnitsResponse result;

        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitFilteredList(null, null, '');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected to get a failure');
        System.assertEquals(null, result.units, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }

    @IsTest static void getNavUnitWorkAllocation_TestResponse() {
        NKS_NavUnitWorkAllocation unit1 = new NKS_NavUnitWorkAllocation();
        unit1.enhetNavn = '12345';
        unit1.enhetNr = 'Test Enhet1';
        
        NKS_NavUnitWorkAllocation unit2 = new NKS_NavUnitWorkAllocation();
        unit2.enhetNavn = '54321';
        unit2.enhetNr = 'Test Enhet2';

        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', JSON.serialize(new List<NKS_NavUnitWorkAllocation>{unit1,unit2}),
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.WorkAllocationResponse result;
        
        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitWorkAllocation(new NKS_NavUnitWorkAllocationInput());
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(true, result.success, 'Expected to get a success');
        System.assertEquals(2, result.units.size(), 'Expected to get both the units in the mock');
        System.assertEquals(null, result.errorMessage, 'Did not expected an error message');
    }

    @IsTest static void getNavUnitWorkAllocation_TestFailure() {
        SingleRequestMock httpMock = new SingleRequestMock(400, 'Bad Request', '',
        null);

        Test.setMock(HttpCalloutMock.class, httpMock);

        NKS_NorgNavUnitService.WorkAllocationResponse result;
        
        NKS_NorgNavUnitService service = new NKS_NorgNavUnitService();

        Test.startTest();
        result = service.getNavUnitWorkAllocation(new NKS_NavUnitWorkAllocationInput());
        Test.stopTest();

        System.assertEquals(false, result.success, 'Did not expect to get a success');
        System.assertEquals(null, result.units, 'Expected to get NULL');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }

}
