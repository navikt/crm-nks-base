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
        // If no read access we cannot lookup the user.
        if(false == hasReadAccessToUser(personId)) {
            return navUnitErrorResponse(Label.NAV_Unit_Error_person_not_accessible);
        }

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
        NKS_NorgNavUnitService.NavUnitResponse resp;

        Boolean isShielded = getIsShielded(person);
        String location = getLocation(person);
        String discretionCode = getDiscretionaryCode(person);

        if(String.isBlank(location)) {
            return navUnitErrorResponse(Label.NAV_Unit_Error_person_location_missing);
        }
        
        resp = service.getNavUnitFromGeographicLocation(location, discretionCode, isShielded);

        return resp;
    }
    
    /**
     * @description Find the suggested unit to use for work allocation.
     * @author Tor Håkon Sigurdsen | 15-12-2020
     * @param personId
     * @param themeGroupCode
     * @param themeCode
     * @param themeSubThemeCode
     * @param taskType
     * @return NKS_NorgNavUnitService.WorkAllocationResponse
     */
    public NKS_NorgNavUnitService.WorkAllocationResponse getWorkAllocation(Id personId, String themeGroupCode, String themeCode, String themeSubThemeCode, String taskType) {
        Person__c person = getPerson(personId);
        return getWorkAllocation(person, themeGroupCode, themeCode, themeSubThemeCode, taskType);
    }

    /**
     * @description Find the suggested unit to use for work allocation. If no person, skip person related fields.
     * @author Tor Håkon Sigurdsen | 15-12-2020
     * @param person
     * @param themeGroupCode
     * @param themeCode
     * @param themeSubThemeCode
     * @param taskType
     * @return NKS_NorgNavUnitService.WorkAllocationResponse
     */
    public NKS_NorgNavUnitService.WorkAllocationResponse getWorkAllocation(Person__c person, String themeGroupCode, String themeCode, String themeSubThemeCode, String taskType) {
        NKS_NavUnitWorkAllocationInput allocationInput = new NKS_NavUnitWorkAllocationInput();

        //If no person due to sharing we can just skip these
        if(null != person) {
            allocationInput.skjermet = getIsShielded(person);
            allocationInput.geografiskOmraade = getLocation(person);
            allocationInput.diskresjonskode = getDiscretionaryCode(person);
        }

        //allocationInput.temagruppe = themeGroupCode; We don't use the correct theme group codes
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
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param person [Must have the fields INT_MunicipalityNumber__c and INT_DistrictNumber__c]
     * @return String [The location string to use. A string of four or six numbers]
     */
    @TestVisible private String getLocation(Person__c person) {
        return String.isNotBlank(person.INT_DistrictNumber__c) ? person.INT_DistrictNumber__c : person.INT_MunicipalityNumber__c;
    }

    /**
     * @description Get a Person__c record based on ID. If no Person found return null.
     * @author Tor Håkon Sigurdsen | 15-12-2020
     * @param personId [String]
     * @return Person__c
     */
    private Person__c getPerson(Id personId) {
        List<Person__c> personResult = [SELECT Id,
                INT_Confidential__c,
                INT_DistrictNumber__c,
                INT_MunicipalityNumber__c,
                INT_IsNavEmployee__c
            FROM Person__c
            WHERE Id = :personId];

        if(personResult.isEmpty()) {
            return null;
        }

        return personResult[0];
    }

    /**
     * @description Reusable error response. 
     * @author Tor Håkon Sigurdsen | 16-12-2020
     * @param errorMesage [String]
     * @return NKS_NorgNavUnitService.NavUnitResponse
     */
    private NKS_NorgNavUnitService.NavUnitResponse navUnitErrorResponse(String errorMesage) {
        NKS_NorgNavUnitService.NavUnitResponse resp = new NKS_NorgNavUnitService.NavUnitResponse();
        resp.success = false;
        resp.errorMessage = errorMesage;

        return resp;
    }

    /**
     * @description Reusable error response. 
     * @author Tor Håkon Sigurdsen | 16-12-2020
     * @param errorMesage [String]
     * @return NKS_NorgNavUnitService.WorkAllocationResponse
     */
    private NKS_NorgNavUnitService.WorkAllocationResponse workAllocationErrorResponse(String errorMesage) {
        NKS_NorgNavUnitService.WorkAllocationResponse resp = new NKS_NorgNavUnitService.WorkAllocationResponse();
        resp.success = false;
        resp.errorMessage = errorMesage;

        return resp;
    }

    /**
     * @description Check if we have access to view the Person. 
     * @author Tor Håkon Sigurdsen | 16-12-2020
     * @param personId [String]
     * @return Boolean
     */
    private Boolean hasReadAccessToUser(String personId) {
        UserRecordAccess access = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :personId];
        return access.HasReadAccess;
    }
}
