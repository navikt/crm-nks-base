@IsTest
private class AzureAccessTokenServiceTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.insertEncryptionKey();
    }

    @IsTest
    private static void getAuthorizationCodeUrl() {
        //define custom settings
        AzureAdAuthorizationCode__c azureAdConfig = new AzureAdAuthorizationCode__c();
        azureAdConfig.AuthorizeUrl__c = 'https://auth.url';
        azureAdConfig.RedirectUrl__c = 'https://redirect.url';
        azureAdConfig.ConsumerKey__c = 'testKey';
        azureAdConfig.Scope__c = 'offline_access%20user.read';
        insert azureAdConfig;

        String expectedUrl =
            'https://auth.url?client_id=testKey&response_type=code&redirect_uri=https://redirect.url&response_mode=query' +
            '&scope=offline_access%20user.read&state=' +
            UserInfo.getUserId();

        String actualUrl = AzureAccessTokenService.getAuthorizationCodeUrl();
        System.assertEquals(expectedUrl, actualUrl);
    }

    static testMethod void getTokensFromAuthorizationCode() {
        Test.setMock(HttpCalloutMock.class, new AzureAdMockHttpResponseGenerator());
        Test.startTest();
        Map<String, String> tokenByType = AzureAccessTokenService.getTokensFromAuthorizationCode(
            'code'
        );
        Test.stopTest();
        System.assertEquals(2, tokenByType.size());
        System.assertEquals('testToken', tokenByType.get('access'));
        System.assertEquals('refreshToken', tokenByType.get('refresh'));

        List<Log__c> logs = [SELECT CRM_Payload__c FROM Log__c WHERE CRM_Type__c = 'Refresh Token'];
        System.assertEquals(1, logs.size());
        String decryptedStoredToken = CryptoService.decryptString(logs[0].CRM_Payload__c);
        System.assertEquals('refreshToken', decryptedStoredToken);
    }

    static testMethod void getTokensFromRefreshToken() {
        Test.setMock(HttpCalloutMock.class, new AzureAdMockHttpResponseGenerator());
        Test.startTest();
        Map<String, String> tokenByType = AzureAccessTokenService.getTokensFromRefreshToken(
            'refreshToken'
        );
        Test.stopTest();

        System.assertEquals(2, tokenByType.size());
        System.assertEquals('testToken', tokenByType.get('access'));
        System.assertEquals('refreshToken', tokenByType.get('refresh'));
    }

    @IsTest
    private static void getValidToken_whenCachedAccessTokenIsValid() {
        Map<String, String> tokenByType = AzureAccessTokenService.getValidToken(
            CryptoService.encryptString('inputToken'),
            DateTime.now().addMinutes(10),
            CryptoService.encryptString('inputRefreshToken')
        );
        System.assertEquals(2, tokenByType.size(), 'access and refresh tokens should be returned');
        System.assertEquals('inputToken', tokenByType.get('access'), 'Input token should be valid');
        System.assertEquals(
            'inputRefreshToken',
            tokenByType.get('refresh'),
            'Input token should be unchaged'
        );
    }

    @IsTest
    private static void getValidToken_whenNoDataInCache() {
        Map<String, String> tokenByType = AzureAccessTokenService.getValidToken(null, null, null);
        System.assertEquals(0, tokenByType.size(), 'No tokes found');
    }

    @IsTest
    private static void getValidToken_whenAccessTokenIsExpired() {
        Test.setMock(HttpCalloutMock.class, new AzureAdMockHttpResponseGenerator());
        Test.startTest();
        Map<String, String> tokenByType = AzureAccessTokenService.getValidToken(
            CryptoService.encryptString('inputToken'),
            DateTime.now().addMinutes(-5),
            CryptoService.encryptString('refreshToken')
        );
        Test.stopTest();

        System.assertEquals(2, tokenByType.size(), 'access and refresh tokens should be returned');
        System.assertEquals(
            'testToken',
            tokenByType.get('access'),
            'New access token should be generated from azure api'
        );
        System.assertEquals(
            'refreshToken',
            tokenByType.get('refresh'),
            'New refresh token should be generated from azure api'
        );
    }

    @IsTest
    private static void getTokenForOtherService_saf() {
        AccessTokenScope__c accessTokenScope = new AccessTokenScope__c();
        accessTokenScope.Saf__c = 'api://scope';
        insert accessTokenScope;
        Test.setMock(HttpCalloutMock.class, new AzureAdMockHttpResponseGenerator());
        Test.startTest();
        String safAccessToken = AzureAccessTokenService.getTokenForOtherService('token', 'saf');
        Test.stopTest();
        System.assertEquals('testToken', safAccessToken);
    }

    @isTest
    private static void testRefreshServiceToken() {
        AccessTokenScope__c accessTokenScope = new AccessTokenScope__c();
        accessTokenScope.Saf__c = 'api://scope';
        insert accessTokenScope;
        Test.setMock(HttpCalloutMock.class, new AzureAdMockHttpResponseGenerator());

        Test.startTest();
        String accessToken = AzureAccessTokenService.refreshServiceToken(
            'refreshtoken',
            'saf',
            'scopes'
        );
        Test.stopTest();

        System.assertEquals('testToken', accessToken);
    }
}
