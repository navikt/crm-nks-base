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
        Person__c person = getPerson(personId);
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
    
    public NKS_NorgNavUnitService.WorkAllocationResponse getWorkAllocation(Id personId, String themeGroupCode, String themeCode, String themeSubThemeCode, String taskType) {
        Person__c person = getPerson(personId);
        return getWorkAllocation(person, themeGroupCode, themeCode, themeSubThemeCode, taskType);
    }

    public NKS_NorgNavUnitService.WorkAllocationResponse getWorkAllocation(Person__c person, String themeGroupCode, String themeCode, String themeSubThemeCode, String taskType) {
        NKS_NavUnitWorkAllocationInput allocationInput = new NKS_NavUnitWorkAllocationInput();
        allocationInput.skjermet = getIsShielded(person);
        allocationInput.geografiskOmraade = getLocation(person);
        allocationInput.diskresjonskode = getDiscretionaryCode(person);
        allocationInput.temagruppe = themeGroupCode;
        allocationInput.tema = themeCode;
        allocationInput.behandlingstema = themeSubThemeCode;
        allocationInput.oppgavetype = taskType;
        
        return service.getNavUnitWorkAllocation(allocationInput);
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
     * * Location is returned in the following order if the field(s) have a value:
     * * INT_GTDistrictNumber__c
     * * INT_GTMunicipalityNumber__c
     * * INT_AddressDistrictNumber_c
     * * INT_AddressMunicipalityNumber__c
     * * INT_MunicipalityNumber__c + INT_RegionNumber__c
     * * INT_MunicipalityNumber__c
     * * INT_TemporaryMunicipalityNumber__c
     * * NULL if none above
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person [Must have the fields INT_MunicipalityNumber__c and INT_DistrictNumber__c]
     * @return String [The location string to use. A string of four or six numbers]
     */
    @TestVisible private String getLocation(Person__c person) {
        return String.isNotBlank(person.INT_DistrictNumber__c) ? person.INT_DistrictNumber__c : person.INT_MunicipalityNumber__c;
    }

    private Person__c getPerson(Id personId) {
        return [SELECT Id,
        INT_Confidential__c,
        INT_DistrictNumber__c,
        INT_MunicipalityNumber__c,
        INT_IsNavEmployee__c
    FROM Person__c
    WHERE Id = :personId];
    }
}
