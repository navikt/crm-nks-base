@IsTest
private with sharing class NKS_SafJournalPostListControllerTest {
    @isTest static void getJournalposts_Test() {
        NKS_SafApexTypes.SafQueryResponse result;

        NKS_SafServiceMock mock = new NKS_SafServiceMock();
        NKS_SafApexTypes.SafQueryResponse queryResponse = new NKS_SafApexTypes.SafQueryResponse();
        queryResponse.isSuccess = true;
        queryResponse.documentOverview = new NKS_SafApexTypes.Dokumentoversikt();
        mock.addSafQueryResponse(queryResponse);

        NKS_SafJournalPostListController.safService = (NKS_SafService) Test.createStub(NKS_SafService.class, mock);

        Test.startTest();
            result = NKS_SafJournalPostListController.getJournalposts('1234567890','AKTOERID');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did expect to get a value in response');
        System.assertEquals(true, result.isSuccess, 'Expected to have a success');
    }

    @isTest static void getJournalposts_TriggerExceptionTest() {
        NKS_SafApexTypes.SafQueryResponse result;

        Test.startTest();
            result = NKS_SafJournalPostListController.getJournalposts(null,null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did expect to get a value in response');
        System.assertEquals(false, result.isSuccess, 'Expected the result to not be success when missing input data');
        System.assertNotEquals(null, result.error, 'Expected to have the error object not returning null when we have a handled exception');
        System.assertEquals(true, String.isNotBlank(result.error.error), 'Expected to have a value in error');
        System.assertEquals(true, String.isNotBlank(result.error.message), 'Expected to have something in the error message field');
    }
}
