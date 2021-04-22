public class NKS_NavSakService {
    private static List<String> SafCaseFields = new List<String>{
        'fagsakId',
        'sakstype',
        'datoOpprettet',
        'tema',
        'fagsaksystem'
    };

    private static Map<String, String> themeMap {
        get {
            if (themeMap == null) {
                themeMap = new Map<String, String>();
                for (Common_Code__c theme : [
                    SELECT Id, Name, CRM_Code__c, CRM_Code_Set__c
                    FROM Common_Code__c
                    WHERE CRM_Code_set__c = 'Tema'
                    ORDER BY Name
                ]) {
                    themeMap.put(theme.CRM_Code__c, theme.Name);
                }
            }
            return themeMap;
        }
        private set {
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SafCaseWrapper> getSafActorCases(String actorId) {
        ApiController apiCtrl = new ApiController();

        //BUILD GRAPH QUERY
        String graphBody = generateGraphBody(actorId);

        apiCtrl.initRequest('SAF_API', 'POST_SAF_CASE_QUERY');
        apiCtrl.addServiceAuthHeader('Saf');
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setBody(graphBody);
        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            SafApiResponse safResp = (SafApiResponse) JSON.deserialize(
                apiCtrl.getResponse().getBody(),
                SafApiResponse.class
            );
            if (safResp.errors != null && !safResp.errors.isEmpty()) {
                //Request went through but query returned errors
                handleError('Graph QL query error', apiCtrl.getResponse());
                AuraHandledException ex = new AuraHandledException('Error retrieving cases');
                ex.setMessage('Error retrieving cases');
                throw ex;
            } else {
                filterCases(safResp.data.saker);
                safResp.data.saker.sort();
                return safResp.data.saker;
            }
        } else {
            //Error handling
            handleError('Error retrieving actor cases', apiCtrl.getResponse());

            AuraHandledException ex = new AuraHandledException('Error retrieving cases');
            ex.setMessage('Error retrieving cases');
            throw ex;
        }
    }

    private static void handleError(String message, HttpResponse payload) {
        LoggerUtility logger = new LoggerUtility('Journal');
        logger.httpError(message, payload, null, CRM_ApplicationDomain.Domain.NKS);
        logger.publish();
    }

    public static String generateGraphBody(String actorId) {
        NKS_SafBrukerIdInput brukerId = new NKS_SafBrukerIdInput();
        brukerId.id = actorId;
        brukerId.type = 'AKTOERID';

        GraphQLFactory graphFactory = new GraphQLFactory(
            'query',
            'saker',
            new Map<String, Object>{ 'brukerId' => brukerId }
        );
        graphFactory.addArgument('$brukerId', 'BrukerIdInput!')
            .addNode('saker')
            .addArgument('brukerId', '$brukerId')
            .addFields(SafCaseFields);

        return graphFactory.build();
    }

    private static void addThemeFriendlyName(SafCaseWrapper navCase) {
        navCase.themeName = themeMap.containsKey(navCase.tema) ? themeMap.get(navCase.tema) : '';
    }

    private static void filterCases(List<SafCaseWrapper> navCases) {
        for (Integer i = navCases.size() - 1; i >= 0; i--) {
            if (navCases[i].sakstype.equalsIgnoreCase('GENERELL_SAK') || String.isBlank(navCases[i].fagsakId)) {
                //If the case is GENERELL_SAK or has no id, remove from result
                navCases.remove(i);
            } else {
                addThemeFriendlyName(navCases[i]);
            }
        }
    }

    public class SafApiResponse {
        public SafQueryResponse data;
        public List<Object> errors;
    }

    public class SafQueryResponse {
        @AuraEnabled
        public List<SafCaseWrapper> saker;
    }

    @testVisible
    public class SafCaseWrapper implements Comparable {
        @AuraEnabled
        public String fagsakId;
        @AuraEnabled
        public String sakstype;
        @AuraEnabled
        public DateTime datoOpprettet;
        @AuraEnabled
        public String tema;
        @AuraEnabled
        public String fagsaksystem;
        @AuraEnabled
        public String themeName;

        /**
         * @description: Comparable implementation sets newest case first in list
         * @author Stian Ruud Schikora | 03-29-2021
         * @param compareObj
         * @return Integer
         **/
        public Integer compareTo(Object compareObj) {
            SafCaseWrapper compareCase = (SafCaseWrapper) compareObj;
            Integer retValue = 0;
            if (this.datoOpprettet > compareCase.datoOpprettet) {
                retValue = -1;
            } else {
                retValue = 1;
            }

            return retValue;
        }
    }
}
