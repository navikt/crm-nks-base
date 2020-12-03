public with sharing class NKS_NavUnitPersonUtility {
    @TestVisible NKS_NorgNavUnitService service;

    public NKS_NavUnitPersonUtility(NKS_NorgNavUnitService service) {
        this.service = service;
    }

    /**
     * @description Use the person id to find the location, shielded and discretionaryCode
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person
     * @return NKS_NorgNavUnitService.NavUnitResponse
     */
    public NKS_NorgNavUnitService.NavUnitResponse getNavUnitFromPerson(Id personId) {
        Person__c person = [SELECT Id,
                                INT_Confidential__c,
                                INT_GTDistrictNumber__c,
                                INT_GTMunicipalityNumber__c,
                                INT_IsNavEmployee__c
                            FROM Person__c
                            WHERE Id = :personId];
        return getNavUnitFromPerson(person);
    }

    /**
     * @description Use the person record to find the location, shielded and discretionaryCode
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person
     * @return NKS_NorgNavUnitService.NavUnitResponse
     */
    public NKS_NorgNavUnitService.NavUnitResponse getNavUnitFromPerson(Person__c person) {
        Boolean isShielded = getIsShielded(person);
        String location = getLocation(person);
        String discretionCode = getDiscretionaryCode(person);

        return service.getNavUnitFromGeographicLocation(location, discretionCode, isShielded);
    }

    /**
     * @description Return true if NAV Employee.
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person [Must have the field INT_IsNavEmployee__c]
     * @return Boolean [SPSF | SPFO | ANY]
     */
    @TestVisible private Boolean getIsShielded(Person__c person) {
        if(true == person.INT_IsNavEmployee__c) {
            return true;
        }
        return false;
    }

    /**
     * @description Get the proper discretionary code based to use.
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person [Must have the field INT_Confidential__c]
     * @return String [SPSF | SPFO | ANY]
     */
    @TestVisible private String getDiscretionaryCode(Person__c person) {
        switch on person.INT_Confidential__c {
            when 'STRENGT_FORTROLIG_UTLAND', 'STRENGT_FORTROLIG' {
                return 'SPSF';
            }
            when 'FORTROLIG' {
                return 'SPFO';
            }
            when 'UGRADERT' {
                return 'ANY';
            }
        }

        return null;
    }

    /**
     * @description Find the location to use when getting a persons NAV Unit from NORG2.
     * * IF INT_TemporaryMunicipalityNumber__c has a value use that instead of INT_MunicipalityNumber__c
     * * IF INT_RegionNumber__c has a value we must add that as NORG2 needs this when finding units based on city districts
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person [Must have the fields INT_TemporaryMunicipalityNumber__c, INT_MunicipalityNumber__c and INT_RegionNumber__c]
     * @return String [The location string to use. A string of four or six numbers]
     * ? Hva hvis tomt
     * ? TEMP REGIONNUMBER?
     */
    @TestVisible private String getLocation(Person__c person) {
        String location = '';

        location += String.isNotBlank(person.INT_GTMunicipalityNumber__c) ? person.INT_GTMunicipalityNumber__c :  '';
        location += String.isNotBlank(person.INT_GTDistrictNumber__c) ? person.INT_GTDistrictNumber__c : '';

        return location;
    }
}
