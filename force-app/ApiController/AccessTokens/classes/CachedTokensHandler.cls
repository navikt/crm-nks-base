public with sharing class CachedTokensHandler {
    private static final String TEST_SERVICE_TOKEN_RESPONSE =
        '{"access_token": "TEST_ACCESS", "refresh_token": "TEST_REFRESH", "scope": "TEST_SCOPE", "expires": ' +
        JSON.serialize(Datetime.now().addSeconds(3600)) +
        '}';

    public static String getAccessToken() {
        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.tokens');
        String accessTokenFromCache = (String) sessionPart.get('accesstoken');
        String refreshTokenFromCache = (String) sessionPart.get('refreshtoken');
        DateTime expires = (DateTime) sessionPart.get('expires');
        if (Test.isRunningTest()) {
            accessTokenFromCache = CryptoService.encryptString('inputToken');
            refreshTokenFromCache = CryptoService.encryptString('inputRefreshToken');
            expires = System.now().addHours(-1);
        }
        Map<String, String> tokenByType = new Map<String, String>();
        //if(accessTokenFromCache==null || refreshTokenFromCache==null || expires==null){
        //generate access token from refresh token in db
        //Issue with token expiration
        String refreshToken = getRefreshTokenFromDatabase();
        if (refreshToken == null)
            return null;
        tokenByType = AzureAccessTokenService.getTokensFromRefreshToken(refreshToken);
        //}
        //else{
        // tokenByType=AzureAccessTokenService.getValidToken(accessTokenFromCache, expires, refreshTokenFromCache);
        //}
        if (tokenByType.size() != 2) {
            return null;
        }
        if (tokenByType.get('access') != accessTokenFromCache) {
            //update cache
            sessionPart.put('accesstoken', CryptoService.encryptString(tokenByType.get('access')));
            sessionPart.put(
                'refreshtoken',
                CryptoService.encryptString(tokenByType.get('refresh'))
            );
            sessionPart.put('expires', System.now().addMinutes(59));
        }
        return tokenByType.get('access');
    }

    /**
     * @description: Reads from cache to see if there is a token available for service
     * If no token or expired, handles refresh or requesting new token
     * @author Stian Ruud Schikora | 10-21-2020
     * @param serviceName
     * @return String
     **/
    public static String getServiceToken(String serviceName) {
        String accessTokenFromCache, refreshTokenFromCache, scope;
        DateTime expires;

        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.tokens');
        String tokenData = Test.isRunningTest()
            ? CryptoService.encryptString(TEST_SERVICE_TOKEN_RESPONSE)
            : (String) sessionPart.get(serviceName + 'tokendata');
        if (String.isNotBlank(tokenData)) {
            String decryptedTokenData = CryptoService.decryptString(tokenData);
            Map<String, Object> tokenDataMap = (Map<String, Object>) JSON.deserializeUntyped(
                decryptedTokenData
            );
            accessTokenFromCache = (String) tokenDataMap.get('access_token');
            refreshTokenFromCache = (String) tokenDataMap.get('refresh_token');
            scope = (String) tokenDataMap.get('scope');
            scope = EncodingUtil.urlEncode(scope, 'UTF-8');
            String expiresString = (String) tokenDataMap.get('expires');
            expires = DateTime.valueOfGmt(expiresString.replace('T', ' '));
            if (expires > System.now()) {
                return accessTokenFromCache;
            } else {
                //AzureAccessTokenService calls cacheServiceToken to update cache
                return AzureAccessTokenService.refreshServiceToken(
                    refreshTokenFromCache,
                    serviceName,
                    scope
                );
            }
        } else {
            //AzureAccessTokenService calls cacheServiceToken to update cache
            return AzureAccessTokenService.getTokenForOtherService(getAccessToken(), serviceName);
        }
    }

    /**
     * @description: Stores a JSON formatted token response in session cache
     * @author Stian Ruud Schikora | 10-21-2020
     * @param tokenData
     * @param serviceName
     **/
    public static void cacheServiceToken(String tokenData, String serviceName) {
        Map<String, Object> tokenDataMap = (Map<String, Object>) JSON.deserializeUntyped(tokenData);
        DateTime expires = System.now().addSeconds((Integer) tokenDataMap.get('expires_in'));
        tokenDataMap.put('expires', expires);

        Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.tokens');
        sessionPart.put(
            serviceName + 'tokendata',
            CryptoService.encryptString(JSON.serialize(tokenDataMap))
        );
    }

    /**
     * @description: Stores refresh token in Log__c
     * @author Frode Hoen | 12-09-2020
     * @param refreshToken
     **/
    @future
    public static void saveRefreshToken(String refreshToken) {
        List<Log__c> existingLogs = [
            SELECT Id
            FROM Log__c
            WHERE CRM_Type__c = 'Refresh Token' AND OwnerId = :userinfo.getuserid()
        ];

        if (existingLogs.size() > 0) {
            delete existingLogs;
            Database.emptyRecycleBin(existingLogs);
        }
        String encryptedRefreshToken = CryptoService.encryptString(refreshToken);
        Log__c newRefreshTokenLog = new Log__c(
            CRM_Type__c = 'Refresh Token',
            CRM_Payload__c = encryptedRefreshToken
        );
        insert newRefreshTokenLog;
    }

    /**
     * @description: Store refresh token in Log__c
     * @author Frode Hoen | 12-09-2020
     **/
    public static string getRefreshTokenFromDatabase() {
        List<Log__c> tokenLogs = [
            SELECT CRM_Payload__c
            FROM Log__c
            WHERE CRM_Type__c = 'Refresh Token' AND OwnerId = :userinfo.getuserid()
        ];
        if (tokenLogs.size() == 0) {
            logError('Refresh token not found - getRefreshTokenFromDatabase');
            return null;
        }
        logInfo('Get refresh token from database');
        return CryptoService.decryptString(tokenLogs[0].CRM_Payload__c);
    }

    private static void logError(String message) {
        LoggerUtility logger = new LoggerUtility();
        logger.error(message + '\n ' + 'User: ' + UserInfo.getUserId() + '\n', null);
        logger.publish();
    }

    private static void logInfo(String message) {
        LoggerUtility logger = new LoggerUtility();
        logger.info(message + '\n ' + 'User: ' + UserInfo.getUserId(), null);
        logger.publish();
    }
}
