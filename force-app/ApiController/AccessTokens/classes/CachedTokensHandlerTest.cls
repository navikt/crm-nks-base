@IsTest
private class CachedTokensHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.insertEncryptionKey();
    }

    /*@IsTest
    private static void getAccessToken_whenNewTokenIsGenerated(){
        Test.setMock(HttpCalloutMock.class, new AzureAdMockHttpResponseGenerator());
        Test.startTest();
        String token=CachedTokensHandler.getAccessToken();
        Test.stopTest();
        System.assertEquals('testToken', token,'Return new token');
    }*/

    @isTest
    private static void testCacheServiceToken() {
        Map<String, Object> tokenDataMap = new Map<String, Object>();
        tokenDataMap.put('expires_in', 3600);
        CachedTokensHandler.cacheServiceToken(JSON.serialize(tokenDataMap), 'TESTSERVICE');
        //No assert as session cache reading is problematic to test
    }

    @isTest
    private static void testGetServiceToken() {
        Test.startTest();
        String accessToken = CachedTokensHandler.getServiceToken('TESTSERVICE');
        Test.stopTest();

        System.assertEquals(accessToken, 'TEST_ACCESS');
    }

    @isTest
    private static void saveRefreshToken() {
        Log__c oldToken = new Log__c(CRM_Payload__c = 'oldToken', CRM_Type__c = 'Refresh Token');
        insert oldToken;

        Test.startTest();
        CachedTokensHandler.saveRefreshToken('newToken');
        Test.stopTest();

        List<Log__c> logs = [SELECT CRM_Payload__c FROM Log__c WHERE CRM_Type__c = 'Refresh Token'];
        System.assertEquals(1, logs.size());
        String decryptedToken = CryptoService.decryptString(logs[0].CRM_Payload__c);
        System.assertEquals('newToken', decryptedToken);
    }

    @isTest
    private static void getRefreshTokenFromDatabase() {
        Log__c tokenLog = new Log__c(
            CRM_Payload__c = CryptoService.encryptString('token'),
            CRM_Type__c = 'Refresh Token'
        );
        insert tokenLog;

        Test.startTest();
        String refreshToken = CachedTokensHandler.getRefreshTokenFromDatabase();
        Test.stopTest();

        System.assertEquals('token', refreshToken, 'Refresh token is returned');
    }

    @isTest
    private static void getRefreshTokenFromDatabase_whenTokenDoesNotExist() {
        Test.startTest();
        String refreshToken = CachedTokensHandler.getRefreshTokenFromDatabase();
        Test.stopTest();

        System.assertEquals(null, refreshToken, 'Refresh token is null');
    }
}
