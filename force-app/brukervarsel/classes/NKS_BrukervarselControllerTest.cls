@IsTest
private with sharing class NKS_BrukervarselControllerTest {
    @IsTest
    static void getBrukerNotifikasjonFromIdentTest() {
        ApiMock.setTestMock('TMS_SERVICE_PATH', 200, 'OK');

        Test.startTest();
        List<NKS_BrukervarslingBestilling> brukernotifikasjoner = NKS_BrukerVarselController.getBrukerNotifikasjonFromIdent('10108000398');
        Test.stopTest();

        Assert.isFalse(brukernotifikasjoner.isEmpty());
    }    

    @IsTest
    static void getBrukerNotifikasjonFromIdentExceptionTest() {
        ApiMock.setTestMock('TMS_SERVICE_PATH', 500, 'Error');

        Test.startTest();
        try {
            List<NKS_BrukervarslingBestilling> brukernotifikasjoner = NKS_BrukerVarselController.getBrukerNotifikasjonFromIdent('10108000398');
        } catch (AuraHandledException ex) {
            System.assert(true, 'Correct exception');
        } catch (Exception ex) {
            System.assert(false, 'Wrong exception');
        }
        Test.stopTest();
    }    
}
