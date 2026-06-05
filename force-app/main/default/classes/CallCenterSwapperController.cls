public with sharing class CallCenterSwapperController {
    @AuraEnabled
    public static Map<String, String> getCallCenters() {
        try {
            List<CallCenter> callCenters = [
                SELECT Id, Name
                FROM CallCenter
                WHERE Name IN ('Demo Call Center Adapter', 'Puzzel Agent Adapter New')
            ];
            Map<String, String> callCenterMap = new Map<String, String>();
            for (CallCenter cc : callCenters) {
                callCenterMap.put(cc.Name, cc.Id);
            }
            return callCenterMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void swapCallCenter(Id callcenterId) {
        try {
            User usr = new User(Id = UserInfo.getUserId());
            usr.CallCenterId = callcenterId;
            update usr;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getCurrentCallCenter() {
        try {
            User currentUser = [SELECT CallCenterId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            return currentUser.CallCenterId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getCallCenterName(Id callCenterId) {
        try {
            CallCenter cc = [SELECT Name FROM CallCenter WHERE Id = :callCenterId LIMIT 1];
            return cc.Name;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
