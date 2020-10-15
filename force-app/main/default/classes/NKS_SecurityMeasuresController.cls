public with sharing class NKS_SecurityMeasuresController {
    @AuraEnabled
    public static List<NKS_SecurityMeasuresController.SecurityMeasure> getSecurityMeasures(String parentId, String parentObjectApiName){
        List<NKS_SecurityMeasuresController.SecurityMeasure> securityMeasures = new List<NKS_SecurityMeasuresController.SecurityMeasure>(); 
        List<SecurityMeasure__c> securityMeasureList = [SELECT Id, INT_Person__c, INT_SecurityMeasure__c, INT_ValidFromDate__c, INT_ValidToDate__c FROM SecurityMeasure__c WHERE INT_Person__c IN (SELECT CRM_Person__c FROM Account WHERE Id =: parentId )];
        for(SecurityMeasure__c sm : securityMeasureList){
            securityMeasures.add(new SecurityMeasure(sm.Id, sm.INT_ValidToDate__c, sm.INT_ValidFromDate__c, sm.INT_SecurityMeasure__c)); 
        }

        return securityMeasures;
    }

    public class SecurityMeasure{
        @AuraEnabled
        public Id RecordId {get;set;}
        @AuraEnabled
        public Date ToDate {get;set;}
        @AuraEnabled
        public Date FromDate {get;set;}
        @AuraEnabled
        public string SecurityMeasure {get;set;}

        public SecurityMeasure(Id recordId, Date toDate, Date fromDate, String securityMeasure){
            this.RecordId=recordId;
            this.ToDate=toDate;
            this.FromDate=fromDate; 
            this.SecurityMeasure=securityMeasure;
        }
    }
}

