/**
 * Get journal posts from SAF
 * !Method receives strings not apex types
 */
public with sharing class NKS_SafJournalPostListController {
    @TestVisible private static NKS_SafService safService;

    @AuraEnabled
    public static NKS_SafApexTypes.SafQueryResponse getJournalpostsUser(String queryVariablesString, String queryFieldString) {
        NKS_SafApexTypes.SafQueryResponse queryResults;

        try {
            //Added to make safService mockable
            if(safService == null) { 
                safService = new NKS_SafService();
            }

            NKS_SafApexTypes.SafQueryVariables queryVariables = (NKS_SafApexTypes.SafQueryVariables) JSON.deserialize(queryVariablesString, NKS_SafApexTypes.SafQueryVariables.class);
            NKS_SafApexTypes.SafQueryField queryField = (NKS_SafApexTypes.SafQueryField) JSON.deserialize(queryFieldString, NKS_SafApexTypes.SafQueryField.class);
            
            queryResults = safService.doSafQuery(NKS_SafBuildQueryUtil.buildQuery('dokumentoversiktBruker', queryField, queryVariables));
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
