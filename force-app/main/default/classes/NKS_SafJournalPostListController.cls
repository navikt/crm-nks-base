/**
 * Get journal posts from SAF
 * !Currently hardcoded query, should be made dynamic
 */
public with sharing class NKS_SafJournalPostListController {
    @TestVisible private static NKS_SafService safService;

    @AuraEnabled(cacheable=true)
    public static NKS_SafApexTypes.SafQueryResponse getJournalposts(String userId, String userType) {
        NKS_SafApexTypes.SafQueryResponse queryResults;
        
        try {

            //Added to make safService mockable
            if(safService == null) { 
                safService = new NKS_SafService();
            }

            //Predefined query
            String query = '"query": "query dokumentoversiktBruker($brukerId: BrukerIdInput!, $foerste: Int!)'
            + '{dokumentoversiktBruker(brukerId: $brukerId, foerste:$foerste) '
            + '{journalposter {journalpostId tittel journalposttype journalstatus tema dokumenter {dokumentInfoId tittel}}}}';

            //Define query variables
            NKS_SafApexTypes.SafQueryVariables queryVariables = new NKS_SafApexTypes.SafQueryVariables();
            queryVariables.brukerId = new NKS_SafApexTypes.BrukerIdInput();
            queryVariables.brukerId.id = userId;
            queryVariables.brukerId.type = (NKS_SafApexTypes.BrukerIdType) NKS_SafApexTypes.parseEnum(userType, NKS_SafApexTypes.BrukerIdType.class);
            queryVariables.foerste = 20;

            //Get the query response
            queryResults = safService.doSafQuery(query, queryVariables);
        } catch (Exception ex) {
            queryResults = new NKS_SafApexTypes.SafQueryResponse();
            queryResults.isSuccess = false;
            queryResults.error = new NKS_SafApexTypes.SafError();
            queryResults.error.message = ex.getMessage();
            queryResults.error.error = ex.getTypeName();
        }

        return queryResults;
    }
}
