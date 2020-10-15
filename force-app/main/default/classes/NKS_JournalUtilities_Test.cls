@isTest
public class NKS_JournalUtilities_Test {
    
    private static final String TEST_AD_TOKEN = '75gugomg-124938rhwe-124352nn';

    @TestSetup
    static void makeData(){
        Cache.Session.put('local.tokens.ADTOKEN', TEST_AD_TOKEN);
    }

    @isTest
    static void testUtilities() {
        String token, stringToEncode, encodedString;
        stringToEncode = 'THIS IS A TEST';

        NKS_JournalUtilities.utilityRequest utilRequest = new NKS_JournalUtilities.utilityRequest('AD_TOKEN', stringToEncode);

        Test.startTest();
        token = NKS_JournalUtilities.handleRequest(new List<NKS_JournalUtilities.utilityRequest>{utilRequest})[0];
        utilRequest.requestType = 'ENCODE_BASE_64';
        encodedString = NKS_JournalUtilities.handleRequest(new List<NKS_JournalUtilities.utilityRequest>{utilRequest})[0];
        Test.stopTest();

        System.assertNotEquals(stringToEncode, encodedString);
        System.assertEquals(stringToEncode, EncodingUtil.base64Decode(encodedString).toString());
    }

}
