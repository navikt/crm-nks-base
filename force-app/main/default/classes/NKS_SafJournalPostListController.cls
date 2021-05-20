/**
 * Get journal posts from SAF
 */
public with sharing class NKS_SafJournalPostListController {
    @AuraEnabled(cacheable=true)
    public static NKS_SafQueryResponse getJournalPosts(String queryString) {
        NKS_SafQueryVariables queryVariables = (NKS_SafQueryVariables) JSON.deserialize(
            queryString,
            NKS_SafQueryVariables.class
        );
        NKS_SafService safService = new NKS_SafService();
        NKS_SafQueryResponse queryResults;
        System.debug(getQuery(queryVariables));
        NKS_SafQuery query = (NKS_SafQuery) JSON.deserialize(getQuery(queryVariables), NKS_SafQuery.class);
        try {
            queryResults = safService.doSafQuery(query);
        } catch (Exception ex) {
            queryResults = new NKS_SafQueryResponse();
            queryResults.isSuccess = false;
            queryResults.errors = new List<NKS_SafError>();
            queryResults.errors.add(new NKS_SafError());
            queryResults.errors[0].message = ex.getMessage();
            queryResults.errors[0].error = ex.getTypeName();
        }

        return queryResults;
    }

    @AuraEnabled(cacheable=true)
    public static List<NKS_NavCaseService.NavCaseWrapper> getNavCases(String actorId) {
        return NKS_NavCaseService.getNavCases(actorId);
    }

    // @AuraEnabled(cacheable=true)
    // public static Id getRecordId(
    //     String field,
    //     String objectApiName,
    //     String relationshipField,
    //     String relationshipValue
    // ) {
    //     String query =
    //         'SELECT ' +
    //         field +
    //         ' FROM ' +
    //         objectApiName +
    //         ' WHERE ' +
    //         relationshipField +
    //         ' = :relationshipValue';
    //     sObject returnObject = Database.query(String.escapeSingleQuotes(query))[0];
    //     return (Id) getFieldValue(returnObject, field);
    // }

    // @AuraEnabled(cacheable=true)
    // public static NKS_SafGetDocumentResponse getDocument(
    //     String journalpostId,
    //     String documentId,
    //     String variantFormat
    // ) {
    //     NKS_SafService service = new NKS_SafService();
    //     return service.getSafDocument(journalpostId, documentId, variantFormat);
    // }

    // private static NKS_SafBrukerIdInput getBrukerIdFromPerson(Id personId) {
    //     NKS_SafBrukerIdInput brukerId = new NKS_SafBrukerIdInput();

    //     Person__c person = [SELECT Id, Name, INT_ActorId__c FROM Person__c WHERE Id = :personId];

    //     brukerId.id = person.INT_ActorId__c;
    //     brukerId.type = 'AKTOERID';

    //     return brukerId;
    // }

    // private static String getPersonActorId(Id personId) {
    //     Person__c person = [SELECT INT_ActorId__c FROM Person__c WHERE Id = :personId];
    //     return person.INT_ActorId__c;
    // }

    // private static String getFieldValue(Sobject obj, String parentRelationField) {
    //     List<String> relationHierarchy = parentRelationField.split('\\.');
    //     String fieldApiName = relationHierarchy.remove(0);

    //     if (obj == null) {
    //         return null;
    //     } else if (relationHierarchy.isEmpty()) {
    //         return (String) obj.get(fieldApiName);
    //     } else {
    //         return getFieldValue(obj.getSObject(fieldApiName), String.join(relationHierarchy, '.'));
    //     }
    // }

    private static String getQuery(Object queryVariables) {
        GraphQLFactory qlFactory = new GraphQLFactory('query', 'journalposter', queryVariables);
        qlFactory.addArgument('$brukerId', 'brukerId!')
            .addArgument('$tema', 'tema!')
            .addArgument('$journalstatuser', 'journalstatuser!')
            .addArgument('$fraDato', 'fraDato!')
            .addArgument('$tilDato', 'tilDato!')
            .addArgument('$foerste', 'foerste!');
        GraphQLNode journalposter = qlFactory.addNode('journalposter')
            .addFields(
                new List<String>{
                    'tittel',
                    'journalposttype',
                    'journalstatus',
                    'tema',
                    'temanavn',
                    'behandlingstema',
                    'behandlingstemanavn',
                    'datoOpprettet',
                    'antallRetur',
                    'kanal',
                    'kanalnavn'
                }
            );
        journalposter.addNode('sak').addFields(new List<String>{ 'fagsakId', 'fagsaksystem', 'sakstype', 'tema' });
        journalposter.addNode('avsenderMottaker').addField('navn');
        journalposter.addNode('dokumenter')
            .addFields(new List<String>{ 'dokumentInfoId', 'tittel' })
            .addNode('dokumentvarianter')
            .addFields(
                new List<String>{ 'variantformat', 'filnavn', 'filtype', 'saksbehandlerHarTilgang', 'skjerming' }
            );

        return qlFactory.build();
    }
}
