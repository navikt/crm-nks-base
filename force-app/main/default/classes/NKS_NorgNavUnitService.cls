/**
 * @description Service class for doing callouts to NORG2 related to NAV Units
 */
public with sharing class NKS_NorgNavUnitService {
    private final string API_CONFIG_NAME = 'APIGW'; //API Config name to set when using the ApiController
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
        final string SERVICE_NAME = 'GET_UNIT_BY_LOCATION';
        NavUnitResponse resp = new NavUnitResponse();
        
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('geografiskOmraade',location);
        
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'NORG2_GET_UNIT_BY_LOCATION', paramMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addApiGwHeader();

        //Optional paarameters
        if(String.isNotBlank(discretionCode)) { apiCtrl.addUrlParam('disk', discretionCode); }
        if(null != screened) { apiCtrl.addUrlParam('skjermet', String.valueOf(screened)); }
        
        apiCtrl.doCallout();
        
        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        if(statusCode == 200 || statusCode == 201) {
            resp.success = true;
            resp.unit = (NKS_NavUnit) JSON.deserialize(apiCtrl.getResponse().getBody(), NKS_NavUnit.class); 
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
        apiCtrl.initRequest(API_CONFIG_NAME, 'NORG2_GET_UNIT_WORK_ALLOCATION');
        apiCtrl.addApiGwHeader();
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type','application/json');
        apiCtrl.setBody(JSON.serialize(allocationInput, true));
        apiCtrl.doCallout();
        
        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        if(statusCode == 200 || statusCode == 201) {
            resp.success = true;
            resp.units = (List<NKS_NavUnitWorkAllocation>) JSON.deserialize(apiCtrl.getResponse().getBody(), List<NKS_NavUnitWorkAllocation>.class); 
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
}
