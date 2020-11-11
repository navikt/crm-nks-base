public with sharing class NKS_SafBuildQueryUtil {
    private final static String QUERY_TEMPLATE = 'query {!queryName}({!schema}) { {!queryName}({!queryParameters}) {!queryField} }';

    public static NKS_SafApexTypes.SafQuery buildQuery(String queryType, NKS_SafApexTypes.SafQueryField queryField, NKS_SafApexTypes.SafQueryVariables queryVariables) {
        String queryString;

        switch on queryType {
            when 'dokumentoversiktBruker' {
                queryString = getDokumentoversiktBrukerQuery(queryField);
            }
            when 'dokumentoversiktFagsak' {
                queryString = getDokumentoversiktFagsakQuery(queryField);
            }
            when 'journalpost' {
                queryString = getJournalpostQuery(queryField);
            }
            when 'tilknyttedeJournalposter' {
                queryString = getTilknyttedeJournalposterQuery(queryField);
            }
            when 'dokumentoversiktJournalstatus' {
                queryString = getDokumentoversiktJournalstatusQuery(queryField);
            }
            when else {
                
            }
        }

        NKS_SafApexTypes.SafQuery queryObj = new NKS_SafApexTypes.safQuery();
        queryObj.query = queryString;
        queryObj.variables = queryVariables;

        return queryObj;
    }

    private static String getDokumentoversiktBrukerQuery(NKS_SafApexTypes.SafQueryField queryField) {
        String schema = '$brukerId: BrukerIdInput!,'
        + '$fraDato: Date, '
        + '$tilDato: Date, '
        + '$tema: [Tema], '
        + '$journalposttyper: [Journalposttyper], '
        + '$journalstatuser: [Journalstatuser], '
        + '$foerste: Int!, '
        + '$etter: String';
        
        String queryParameters = 'brukerId: $brukerId, '
        +'fraDato: $fraDato, '
        +'tilDato: $tilDato, '
        +'tema: $tema, '
        +'journalposttyper: $journalposttyper, '
        +'journalstatuser: $journalstatuser, '
        +'foerste: $foerste, '
        +'etter: $etter';

        return buildQuery('dokumentoversiktBruker', schema, queryParameters, queryField);
    }

    private static String getDokumentoversiktFagsakQuery(NKS_SafApexTypes.SafQueryField queryField) {
        String schema = '$fagsakId: FagsakInput!,'
        + '$fraDato: Date,'
        + '$tema: [Tema],'
        + '$journalposttyper: [Journalposttyper],'
        + '$journalstatuser: [Journalstatuser],'
        + '$foerste: Int!,'
        + '$etter: String';
        
        String queryParameters = 'fagsakId: $fagsakId,'
        +'fraDato: $fraDato,'
        +'tilDato: $tilDato,'
        +'tema: $tema,'
        +'journalposttyper: $journalposttyper,'
        +'journalstatuser: $journalstatuser,'
        +'foerste: $foerste,'
        +'etter: $etter';

        return buildQuery('dokumentoversiktFagsak', schema, queryParameters, queryField);
    }

    private static String getJournalpostQuery(NKS_SafApexTypes.SafQueryField queryField) {
        String schema = '$journalpostId: String!';
        
        String queryParameters = 'journalpostId: $journalpostId';

        return buildQuery('journalpost', schema, queryParameters, queryField);
    }

    private static String getTilknyttedeJournalposterQuery(NKS_SafApexTypes.SafQueryField queryField) {
        String schema = '$dokumentInfoId: String!,'
        + '$tilknytning: Tilknytning';
        
        String queryParameters = 'dokumentInfoId: $dokumentInfoId,'
        +'tilknytning: $tilknytning';

        return buildQuery('tilknyttedeJournalposter', schema, queryParameters, queryField);
    }

    private static String getDokumentoversiktJournalstatusQuery(NKS_SafApexTypes.SafQueryField queryField) {
        String schema = '$journalposttype: {Journalposttype],'
        + '$journalstatus: [Journalstatus],'
        + '$tema: [Tema],'
        + '$fraDato: Date,'
        + '$foerste: Int!,'
        + '$etter: String';
        
        String queryParameters = 'journalposttype: $journalposttype,'
        +'journalstatus: $journalstatus,'
        +'tema: $tema,'
        +'fraDato: $fraDato,'
        +'foerste: $foerste,'
        +'etter: $etter';

        return buildQuery('dokumentoversiktJournalstatus', schema, queryParameters, queryField);
    }

    private static String buildQuery(String queryName, String schema, String queryParameters, NKS_SafApexTypes.SafQueryField queryField) {
        String query = QUERY_TEMPLATE;
        query = query.replace('{!queryName}',queryName);
        query = query.replace('{!schema}',schema);
        query = query.replace('{!queryParameters}',queryParameters);
        query = query.replace('{!queryField}',queryField.toString());
        
        return query;
    }
}
