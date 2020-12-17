/**
 * @description Service class for doing callouts to NORG2 related to NAV Units
 */
public with sharing class NKS_NorgNavUnitService {
    private final string API_CONFIG_NAME = 'NORG2_UNIT_API'; //API Config name to set when using the ApiController
    private final string SERVICE_AUTH_HEADER = 'SaasToNavApiGw';

    /**
     * @description Get the unit related to the geographical location submitted
     * @author Tor Håkon Sigurdsen | 26-11-2020
     * @param location [String reference to the geographical location]
     * @return NavUnitResponse [Wrapper holding success (true|false), response from Norg2 and error message with reference to application log]
     */
    public NavUnitResponse getNavUnitFromGeographicLocation(String location) {
        return getNavUnitFromGeographicLocation(location, null, null);
    }

    /**
     * @description Get the unit related to the geographical location submitted
     * @author Tor Håkon Sigurdsen | 26-11-2020
     * @param location [NKS_NavUnitWorkAllocationInput: ApexType with params]
     * @param discretionCode [Discretion codes on cases a unit can process]
     * @param shielded [If the unit should process cases for a shielded NAV Employee]
     * @return NavUnitResponse [Wrapper holding success (true|false), response from Norg2 and error message with reference to application log]
     */
    public NavUnitResponse getNavUnitFromGeographicLocation(String location, String discretionCode, Boolean screened) {
        NavUnitResponse resp = new NavUnitResponse();
        
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('geografiskOmraade',location);

        Map<String,String> urlParamMap = new Map<String,String>();
        //Optional parameters
        if(String.isNotBlank(discretionCode)) { urlParamMap.put('disk', discretionCode); }
        if(null != screened) { urlParamMap.put('skjermet', String.valueOf(screened)); }

        
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_UNIT_BY_LOCATION', paramMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.setUrlParams(urlParamMap);

        apiCtrl.doCallout();
        
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();

        bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');

        if(statusCode == 200) {
            resp.success = true;
            resp.unit = (NKS_NavUnit) JSON.deserialize(bodyString, NKS_NavUnit.class);
        } else {
            String params = '[geografiskOmraade: ' + location + '| disk: ' + discretionCode + ' | skjermet: ' + screened +']';
            String errorRef = logError(apiCtrl.getResponse(), 'Error from NKS_NorgNavUnitService.getNavUnitFromGeographicLocation. Parameters: ' + params);
            resp.errorMessage = 'Kunne ikke hente enhets informasjon fra NORG2. Referanse til feil: ' + errorRef;
            
            if(statusCode == 404) {
                resp.errorMessage = 'Kunne ikke finne enhet i NORG2. Referanse til feil: ' + errorRef;
            } else if(statusCode == 500) {
                resp.errorMessage = 'Noe gikk galt ved henting av enhet fra NORG2. Referanse til feil: ' + errorRef;
            }
        }

        return resp;
    }

    public NavUnitResponse getNavUnitFromUnitNumber(String unitNumber) {
        NavUnitResponse response = new NavUnitResponse();
        NavUnitsResponse resp = getNavUnitFilteredList(null, new List<String>{unitNumber}, null);

        response.errorMessage = resp.errorMessage;
        response.success = resp.success;
        response.unit = (null != resp.units && false == resp.units.isEmpty()) ? resp.units[0] : null;

        return response;
    }

    /**
     * @Description Get a filtered list of all units
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param unitNumber
     * @return NavUnitsResponse [Wrapper holding success (true|false), response from Norg2 (List of units) and error message with reference to application log]
     */
    public NavUnitContactInformationResponse getNavUnitContactInformation(String unitNumber) {
        NavUnitContactInformationResponse resp = new NavUnitContactInformationResponse();

        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('enhetsnummer',unitNumber);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_UNIT_CONTACT_INFORMATION', paramMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.doCallout();

        String bodyString = apiCtrl.getResponse().getBody();
        
        if(String.isNotBlank(bodyString)) {
            bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        }
        
        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        if(statusCode == 200) {
            resp.success = true;

            if(true == String.isNotBlank(bodyString)) {
                resp.contactInformation = (NKS_NAvUnitContactInformation) JSON.deserialize(bodyString, NKS_NAvUnitContactInformation.class); 
            }
        } else{
            String errorRef = logError(apiCtrl.getResponse(), 'Error from NKS_NorgNavUnitService.getNavUnitFromGeographicLocation for unit: ' + unitNumber + '.');
            resp.errorMessage = 'Kunne ikke hente enhetens kontaktdetaljer fra NORG2. Referanse til feil: ' + errorRef;
            resp.success = false;

            if(statusCode == 404) {
                resp.errorMessage = 'Kunne ikke finne enhets insformasjon i NORG2. Referanse til feil: ' + errorRef;
            }
        }

        return resp;
    }

    /**
     * @Description Get a filtered list of all units
     * @author Tor Håkon Sigurdsen | 30-11-2020
     * @param unitStatuses
     * @param unitNumbers
     * @param taskProcessing
     * @return NavUnitContactInformationResponse [Wrapper holding success (true|false), response from Norg2 and error message with reference to application log]
     */
    public NavUnitsResponse getNavUnitFilteredList(List<String> unitStatuses, List<String> unitNumbers, String taskProcessingFilter) {
        NavUnitsResponse resp = new NavUnitsResponse();

        Map<String,String> urlParamMap = new Map<String,String>();
        //Optional parameters
        if(null != unitStatuses && 0 < unitStatuses.size()) { urlParamMap.put('enhetStatusListe', String.join(unitStatuses, ',')); }
        if(null != unitNumbers && 0 < unitNumbers.size()) { urlParamMap.put('enhetsnummerListe', String.join(unitNumbers,',')); }
        if(String.isNotBlank(taskProcessingFilter)) { urlParamMap.put('oppgavebehandlerFilter', taskProcessingFilter); }

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_UNITS_FILTERED_LIST');
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.setUrlParams(urlParamMap);

        apiCtrl.doCallout();

        String bodyString = apiCtrl.getResponse().getBody();
        
        if(String.isNotBlank(bodyString)) {
            bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        }

        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        if(statusCode == 200) {
            resp.success = true;

            if(true == String.isNotBlank(bodyString)) {
                resp.units = (List<NKS_NavUnit>) JSON.deserialize(bodyString, List<NKS_NavUnit>.class); 
            }
        } else{
            String errorRef = logError(apiCtrl.getResponse(), 'Error from NKS_NorgNavUnitService.getNavUnitFromGeographicLocation.');
            resp.errorMessage = 'Kunne ikke hente enhets informasjon fra NORG2. Referanse til feil: ' + errorRef;
            resp.success = false;
        }

        return resp;
    }

    /**
     * @description Get possible work allocation.
     * @author Tor Håkon Sigurdsen | 26-11-2020
     * @param allocationInput
     * @return WorkAllocationResponse [Wrapper holding success (true|false), response from Norg2 and error message with reference to application log]
     */
    public WorkAllocationResponse getNavUnitWorkAllocation(NKS_NavUnitWorkAllocationInput allocationInput) {
        WorkAllocationResponse resp = new WorkAllocationResponse();
        
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'POST_UNIT_WORK_ALLOCATION');
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type','application/json');
        apiCtrl.setBody(JSON.serialize(allocationInput, true));
        apiCtrl.doCallout();
        
        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        String bodyString = apiCtrl.getResponse().getBody();
        
        if(String.isNotBlank(bodyString)) {
            bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        }

        if(statusCode == 200) {
            resp.success = true;

            if(true == String.isNotBlank(bodyString)) {
                resp.units = (List<NKS_NavUnitWorkAllocation>) JSON.deserialize(bodyString, List<NKS_NavUnitWorkAllocation>.class); 
            }
        } else{
            String errorRef = logError(apiCtrl.getResponse(), 'Error from NKS_NorgNavUnitService.getNavUnitWorkAllocation.');
            resp.errorMessage = 'Kunne ikke hente arbeidsfordeling fra NORG2. Referanse til feil: ' + errorRef;
            resp.success = false;
        }

        return resp;
    }

    /**
     * @description Create a log entry for troubleshooting
     * @author Tor Håkon Sigurdsen | 26-11-2020
     * @param resp
     * @param message [Message to add to the log]
     * @return String [UUID of the log]
     */
    private String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message + '\n ' + 'Status: ' + resp.getStatus() + '\n' + 'Body: ' + resp.getBody(), null);
        errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
        logger.publish();

        return errorRef;
    }

    // RESPONSE WRAPPERS

    public class WorkAllocationResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public List<NKS_NavUnitWorkAllocation> units;
        @AuraEnabled public String errorMessage;

        public WorkAllocationResponse() {
            this.success = false;
            this.units = null;
            this.errorMessage = null;
        }
    }

    public class NavUnitResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public NKS_NavUnit unit;
        @AuraEnabled public String errorMessage;

        public NavUnitResponse() {
            this.success = false;
            this.unit = null;
            this.errorMessage = null;
        }
    }

    public class NavUnitsResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public List<NKS_NavUnit> units;
        @AuraEnabled public String errorMessage;

        public NavUnitsResponse() {
            this.success = false;
            this.units = null;
            this.errorMessage = null;
        }
    }

    public class NavUnitContactInformationResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public NKS_NAvUnitContactInformation contactInformation;
        @AuraEnabled public String errorMessage;

        public NavUnitContactInformationResponse() {
            this.success = false;
            this.contactInformation = null;
            this.errorMessage = null;
        }
    }
}
