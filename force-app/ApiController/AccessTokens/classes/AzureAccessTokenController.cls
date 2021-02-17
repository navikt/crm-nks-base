public with sharing class AzureAccessTokenController {
    public PageReference redirect() {
        String code = apexpages.currentPage().getParameters().get('code');
        if (code == null) {
            //Initiate token
            String initiateUrl = AzureAccessTokenService.getAuthorizationCodeUrl();
            pageReference pg = new pageReference(initiateUrl);
            return pg.setRedirect(true);
        }
        Map<String, String> tokenByType = AzureAccessTokenService.getTokensFromAuthorizationCode(
            code
        );
        if (tokenByType.size() == 2) {
            //store access and refresh token in session
            Cache.SessionPartition sessionPart = Cache.Session.getPartition('local.tokens');
            sessionPart.put('accesstoken', CryptoService.encryptString(tokenByType.get('access')));
            sessionPart.put(
                'refreshtoken',
                CryptoService.encryptString(tokenByType.get('refresh'))
            );
            sessionPart.put('expires', System.now().addMinutes(59));
        }
        return Auth.SessionManagement.finishLoginFlow();
    }
}
