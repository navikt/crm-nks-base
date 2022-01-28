public without sharing class NKS_FamilyViewControllerHelper {
    public static Person__c getPerson(Set<String> identsList){
        if(identsList == null){
            return null;
        }
        return [SELECT Id, INT_AddressMunicipalityNumber__c, INT_AddressDistrictNumber__c, INT_IsNavEmployee__c, INT_Confidential__c, INT_DateOfBirth__c, INT_DateOfDeath__c, NKS_Full_Name__c, INT_ResidentialZipCode__c, INT_Sex__c, INT_ResidentialAddress__c FROM Person__c WHERE Name IN :identsList LIMIT 1];
    }
}
