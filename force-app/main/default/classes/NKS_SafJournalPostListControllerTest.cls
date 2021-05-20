@IsTest
private with sharing class NKS_SafJournalPostListControllerTest {
    @IsTest
    static void getJournalPosts() {
        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();
        queryVariables.foerste = 10;

        NKS_SafQueryResponse result;

        NKS_SafQueryResponse resp = new NKS_SafQueryResponse();
        resp.data = new NKS_SafQueryResponse.NKS_SAFData();
        resp.data.dokumentoversiktBruker = new NKS_SafDokumentoversikt();
        resp.data.dokumentoversiktBruker.journalposter = new List<NKS_SafJournalpost>();
        resp.data.dokumentoversiktBruker.sideInfo = new NKS_SafSideInfo();
        resp.data.dokumentoversiktBruker.sideInfo.finnesNesteSide = false;

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'Success',
            JSON.serialize(resp, true),
            new Map<String, String>()
        );

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        result = NKS_SafJournalPostListController.getJournalPosts(JSON.serialize(queryVariables));
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Expected success');
        System.assertEquals(0, result.data.dokumentoversiktBruker.journalposter.size(), 'Expected empty list');
    }

    @IsTest
    static void getNavCases() {
        SingleRequestMock mock = new SingleRequestMock(200, 'Success', '[]', new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        List<NKS_NavCaseService.NavCaseWrapper> result;

        Test.startTest();
        result = NKS_SafJournalPostListController.getNavCases('100003000120');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'expected empty list');
    }
}
