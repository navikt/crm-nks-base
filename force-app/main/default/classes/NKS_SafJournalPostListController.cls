/**
 * Get journal posts from SAF
 * !Method receives strings not apex types
 */
public with sharing class NKS_SafJournalPostListController {
    @TestVisible private static NKS_SafService safService;

    @AuraEnabled
    public static NKS_SafQueryResponse getJournalpostsUser(NKS_SafQueryVariables queryVariables, NKS_SafQueryField queryField) {
        NKS_SafQueryResponse queryResults;

        try {
            //Added to make safService mockable
            if(safService == null) { 
                safService = new NKS_SafService();
            }

            // NKS_SafQueryVariables queryVariables = (NKS_SafApexTypes.SafQueryVariables) JSON.deserialize(queryVariablesString, NKS_SafApexTypes.SafQueryVariables.class);
            // NKS_SafQueryField queryField = (NKS_SafApexTypes.SafQueryField) JSON.deserialize(queryFieldString, NKS_SafApexTypes.SafQueryField.class);
            
            queryResults = safService.doSafQuery(NKS_SafBuildQueryUtil.buildQuery('dokumentoversiktBruker', queryField, queryVariables));
        } catch (Exception ex) {
            queryResults = new NKS_SafQueryResponse();
            queryResults.isSuccess = false;
            queryResults.error = new NKS_SafError();
            queryResults.error.message = ex.getMessage();
            queryResults.error.error = ex.getTypeName();
        }

        return queryResults;
    }


    @AuraEnabled
    public static NKS_SafBrukerIdInput getAccountQueryVariables(String brukerIdField, String objectApiName, String relationshipField, String viewedRecordId, String brukerIdType){
        NKS_SafBrukerIdInput brukerIdInput = new NKS_SafBrukerIdInput();

        String query = 'SELECT ' + brukerIdField + ' FROM ' + objectApiName + ' WHERE ';
        query +=  relationshipField + ' = :viewedRecordId';

        sObject returnObject = Database.query(query)[0];
        
        brukerIdInput.id = getFieldValue(returnObject,brukerIdField);
        brukerIdInput.type = brukerIdType.toUpperCase();

        return brukerIdInput;
    }

    private static String getFieldValue(Sobject obj, String parentRelationField) {
        List<String> relationHierarchy = parentRelationField.split('\\.');
        String fieldApiName = relationHierarchy.remove(0);

        if(relationHierarchy.isEmpty()) {
            return (String) obj.get(fieldApiName);
        } else {
            return getFieldValue(obj.getSObject(fieldApiName),String.join(relationHierarchy, '.'));
        }
    }

}
