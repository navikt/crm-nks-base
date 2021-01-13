public with sharing class NKSNavTaskWorkAllocationController {
    private static NKS_NorgNavUnitService service {get{if(null == service){service = new NKS_NorgNavUnitService();}return service;} set;}

    @AuraEnabled(cacheable=true)
    public static NKS_NorgNavUnitService.WorkAllocationResponse getWorkAllocations(String personId, String themeGroupCode, String themeCode, String themeSubThemeCode, String taskType) {
        NKS_NavUnitPersonUtility utility = new NKS_NavUnitPersonUtility(service);

        NKS_NorgNavUnitService.WorkAllocationResponse response = utility.getWorkAllocation(personId, themeGroupCode, themeCode, themeSubThemeCode, taskType);
        
        setUnitId(response.units);

        return response;
    }

    private static void setUnitId(List<NKS_NavUnitWorkAllocation> responseUnits) {
        Map<String,NKS_NavUnitWorkAllocation> unitMap = new Map<String,NKS_NavUnitWorkAllocation>();

        for(NKS_NavUnitWorkAllocation unit : responseUnits) {
            unitMap.put(unit.enhetNr, unit);
        }

        for(NavUnit__c sfUnit : [SELECT Id, INT_UnitNumber__c FROM NavUnit__c WHERE INT_UnitNumber__c IN :unitMap.keySet()]) {
            NKS_NavUnitWorkAllocation unit = unitMap.get(sfUnit.INT_UnitNumber__c);

            unit.sfId = null == unit ? '' : sfUnit.Id;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUserNavUnitId(String userUnitNumber) {
        return [SELECT Id FROM NavUnit__c WHERE INT_UnitNumber__c =: userUnitNumber]?.Id;
    }
}
