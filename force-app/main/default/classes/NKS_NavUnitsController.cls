public with sharing class NKS_NavUnitsController {
    @AuraEnabled(cacheable=true)
    public static String getUnits() {
        List<PicklistValue> picklistValues = new List<picklistValue>();
        for (NavUnit__c unit : getUnitsFromDatabase()) {
            picklistValues.add(new PicklistValue(unit.CRM_QueueId__c, unit.NKS_Name_Short__c));
        }
        String jSONList = JSON.serialize(picklistValues);
        return jSONList;
    }

    private static List<NavUnit__c> getUnitsFromDatabase() {
        return [
            SELECT Id, CRM_QueueId__c, NKS_Name_Short__c
            FROM NavUnit__c
            WHERE CRM_QueueId__c != NULL
            ORDER BY NKS_Name_Short__c
        ];
    }

    public class PicklistValue {
        public String value { get; set; }
        public String label { get; set; }

        public PicklistValue(String param1, String param2) {
            value = param1;
            label = param2;
        }
    }
}
