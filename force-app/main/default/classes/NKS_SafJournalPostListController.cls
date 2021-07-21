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

    @AuraEnabled(cacheable=true)
    public static NKS_SafGetDocumentResponse getDocument(
        String journalpostId,
        String documentId,
        String variantFormat
    ) {
        NKS_SafService service = new NKS_SafService();
        return service.getSafDocument(journalpostId, documentId, variantFormat);
    }

    private static String getQuery(Object queryVariables) {
        GraphQLFactory qlFactory = new GraphQLFactory('query', 'dokumentoversiktBruker', queryVariables)
            .addArgument('$brukerId', 'BrukerIdInput! ')
            .addArgument('$tema', '[Tema] ')
            .addArgument('$journalstatuser', '[Journalstatus] ')
            .addArgument('$fraDato', 'Date ')
            .addArgument('$tilDato', 'Date ')
            .addArgument('$foerste', 'Int!')
            .addArgument('$etter', 'String');

        GraphQLNode dokumentoversiktBruker = qlFactory.addNode('dokumentoversiktBruker')
            .addArgument('brukerId', '$brukerId ')
            .addArgument('tema', '$tema ')
            .addArgument('journalstatuser', '$journalstatuser ')
            .addArgument('fraDato', '$fraDato ')
            .addArgument('tilDato', '$tilDato ')
            .addArgument('foerste', '$foerste ')
            .addArgument('etter', '$etter ');
        dokumentoversiktBruker.addNode('sideInfo').addFields(new List<String>{ 'sluttpeker', 'finnesNesteSide' });

        GraphQLNode journalposter = dokumentoversiktBruker.addNode('journalposter');
        journalposter.addFields(
            new List<String>{
                'journalpostId',
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
        journalposter.addNode('relevanteDatoer').addFields(new List<String>{ 'dato', 'datotype' });
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
