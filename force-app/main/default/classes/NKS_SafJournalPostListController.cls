/**
 * Get journal posts from SAF
 */
public with sharing class NKS_SafJournalPostListController {
    @TestVisible
    private static NKS_SafService safService;

    @AuraEnabled(cacheable=true)
    public static NKS_SafQueryResponse getJournalPosts(
        String brukerIdField,
        String objectApiName,
        String relationshipField,
        String viewedRecordId,
        NKS_SafQueryVariables queryVariables,
        NKS_SafQueryField queryField
    ) {
        NKS_SafQueryResponse queryResults;

        try {
            //Added to make safService mockable
            if (safService == null) {
                safService = new NKS_SafService();
            }

            queryVariables.brukerId = getBrukerIdFromPerson(
                getPersonId(brukerIdField, objectApiName, relationshipField, viewedRecordId)
            );

            queryResults = safService.doSafQuery(
                NKS_SafBuildQueryUtil.buildQuery(
                    'dokumentoversiktBruker',
                    queryField,
                    queryVariables
                )
            );
        } catch (Exception ex) {
            queryResults = new NKS_SafQueryResponse();
            queryResults.isSuccess = false;
            queryResults.error = new NKS_SafError();
            queryResults.error.message = ex.getMessage();
            queryResults.error.error = ex.getTypeName();
        }

        return queryResults;
    }

    @AuraEnabled(cacheable=true)
    public static List<NKS_NavCaseService.NavCaseWrapper> getNavCases(
        String brukerIdField,
        String objectApiName,
        String relationshipField,
        String viewedRecordId
    ) {
        String actorId = getPersonActorId(
            getPersonId(brukerIdField, objectApiName, relationshipField, viewedRecordId)
        );

        return NKS_NavCaseService.getNavCases(actorId);
    }

    private static Id getPersonId(
        String personIdField,
        String objectApiName,
        String relationshipField,
        String viewedRecordId
    ) {
        Id personId;

        String query = 'SELECT ' + personIdField + ' FROM ' + objectApiName + ' WHERE ';
        query += relationshipField + ' = :viewedRecordId';

        sObject returnObject = Database.query(String.escapeSingleQuotes(query))[0];

        return (Id) getFieldValue(returnObject, personIdField);
    }

    private static NKS_SafBrukerIdInput getBrukerIdFromPerson(Id personId) {
        NKS_SafBrukerIdInput brukerId = new NKS_SafBrukerIdInput();

        Person__c person = [SELECT Id, Name, INT_ActorId__c FROM Person__c WHERE Id = :personId];

        brukerId.id = person.INT_ActorId__c;
        brukerId.type = 'AKTOERID';

        return brukerId;
    }

    private static String getPersonActorId(Id personId) {
        Person__c person = [SELECT INT_ActorId__c FROM Person__c WHERE Id = :personId];
        return person.INT_ActorId__c;
    }

    private static String getFieldValue(Sobject obj, String parentRelationField) {
        List<String> relationHierarchy = parentRelationField.split('\\.');
        String fieldApiName = relationHierarchy.remove(0);

        if (relationHierarchy.isEmpty()) {
            return (String) obj.get(fieldApiName);
        } else {
            return getFieldValue(obj.getSObject(fieldApiName), String.join(relationHierarchy, '.'));
        }
    }
}
