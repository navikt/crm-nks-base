//Service class for communication with the "sakOgBehandling" API for retrieving a NAV users open cases
public class NKS_NavCaseService {

    private static Map<String, String> themeMap {
        get{
            Map<String, String> returnMap = new Map<String, String>();
            for (Common_Code__c theme : [SELECT Id, Name, CRM_Code__c, CRM_Code_Set__c FROM Common_Code__c WHERE CRM_Code_set__c = 'Tema' ORDER BY Name]) {
                returnMap.put(theme.CRM_Code__c, theme.Name);
            }
            return returnMap;
        } private set{}
    }

    @AuraEnabled(Cacheable=true)
    public static List<NavCaseWrapper> getNavCases(String actorId) {
       return getNavCases(actorId, false);
    }

    @AuraEnabled(Cacheable=true)
    public static List<NavCaseWrapper> getNavCases(String actorId, Boolean onlyOpenCases) {
        ApiController apiCtrl = new ApiController();

        Map<String, String> pathParams = new Map<String, String> {'aktoerid' => actorId};
        apiCtrl.initRequest('SAK_OG_BEHANDLING_API', 'GET_NAV_CASES', pathParams);
        apiCtrl.addUrlParam('kunAapneBehandlingskjeder', String.valueOf(onlyOpenCases));
        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if(statusCode == 200 || statusCode == 201) {
            NavCaseResponse caseResponse = (NavCaseResponse) JSON.deserialize(apiCtrl.getResponse().getBody(), NavCaseResponse.class);
            List<NavCaseWrapper> navCases = caseResponse.sak; 
            addThemeFriendlyName(navCases);
            return navCases;
        }
        else{
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error retrieving person cases \n ' + 'Status: ' + apiCtrl.getResponse().getStatus() + '\n' + 'Body: ' + apiCtrl.getResponse().getBody(), null);
            logger.peek().Payload__c = 'REQUEST: \n\n' + JSON.serializePretty(apiCtrl.getRequest().getBody());
            logger.publish();
            AuraHandledException ex = new AuraHandledException('Error retrieving cases');
            ex.setMessage('Error retrieving cases');
            throw ex;
        }
    }

    private static void addThemeFriendlyName(List<NavCaseWrapper> navCases) {
        for (NavCaseWrapper navCase : navCases) {
            navCase.themeName = themeMap.containsKey(navCase.sakstema.value) ? themeMap.get(navCase.sakstema.value) : '';
        }
    }

    public class NavCaseResponse{
        private List<NavCaseWrapper> sak;
    }

    @testVisible
    public class NavCaseWrapper {
        @AuraEnabled public String saksId;
        @AuraEnabled public DateTime opprettet;
        @AuraEnabled public DateTime lukket;
        @AuraEnabled public String behandlingskjede;
        @AuraEnabled public sakstema sakstema;
        @AuraEnabled public String themeName;
    }

    private class sakstema {
        @AuraEnabled public String value; //Kodeverks value
        private String kodeRef; //Check return type
        private String kodeverksRef;
    }

}
