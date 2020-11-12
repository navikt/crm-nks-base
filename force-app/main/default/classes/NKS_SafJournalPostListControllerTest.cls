@IsTest
private with sharing class NKS_SafJournalPostListControllerTest {
    @isTest static void getJournalposts_Test() {
        NKS_SafApexTypes.SafQueryResponse result;

        //Prepare mock
        NKS_SafServiceMock mock = new NKS_SafServiceMock();
        NKS_SafApexTypes.SafQueryResponse queryResponse = new NKS_SafApexTypes.SafQueryResponse();
        queryResponse.isSuccess = true;
        queryResponse.documentOverview = new NKS_SafApexTypes.Dokumentoversikt();
        mock.addSafQueryResponse(queryResponse);

        //Set mock
        NKS_SafJournalPostListController.safService = (NKS_SafService) Test.createStub(NKS_SafService.class, mock);

        //Prepare input data
        NKS_SafApexTypes.SafQueryVariables qv = new NKS_SafApexTypes.SafQueryVariables();

        NKS_SafApexTypes.SafQueryField queryField = new NKS_SafApexTypes.SafQueryField('tittel');
        queryField.queryFields.add(new NKS_SafApexTypes.SafQueryField('journalpost'));
        // NKS_SafApexTypes.SafQueryField queryField1 = new NKS_SafApexTypes.SafQueryField('tittel');
        // //queryField1.name = 'tittel';
        
        // NKS_SafApexTypes.SafQueryField queryField2 = new NKS_SafApexTypes.SafQueryField('journalpost');
        // //queryField2.name = 'journalpost';
        // //queryField2.queryFields = new List<NKS_SafApexTypes.SafQueryField>();
        // queryField2.queryFields.add(queryField1);

        Test.startTest();
            result = NKS_SafJournalPostListController.getJournalpostsUser(JSON.serialize(qv), JSON.serialize(queryField));
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did expect to get a value in response');
        System.assertEquals(true, result.isSuccess, 'Expected to have a success');
    }

    @isTest static void getJournalposts_TriggerExceptionTest() {
        NKS_SafApexTypes.SafQueryResponse result;

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
