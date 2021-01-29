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
        ApiController apiCtrl = new ApiController();

        Map<String, String> pathParams = new Map<String, String> {'actorId' => actorId};
        apiCtrl.initRequest('SAK_OG_BEHANDLING_API', 'GET_NAV_CASES', pathParams);
        apiCtrl.setBody(JSON.serialize(new FinnSakOgBehandlingskjedeListeRequest(actorId)));
        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if(statusCode == 200 || statusCode == 201) {
            List<NavCaseWrapper> responseList = (List<NavCaseWrapper>) JSON.deserialize(apiCtrl.getResponse().getBody(), List<NavCaseWrapper>.class);
            addThemeFriendlyName(responseList);
            return responseList;
        }
        else{
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error retrieving person cases \n ' + 'Status: ' + apiCtrl.getResponse().getStatus() + '\n' + 'Body: ' + apiCtrl.getResponse().getBody(), null);
            logger.peek().Payload__c = 'REQUEST: \n\n' + JSON.serializePretty(apiCtrl.getRequest().getBody());
            logger.publish();
            AuraHandledException ex = new AuraHandledException('Something crashed..');
            ex.setMessage('Something crashed');
            throw ex;
        }
    }

    private static void addThemeFriendlyName(List<NavCaseWrapper> navCases) {
        for (NavCaseWrapper navCase : navCases) {
            navCase.themeName = themeMap.containsKey(navCase.sakstema.value) ? themeMap.get(navCase.sakstema.value) : '';
        }
    }

    public class FinnSakOgBehandlingskjedeListeRequest {

        public FinnSakOgBehandlingskjedeListeRequest(String aktoerREF) {
            this.aktoerREF = aktoerREF;
        }

        private String aktoerREF;
        private List<String> sakstema; //List of tema from kodeverk used as filter
        private List<String> behandlingskjedetype;
        private Boolean kunAapneBehandlingskjeder; //Set to true if only querying open cases
        private DateTime tidspunkt; //If set returns only cases that has a close date after the defined datetime
    }

    private class NavCaseWrapper {
        public NavCaseWrapper(String theme, String caseId){
            sakstema sTheme = new sakstema();
            sTheme.value = theme;
            
            this.saksId = caseId;
            this.sakstema = sTheme;
            this.lukket = DateTime.now();
        }

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
