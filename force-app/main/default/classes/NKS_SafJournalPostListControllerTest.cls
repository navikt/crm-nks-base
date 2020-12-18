@IsTest
private with sharing class NKS_SafJournalPostListControllerTest {
    @isTest static void getJournalpostsTest() {
        NKS_SafQueryResponse result;

        //Prepare mock
        NKS_SafServiceMock mock = new NKS_SafServiceMock();
        NKS_SafQueryResponse queryResponse = new NKS_SafQueryResponse();
        queryResponse.isSuccess = true;
        queryResponse.documentOverview = new NKS_SafDokumentoversikt();
        mock.addSafQueryResponse(queryResponse);

        //Set mock
        NKS_SafJournalPostListController.safService = (NKS_SafService) Test.createStub(NKS_SafService.class, mock);

        //Prepare input data
        NKS_SafQueryVariables qv = new NKS_SafQueryVariables();

        NKS_SafQueryField queryField = new NKS_SafQueryField('tittel');
        queryField.queryFields.add(new NKS_SafQueryField('journalpost'));

        Test.startTest();
            result = NKS_SafJournalPostListController.getJournalpostsUser(qv, queryField);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did expect to get a value in response');
        System.assertEquals(true, result.isSuccess, 'Expected to have a success');
    }

    @isTest static void getJournalpostsTriggerExceptionTest() {
        NKS_SafQueryResponse result;

        Test.startTest();
            result = NKS_SafJournalPostListController.getJournalpostsUser(null,null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did expect to get a value in response');
        System.assertEquals(false, result.isSuccess, 'Expected the result to not be success when missing input data');
        System.assertNotEquals(null, result.error, 'Expected to have the error object not returning null when we have a handled exception');
        System.assertEquals(true, String.isNotBlank(result.error.error), 'Expected to have a value in error');
        System.assertEquals(true, String.isNotBlank(result.error.message), 'Expected to have something in the error message field');
    }
}
