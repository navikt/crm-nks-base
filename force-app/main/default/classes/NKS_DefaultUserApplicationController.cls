public with sharing class NKS_DefaultUserApplicationController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getDefaultAppUserCount() {
        try {
            List<UserAppInfo> userAppInfoList = [SELECT UserId, AppDefinitionId FROM UserAppInfo WHERE User.IsActive = TRUE];
            
            List<Id> appDefinitionIds = new List<Id>();
            for (UserAppInfo userAppInfo : userAppInfoList) {
                appDefinitionIds.add(userAppInfo.AppDefinitionId);
            }

            Map<Id, String> appDefinitionDevNameByDurableId = new Map<Id, String>();
            for (AppDefinition appDefinition : [SELECT DurableId, DeveloperName FROM AppDefinition WHERE DurableId IN :appDefinitionIds]) {
                appDefinitionDevNameByDurableId.put(appDefinition.DurableId, appDefinition.DeveloperName);
            }

            Map<String, Integer> appUserCountMap = new Map<String, Integer>();
            for (UserAppInfo userAppInfo : userAppInfoList) {
                if (appDefinitionDevNameByDurableId.containsKey(userAppInfo.AppDefinitionId)) {
                    String appName = appDefinitionDevNameByDurableId.get(userAppInfo.AppDefinitionId);
                    if (appUserCountMap.containsKey(appName)) {
                        appUserCountMap.put(appName, appUserCountMap.get(appName) + 1);
                    } else {
                        appUserCountMap.put(appName, 1);
                    }
                }
            }
            return appUserCountMap;
        } catch (Exception e) {
            throw new GetDefaultAppUserCountException(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUsersDefaultApp(String userIdOrUsername) {
        try {
            User user = [SELECT Id FROM User WHERE IsActive = TRUE AND (Id = :userIdOrUsername OR Name = :userIdOrUsername) LIMIT 1];
            if (user == null) {
                return '';
            }
            UserAppInfo userAppInfo = [SELECT AppDefinitionId FROM UserAppInfo WHERE UserId = :user.Id LIMIT 1];
            if (userAppInfo != null) {
                AppDefinition appDefinition = [SELECT DeveloperName FROM AppDefinition WHERE DurableId = :userAppInfo.AppDefinitionId LIMIT 1];
                return appDefinition != null ? appDefinition.DeveloperName : '';
            }
        } catch (Exception e) {
            throw new NoUserFoundException(e);
        }
        return '';
    }

    private class NoUserFoundException extends Exception {}
    private class GetDefaultAppUserCountException extends Exception {}
}