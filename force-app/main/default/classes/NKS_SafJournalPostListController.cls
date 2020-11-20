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

    @AuraEnabled
    public static NKS_SafApexTypes.BrukerIdInput getAccountQueryVariables(String field, String parentId, String objectApiName, String relationField, String parentRelationField, String parentObjectApiName, String brukerIdType){
        NKS_SafApexTypes.BrukerIdInput brukerId = new NKS_SafApexTypes.BrukerIdInput();

        Set<String> parentRelationIds = getParentRelation(parentId, relationField, objectApiName);
        
        String query = 'SELECT ' + field + ' FROM ' + parentObjectApiName + ' WHERE ';
        query +=  parentRelationField + ' IN :parentRelationIds';
        sObject returnObject = Database.query(query)[0];
        
        brukerId.id = getFieldValue(returnObject,field);
        brukerId.type = brukerIdType.toUpperCase();

        return brukerId;
    }

    private static Set<String> getParentRelation(String parentId, String relationField, String objectApiName) {
        Set<String> parentRelationIds = new Set<String>();
        String query = 'SELECT ' + relationField + ' FROM ' + objectApiName + ' WHERE Id = :parentId';
        for(SObject sObj : Database.query(query)) {
            parentRelationIds.add(getFieldValue(sObj,relationField));
        }

        return parentRelationIds;
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
