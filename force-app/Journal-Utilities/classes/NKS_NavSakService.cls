public class NKS_NavSakService {
    
    private static Map<String, String> themeMap {
        get{
            Map<String, String> returnMap = new Map<String, String>();
            for (Common_Code__c theme : [SELECT Id, Name, CRM_Code__c, CRM_Code_Set__c FROM Common_Code__c WHERE CRM_Code_set__c = 'Tema' ORDER BY Name]) {
                returnMap.put(theme.CRM_Code__c, theme.Name);
            }
            return returnMap;
        } private set{}
    }

    @AuraEnabled(cacheable=true)
    public static List<SakWrapper> getActorCases(String actorId){
        ApiController apiCtrl = new ApiController();

        Map<String, String> queryParams = new Map<String, String> {'aktoerid' => actorId};
        apiCtrl.initRequest('SAK_API', 'GET_SAK_NAV_CASES');
        apiCtrl.setUrlParams(queryParams);
        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if(statusCode == 200 || statusCode == 201) {
            List<SakWrapper> navCases = (List<SakWrapper>) JSON.deserialize(apiCtrl.getResponse().getBody(), List<SakWrapper>.class);
            addThemeFriendlyName(navCases);
            return navCases;
        }
        else{
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error retrieving person cases from SAK \n ' + 'Status: ' + apiCtrl.getResponse().getStatus() + '\n' + 'Body: ' + apiCtrl.getResponse().getBody(), null);
            logger.peek().Payload__c = 'REQUEST: \n\n' + JSON.serializePretty(apiCtrl.getRequest().getBody());
            logger.publish();
            AuraHandledException ex = new AuraHandledException('Error retrieving cases');
            ex.setMessage('Error retrieving cases');
            throw ex;
        }
    }

    private static void addThemeFriendlyName(List<SakWrapper> navCases) {
        for (SakWrapper navCase : navCases) {
            navCase.themeName = themeMap.containsKey(navCase.tema) ? themeMap.get(navCase.tema) : '';
        }
    }

    @testVisible
    public class SakWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String orgnr;
        @AuraEnabled public String applikasjon;
        @AuraEnabled public String aktoerId;
        @AuraEnabled public DateTime opprettetTidspunkt;
        private String opprettetAv;
        @AuraEnabled public String fagsakNr;
        @AuraEnabled public String tema;
        @AuraEnabled public String themeName;
    }
}
