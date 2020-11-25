@isTest
public class NKS_JournalUtilities_Test {

    @isTest
    static void testDocumentGeneration() {
        String stringToEncode, encodedString;
        stringToEncode = 'THIS IS A TEST';

        NKS_JournalUtilities.utilityRequest utilRequest = new NKS_JournalUtilities.utilityRequest('GENERATE_DOCUMENT', stringToEncode, null);

        Test.startTest();
        utilRequest.requestType = 'GENERATE_DOCUMENT';
        encodedString = NKS_JournalUtilities.handleRequest(new List<NKS_JournalUtilities.utilityRequest>{utilRequest})[0].documentString;
        Test.stopTest();

        System.assertNotEquals(stringToEncode, encodedString);
        System.assertEquals(Blob.toPdf(stringToEncode).size(), EncodingUtil.base64Decode(encodedString).size());
    }

    @isTest
    static void testPostJournal(){
        NKS_JournalEntryWrapper journalRequest = new NKS_JournalEntryWrapper();

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{"journalpostId": "3456787"}', null));

        NKS_JournalUtilities.utilityRequest utilRequest = new NKS_JournalUtilities.utilityRequest('POST_JOURNAL', null, journalRequest);

        Test.startTest();
        String journalPostId = NKS_JournalUtilities.handleRequest(new List<NKS_JournalUtilities.utilityRequest>{utilRequest})[0].journalpostId;
        Test.stopTest();

        System.assertEquals('3456787', journalPostId, 'Incorrect Journal post ID');
    }

}
