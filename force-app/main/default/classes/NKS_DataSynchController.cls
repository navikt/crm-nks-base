public without sharing class NKS_DataSynchController {
    private static Map<String, Id> themeGroupMap {
        get {
            if (themeGroupMap == null) {
                themeGroupMap = new Map<String, Id>();
                for (Common_Code__c themeGroup : [
                    SELECT Id, CRM_Code__c
                    FROM Common_Code__c
                    WHERE CRM_Code_Set__c = 'Temagrupper'
                ]) {
                    themeGroupMap.put(themeGroup.CRM_Code__c, themeGroup.Id);
                }
            }
            return themeGroupMap;
        }
        set {
        }
    }

    @AuraEnabled
    public static Boolean doBankAccountNumberSync(String ident) {
        Boolean isSynced = true;

        try {
            TPS_Persons.getBankkonto(ident, true);
        } catch (Exception e) {
            isSynced = false;
        }

        return isSynced;
    }
}
