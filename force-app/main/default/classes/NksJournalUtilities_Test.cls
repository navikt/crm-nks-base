@isTest
public class NksJournalUtilities_Test {
    
    private static final String TEST_AD_TOKEN = '75gugomg-124938rhwe-124352nn';

    @TestSetup
    static void makeData(){
        Cache.Session.put('local.tokens.ADTOKEN', TEST_AD_TOKEN);
System.debug('TOKEN TEST SETUP: ' +  (String) Cache.Session.getPartition('local.tokens').get('ADTOKEN'));
    }

    @isTest
    static void testUtilities() {
        String token, stringToEncode, encodedString;
        stringToEncode = 'THIS IS A TEST';

        NksJournalUtilities.utilityRequest utilRequest = new NksJournalUtilities.utilityRequest('AD_TOKEN', stringToEncode);

        Test.startTest();
        token = NksJournalUtilities.handleRequest(new List<NksJournalUtilities.utilityRequest>{utilRequest})[0];
        utilRequest.requestType = 'ENCODE_BASE_64';
        encodedString = NksJournalUtilities.handleRequest(new List<NksJournalUtilities.utilityRequest>{utilRequest})[0];
        Test.stopTest();

        System.assertNotEquals(stringToEncode, encodedString);
        //System.assertEquals(TEST_AD_TOKEN, token);
        System.assertEquals(stringToEncode, EncodingUtil.base64Decode(encodedString).toString());
    }

}
