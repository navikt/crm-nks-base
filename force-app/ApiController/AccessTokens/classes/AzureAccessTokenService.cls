public with sharing class AzureAccessTokenService {
    public static Map<String, String> getValidToken(
        String accessToken,
        DateTime accessTokenExpiration,
        String refreshToken
    ) {
        Map<String, String> tokenByType = new Map<String, String>();
        //returns valid access and refresh token
        if (refreshToken == null) {
            return tokenByType;
        }
        if (accessTokenExpiration > System.now()) {
            String decryptedAccessToken = CryptoService.decryptString(accessToken);
            String decryptedRefreshToken = CryptoService.decryptString(refreshToken);
            tokenByType.put('access', decryptedAccessToken);
            tokenByType.put('refresh', decryptedRefreshToken);
            return tokenByType;
        }

        //generate new tokens
        String decryptedRefreshToken = CryptoService.decryptString(refreshToken);
        return AzureAccessTokenService.getTokensFromRefreshToken(decryptedRefreshToken);
    }

    public static String getAuthorizationCodeUrl() {
        AzureAdAuthorizationCode__c azureAdConfig = AzureAdAuthorizationCode__c.getOrgDefaults();
        String baseUrl = azureAdConfig.AuthorizeUrl__c;
        String key = azureAdConfig.ConsumerKey__c;
        String redirectUrl = azureAdConfig.RedirectUrl__c;
        String scope = azureAdConfig.Scope__c;
        Id userId = UserInfo.getUserId();
        return baseUrl +
            '?client_id=' +
            key +
            '&response_type=code&redirect_uri=' +
            redirectUrl +
            '&response_mode=query&scope=' +
            scope +
            '&state=' +
            userId;
    }

    public static Map<String, String> getTokensFromAuthorizationCode(String code) {
        Map<String, String> tokenByType = new Map<String, String>();
        AzureAdAuthorizationCode__c azureAdConfig = AzureAdAuthorizationCode__c.getOrgDefaults();
        String redirectUrl = azureAdConfig.RedirectUrl__c;
        String scope = azureAdConfig.Scope__c;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AzureAd');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        req.setBody(
            'grant_type=authorization_code&scope=' +
            scope +
            '&redirect_uri=' +
            redirectUrl +
            '&client_id={!$Credential.UserName}&client_secret={!$Credential.Password}&code=' +
            code
        );
        HttpResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            String accessToken = getTokenValueFromResponse(res.getBody(), 'access_token');
            String refreshToken = getTokenValueFromResponse(res.getBody(), 'refresh_token');
            tokenByType.put('access', accessToken);
            tokenByType.put('refresh', refreshToken);

            //save refresh token to db
            CachedTokensHandler.saveRefreshToken(refreshToken);
        } else {
            logError(res, 'Error from AzureAccessTokenService.getTokensFromAuthorizationCode');
        }
        return tokenByType;
    }

    public static Map<String, String> getTokensFromRefreshToken(String refreshToken) {
        Map<String, String> tokenByType = new Map<String, String>();
        AzureAdAuthorizationCode__c azureAdConfig = AzureAdAuthorizationCode__c.getOrgDefaults();
        String redirectUrl = azureAdConfig.RedirectUrl__c;
        String scope = azureAdConfig.Scope__c + '%20user.read';

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AzureAd');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        req.setBody(
            'grant_type=refresh_token&scope=' +
            scope +
            '&redirect_uri=' +
            redirectUrl +
            '&client_id={!$Credential.UserName}&client_secret={!$Credential.Password}&refresh_token=' +
            refreshToken
        );
        HttpResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            tokenByType.put('access', getTokenValueFromResponse(res.getBody(), 'access_token'));
            tokenByType.put('refresh', getTokenValueFromResponse(res.getBody(), 'refresh_token'));
        } else {
            logError(res, 'Error from AzureAccessTokenService.getTokensFromRefreshToken');
        }
        return tokenByType;
    }

    /**
     * @description: Refresh a service token that has expired
     * @author Stian Ruud Schikora | 10-21-2020
     * @param refreshToken
     * @param serviceName
     * @param scope
     * @return String
     **/
    public static String refreshServiceToken(
        String refreshToken,
        String serviceName,
        String scope
    ) {
        AzureAdAuthorizationCode__c azureAdConfig = AzureAdAuthorizationCode__c.getOrgDefaults();
        String redirectUrl = azureAdConfig.RedirectUrl__c;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AzureAd');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        req.setBody(
            'grant_type=refresh_token&scope=' +
            scope +
            '&redirect_uri=' +
            redirectUrl +
            '&client_id={!$Credential.UserName}&client_secret={!$Credential.Password}&refresh_token=' +
            refreshToken
        );
        HttpResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            //Stores the token response in session cache
            CachedTokensHandler.cacheServiceToken(res.getBody(), serviceName);
            return getTokenValueFromResponse(res.getBody(), 'access_token');
        } else {
            logError(res, 'Error from AzureAccessTokenService.refreshServiceToken');
        }
        return null;
    }

    private static String getTokenValueFromResponse(String response, String token) {
        JSONParser parser = JSON.createParser(response);
        String tokenValue = '';
        while (parser.nextToken() != null) {
            if (parser.getText() == token) {
                parser.nextToken();
                tokenValue = parser.getText();
            }
        }
        return tokenValue;
    }

    public static string getTokenForOtherService(String token, String serviceName) {
        AccessTokenScope__c accessTokenScope = AccessTokenScope__c.getOrgDefaults();
        String scope = (String) accessTokenScope.get(serviceName + '__c');
        if (scope == null)
            return null;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AzureAd');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        req.setBody(
            'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&client_id={!$Credential.UserName}&client_secret={!$Credential.Password}&assertion=' +
            token +
            '&scope=' +
            scope +
            '&requested_token_use=on_behalf_of'
        );
        HttpResponse res = h.send(req);
        if (res.getStatusCode() == 200) {
            //Stores the token response in session cache
            CachedTokensHandler.cacheServiceToken(res.getBody(), serviceName);
            return getTokenValueFromResponse(res.getBody(), 'access_token');
        } else {
            logError(res, 'Error from AzureAccessTokenService.getTokenForOtherService');
        }
        return null;
    }

    private static void logError(HttpResponse resp, String message) {
        LoggerUtility logger = new LoggerUtility();
        logger.error(
            message +
            '\n ' +
            'Status: ' +
            resp.getStatus() +
            '\n' +
            'User: ' +
            UserInfo.getUserId() +
            '\n' +
            'Body: ' +
            resp.getBody(),
            null
        );
        logger.publish();
    }
}
