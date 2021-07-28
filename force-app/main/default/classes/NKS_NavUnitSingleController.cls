public with sharing class NKS_NavUnitSingleController {
    @AuraEnabled(cacheable=true)
    public static NavUnit findUnit(String value, String type) {
        try {
            switch on type {
                when 'PERSON_LOCATION' {
                    Person__c p = String.isNotBlank(value) ? getPerson(value) : null;

                    return p != null ? NorgNavUnits.getPersonNavUnit(p) : null;
                }
                when 'UNIT_NUMBER' {
                    return NorgNavUnits.getNavUnit(value);
                }
            }
        } catch (Exception e) {
            throw new AuraException(e.getMessage());
        }

        return null;
    }

    private static Person__c getPerson(Id personId) {
        return [
            SELECT Id, INT_IsNavEmployee__c, INT_Confidential__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c
            FROM Person__c
            WHERE Id = :personId
        ][0];
    }

    @AuraEnabled(cacheable=true)
    public static NavUnitContactInformation getContactInformation(String unitNumber) {
        try {
            return NorgNavUnits.getNavUnitContactInformation(unitNumber);
        } catch (Exception e) {
            throw new AuraException(e.getMessage());
        }
    }
}
