public with sharing class NKS_SecurityMeasuresController {
    @AuraEnabled
    public static List<NKS_SecurityMeasuresController.SecurityMeasure> getSecurityMeasures(
        String parentId,
        String relationshipField,
        String parentObjectApiName
    ) {
        List<NKS_SecurityMeasuresController.SecurityMeasure> securityMeasures = new List<NKS_SecurityMeasuresController.SecurityMeasure>();

        if (String.isNotBlank(relationshipField)) {
            parentId = getAccountId(parentId, relationshipField, parentObjectApiName);
        }

        List<SecurityMeasure__c> securityMeasureList = [
            SELECT Id, INT_Person__c, INT_SecurityMeasure__c, INT_ValidFromDate__c, INT_ValidToDate__c
            FROM SecurityMeasure__c
            WHERE INT_Person__c IN (SELECT CRM_Person__c FROM Account WHERE Id = :parentId)
        ];
        for (SecurityMeasure__c sm : securityMeasureList) {
            securityMeasures.add(
                new SecurityMeasure(sm.Id, sm.INT_ValidToDate__c, sm.INT_ValidFromDate__c, sm.INT_SecurityMeasure__c)
            );
        }

        return securityMeasures;
    }

    private static Id getAccountId(String parentId, String relationshipField, String parentObjectApiName) {
        String query = 'SELECT ' + relationshipField + ' FROM ' + parentObjectApiName + ' WHERE Id =:parentId';
        sObject parentObject = Database.query(String.escapeSingleQuotes(query))[0];

        return (Id) parentObject.get(relationshipField);
    }

    public class SecurityMeasure {
        @AuraEnabled
        public Id RecordId { get; set; }
        @AuraEnabled
        public Date ToDate { get; set; }
        @AuraEnabled
        public Date FromDate { get; set; }
        @AuraEnabled
        public string SecurityMeasure { get; set; }

        public SecurityMeasure(Id recordId, Date toDate, Date fromDate, String securityMeasure) {
            this.RecordId = recordId;
            this.ToDate = toDate;
            this.FromDate = fromDate;
            this.SecurityMeasure = securityMeasure;
        }
    }
}
