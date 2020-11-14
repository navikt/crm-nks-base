@isTest
public class NKS_JournalUtilities_Test {

    @isTest
    static void testUtilities() {
        String token, stringToEncode, encodedString;
        stringToEncode = 'THIS IS A TEST';

        NKS_JournalUtilities.utilityRequest utilRequest = new NKS_JournalUtilities.utilityRequest('AD_TOKEN', stringToEncode);

        Test.startTest();
        token = NKS_JournalUtilities.handleRequest(new List<NKS_JournalUtilities.utilityRequest>{utilRequest})[0];
        utilRequest.requestType = 'GENERATE_DOCUMENT';
        encodedString = NKS_JournalUtilities.handleRequest(new List<NKS_JournalUtilities.utilityRequest>{utilRequest})[0];
        Test.stopTest();

        System.assertNotEquals(stringToEncode, encodedString);
        System.assertEquals(Blob.toPdf(stringToEncode).size(), EncodingUtil.base64Decode(encodedString).size());
    }

}
