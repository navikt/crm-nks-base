@IsTest
private with sharing class NKS_SafJournalPostListControllerTest {
    @IsTest
    static void getJournalPosts() {
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'UGRADERT',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = true,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        String brukerIdField = 'Id';
        String objectApiName = 'Person__c';
        String relationshipField = 'Id';
        String viewedRecordId = p.Id;

        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();
        queryVariables.foerste = 10;

        NKS_SafQueryField queryField = new NKS_SafQueryField();
        queryField.name = 'Test';

        NKS_SafQueryResponse result;

        NKS_SafDokumentoversikt dokumentoversikt = new NKS_SafDokumentoversikt();
        dokumentoversikt.journalposter = new List<NKS_SafJournalpost>();
        dokumentoversikt.sideInfo = new NKS_SafSideInfo();
        dokumentoversikt.sideInfo.finnesNesteSide = false;

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'Success',
            '{  "data": { "dokumentoversiktBruker": ' +
            JSON.serialize(dokumentoversikt) +
            '}}',
            new Map<String, String>()
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        result = NKS_SafJournalPostListController.getJournalPosts(
            brukerIdField,
            objectApiName,
            relationshipField,
            viewedRecordId,
            queryVariables,
            queryField
        );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Expected success');
        System.assertEquals(0, result.documentOverview.journalposter.size(), 'Expected empty list');
    }

    @IsTest
    static void getNavCases() {
        Person__c p = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(
                INT_ActorId__c = '100003000120',
                INT_Confidential__c = 'UGRADERT',
                INT_FirstName__c = 'Harry',
                INT_IsNavEmployee__c = true,
                INT_LastName__c = 'Potter'
            ),
            true
        );

        String brukerIdField = 'Id';
        String objectApiName = 'Person__c';
        String relationshipField = 'Id';
        String viewedRecordId = p.Id;

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'Success',
            '[]',
            new Map<String, String>()
        );
        Test.setMock(HttpCalloutMock.class, mock);

        List<NKS_NavCaseService.NavCaseWrapper> result;

        Test.startTest();
        result = NKS_SafJournalPostListController.getNavCases(
            brukerIdField,
            objectApiName,
            relationshipField,
            viewedRecordId
        );
        Test.stopTest();

        System.assertEquals(0, result.size(), 'expected empty list');
    }
}
