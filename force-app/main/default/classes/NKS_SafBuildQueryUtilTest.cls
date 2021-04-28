@IsTest
private with sharing class NKS_SafBuildQueryUtilTest {
    @isTest
    static void buildQuery_dokumentoversiktBruker() {
        NKS_SafQuery result;

        NKS_SafQueryField queryField = new NKS_SafQueryField('journalPost');
        queryField.queryFields.add(new NKS_SafQueryField('name'));

        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();

        Test.startTest();
        result = NKS_SafBuildQueryUtil.buildQuery('dokumentoversiktBruker', queryField, queryVariables);
        Test.stopTest();

        System.assertEquals(true, String.isNotBlank(result.query), 'Expected a query string to be in place');
        System.assertEquals(
            true,
            result.query.startsWith('query dokumentoversiktBruker('),
            'Did not have the expected start and/or query name.'
        );
        System.assertNotEquals(null, result.variables, 'Expected the variables to be in place');
    }

    @isTest
    static void buildQuery_dokumentoversiktFagsak() {
        NKS_SafQuery result;

        NKS_SafQueryField queryField = new NKS_SafQueryField('journalPost');
        queryField.queryFields.add(new NKS_SafQueryField('name'));

        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();

        Test.startTest();
        result = NKS_SafBuildQueryUtil.buildQuery('dokumentoversiktFagsak', queryField, queryVariables);
        Test.stopTest();

        System.assertEquals(true, String.isNotBlank(result.query), 'Expected a query string to be in place');
        System.assertEquals(
            true,
            result.query.startsWith('query dokumentoversiktFagsak('),
            'Did not have the expected start and/or query name.'
        );
        System.assertNotEquals(null, result.variables, 'Expected the variables to be in place');
    }

    @isTest
    static void buildQuery_journalpost() {
        NKS_SafQuery result;

        NKS_SafQueryField queryField = new NKS_SafQueryField('journalPost');
        queryField.queryFields.add(new NKS_SafQueryField('name'));

        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();

        Test.startTest();
        result = NKS_SafBuildQueryUtil.buildQuery('journalpost', queryField, queryVariables);
        Test.stopTest();

        System.assertEquals(true, String.isNotBlank(result.query), 'Expected a query string to be in place');
        System.assertEquals(
            true,
            result.query.startsWith('query journalpost('),
            'Did not have the expected start and/or query name.'
        );
        System.assertNotEquals(null, result.variables, 'Expected the variables to be in place');
    }

    @isTest
    static void buildQuery_tilknyttedeJournalposter() {
        NKS_SafQuery result;

        NKS_SafQueryField queryField = new NKS_SafQueryField('journalPost');
        queryField.queryFields.add(new NKS_SafQueryField('name'));

        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();

        Test.startTest();
        result = NKS_SafBuildQueryUtil.buildQuery('tilknyttedeJournalposter', queryField, queryVariables);
        Test.stopTest();

        System.assertEquals(true, String.isNotBlank(result.query), 'Expected a query string to be in place');
        System.assertEquals(
            true,
            result.query.startsWith('query tilknyttedeJournalposter('),
            'Did not have the expected start and/or query name.'
        );
        System.assertNotEquals(null, result.variables, 'Expected the variables to be in place');
    }

    @isTest
    static void buildQuery_dokumentoversiktJournalstatus() {
        NKS_SafQuery result;

        NKS_SafQueryField queryField = new NKS_SafQueryField('journalPost');
        queryField.queryFields.add(new NKS_SafQueryField('name'));

        NKS_SafQueryVariables queryVariables = new NKS_SafQueryVariables();

        Test.startTest();
        result = NKS_SafBuildQueryUtil.buildQuery('dokumentoversiktJournalstatus', queryField, queryVariables);
        Test.stopTest();

        System.assertEquals(true, String.isNotBlank(result.query), 'Expected a query string to be in place');
        System.assertEquals(
            true,
            result.query.startsWith('query dokumentoversiktJournalstatus('),
            'Did not have the expected start and/or query name.'
        );
        System.assertNotEquals(null, result.variables, 'Expected the variables to be in place');
    }
}
