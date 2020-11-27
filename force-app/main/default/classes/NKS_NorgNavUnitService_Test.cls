@IsTest
private with sharing class NKS_NorgNavUnitService_Test {
    
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
        System.assertEquals(null, result.unit, 'Expected to get the unit same unit as in the mock');
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
        System.assertEquals(null, result.units, 'Expected to get both the units in the mock');
        System.assertEquals(true, String.isNotBlank(result.errorMessage), 'Expected an error message to be set');
    }

}
