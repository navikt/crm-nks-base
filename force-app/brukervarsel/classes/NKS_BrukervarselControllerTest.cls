@IsTest
private with sharing class NKS_BrukervarselControllerTest {
    @IsTest
    static void importBrukervarselNotificationsSuccess() {
        ApiMock.setTestMock('GET_VARSEL_FROM_BRUKER_ID', 200, 'OK');
        List<NKS_BrukervarslingBestilling> result;
        Test.startTest();
        result = NKS_BrukervarselController.getBrukerVarselFromActorId('100003000120', Date.today(), Date.today());
        Test.stopTest();

        System.assertEquals(6, result.size(), 'Excpected three items in list');
    }

    @IsTest
    static void importBrukervarselNotificationsError() {
        ApiMock.setTestMock('GET_VARSEL_FROM_BRUKER_ID', 500, 'Error');

        Test.startTest();
        try {
            NKS_BrukervarselController.getBrukerVarselFromActorId('100003000120', Date.today(), Date.today());
        } catch (AuraHandledException ex) {
            System.assert(true, 'Correct exception');
        } catch (Exception ex) {
            System.assert(false, 'Wrong exception');
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected an error logged');
    }
}
