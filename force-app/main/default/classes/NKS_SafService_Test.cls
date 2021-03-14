@IsTest
private with sharing class NKS_SafService_Test {
    @isTest
    static void doSafQuerySuccess() {
        NKS_SafQueryResponse result;
        NKS_SafService service = new NKS_SafService();

        String responseBody =
            '{' +
            '  "data": {' +
            '    "dokumentoversiktBruker": {' +
            '      "journalposter": [' +
            '        {' +
            '          "journalpostId": "429111291",' +
            '          "tittel": "Innhenting av opplysninger",' +
            '          "journalposttype": "N",' +
            '          "journalstatus": "JOURNALFOERT",' +
            '          "tema": "OPP",' +
            '          "datoOpprettet": "2018-01-01T12:00:00",' +
            '          "sak": {' +
            '            "fagsakId": "4g9b0ecf"' +
            '          },' +
            '          "avsenderMottaker": {' +
            '            "navn": "Harry"' +
            '          },' +
            '          "dokumenter": [' +
            '            {' +
            '              "dokumentInfoId": "441010176",' +
            '              "tittel": "Innhenting av opplysninger",' +
            '              "dokumentvarianter": [' +
            '                {' +
            '                 "variantformat": "ARKIV",' +
            '                 "filnavn": "innhenting_asd.pdf",' +
            '                 "saksbehandlerHarTilgang": true,' +
            '                 "skjerming": "POL"' +
            '                }' +
            '              ]' +
            '            }' +
            '          ]' +
            '        }' +
            '      ]' +
            '    }' +
            '  }' +
            '}';

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'Success',
            responseBody,
            new Map<String, String>()
        );

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        NKS_SafQuery query = new NKS_SafQuery();
        query.variables = new NKS_SafQueryVariables();
        result = service.doSafQuery(query);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(
            true,
            result.isSuccess,
            'result.isSuccess is not set correctly. Expected to get a success'
        );
        System.assertNotEquals(
            null,
            result.data.dokumentoversiktBruker,
            'result.data.documentOverview is not set correctly. Expected to get a value'
        );
        System.assertEquals(
            1,
            result.data.dokumentoversiktBruker.journalposter.size(),
            'Expected 1 journalpost record'
        );
    }

    @isTest
    static void doSafQueryError() {
        NKS_SafQueryResponse result;
        NKS_SafService service = new NKS_SafService();

        String errorBody =
            '{"timestamp":"' +
            DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') +
            '","status":401,"error":"Unauthorized","message":"no valid token found in validation context","path":"/graphql"}';

        SingleRequestMock mock = new SingleRequestMock(
            401,
            'Unauthorized',
            errorBody,
            new Map<String, String>()
        );

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        NKS_SafQuery query = new NKS_SafQuery();
        query.variables = new NKS_SafQueryVariables();
        result = service.doSafQuery(query);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(
            false,
            result.isSuccess,
            'result.isSuccess is not set correctly. Expected to get a failure'
        );
        System.assertEquals(
            null,
            result.data,
            'result.data is not set correctly. Expected to get NULL'
        );
        System.assertEquals(1, result.errors.size(), 'Expected to have an error');
    }

    @isTest
    static void getSafDocumentTest() {
        NKS_SafGetDocumentResponse result;
        NKS_SafService service = new NKS_SafService();

        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/pdf');
        headers.put('Content-Disposition', 'inline');

        SingleRequestMock mock = new SingleRequestMock(200, 'Success', 'TEST_BODY_STRING', headers);

        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        result = service.getSafDocument('journalId', 'documentInfoId', 'variantFormat');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(
            true,
            result.isSuccess,
            'result.isSuccess is not set correctly. Expected to get a success'
        );
        System.assertEquals(
            'VEVTVF9CT0RZX1NUUklORw==',
            result.documentString,
            'result.documentString is not set correctly. Expected to get the string VEVTVF9CT0RZX1NUUklORw=='
        );
        System.assertEquals(
            'application/pdf',
            result.contentType,
            'result.contentType is not set correctly. Expected to get application/pdf'
        );
        System.assertEquals(
            'inline',
            result.contentDisposition,
            'result.contentDisposition is not set correctly. Expected to get inline'
        );
    }

    @isTest
    static void getSafDocumentError() {
        NKS_SafGetDocumentResponse result;
        NKS_SafService service = new NKS_SafService();

        String errorBody =
            '{"timestamp":"' +
            DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') +
            '","status":401,"error":"Unauthorized","message":"no valid token found in validation context","path":"/rest/hentdokument/journalId/documentInfoId/variantFormat"}';

        SingleRequestMock mock = new SingleRequestMock(
            401,
            'Unauthorized',
            errorBody,
            new Map<String, String>()
        );

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        result = service.getSafDocument('journalId', 'documentInfoId', 'variantFormat');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(
            false,
            result.isSuccess,
            'result.isSuccess is not set correctly. Expected to get an error'
        );
        System.assertEquals(
            null,
            result.documentString,
            'result.documentString is not set correctly. Expected to get NULL'
        );
        System.assertEquals(
            null,
            result.contentType,
            'result.contentType is not set correctly. Expected to get NULL'
        );
        System.assertEquals(
            null,
            result.contentDisposition,
            'result.contentDisposition is not set correctly. Expected to get NULL'
        );
        System.assertNotEquals(
            null,
            result.error,
            'result.error is not set corrrectly. Expected a value'
        );
        System.assertEquals(401, result.error.status, 'Expected to get 401');
        System.assertEquals('Unauthorized', result.error.error, 'Expected to get Unauthorized');
        System.assertEquals(
            true,
            String.isNotBlank(result.error.message),
            'Expected to get a value in message'
        );
        System.assertEquals(
            true,
            String.isNotBlank(result.error.path),
            'Expected to get a value in path'
        );
        System.assertNotEquals(
            null,
            result.error.timestamp,
            'Expected to get a value in timestamp'
        );
    }
}
