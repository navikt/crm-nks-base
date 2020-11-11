@IsTest
private with sharing class NKS_SafService_Test {

    @isTest static void doSafQuery_Success() {
        NKS_SafApexTypes.SafQueryResponse result;
        NKS_SafService service = new NKS_SafService();

        String responseBody = '{'
        +'  "data": {'
        +'    "dokumentoversiktBruker": {'
        +'      "journalposter": ['
        +'        {'
        +'          "journalpostId": "429111291",'
        +'          "tittel": "Innhenting av opplysninger",'
        +'          "journalposttype": "N",'
        +'          "journalstatus": "JOURNALFOERT",'
        +'          "tema": "OPP",'
        +'          "datoOpprettet": "2018-01-01T12:00:00",'
        +'          "sak": {'
        +'            "fagsakId": "4g9b0ecf"'
        +'          },'
        +'          "avsenderMottaker": {'
        +'            "navn": "Harry"'
        +'          },'
        +'          "dokumenter": ['
        +'            {'
        +'              "dokumentInfoId": "441010176",'
        +'              "tittel": "Innhenting av opplysninger",'
        +'              "dokumentvarianter": ['
        +'                {'
        +'                 "variantformat": "ARKIV",'
        +'                 "filnavn": "innhenting_asd.pdf",'
        +'                 "saksbehandlerHarTilgang": true,'
        +'                 "skjerming": "POL"'
        +'                }'
        +'              ]'
        +'            }'
        +'          ]'
        +'        }'
        +'      ]'
        +'    }'
        +'  }'
        +'}';
        
        SingleRequestMock mock = new SingleRequestMock(200,'Success',responseBody, new Map<String, String>());

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            result = service.doSafQuery(new NKS_SafApexTypes.SafQuery());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(true, result.isSuccess, 'result.isSuccess is not set correctly. Expected to get a success');
        System.assertNotEquals(null, result.documentOverview, 'result.documentOverview is not set correctly. Expected to get a value');
        System.assertEquals(1, result.documentOverview.journalposter.size(), 'Expected 1 journalpost record');
    }

    @isTest static void doSafQuery_Error() {
        NKS_SafApexTypes.SafQueryResponse result;
        NKS_SafService service = new NKS_SafService();

        String errorBody = '{"timestamp":"'+DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX')+'","status":401,"error":"Unauthorized","message":"no valid token found in validation context","path":"/graphql"}';
        
        SingleRequestMock mock = new SingleRequestMock(401,'Unauthorized',errorBody, new Map<String, String>());

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            result = service.doSafQuery(new NKS_SafApexTypes.SafQuery());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(false, result.isSuccess, 'result.isSuccess is not set correctly. Expected to get a failure');
        System.assertEquals(null, result.documentOverview, 'result.documentOverview is not set correctly. Expected to get NULL');
        System.assertNotEquals(null, result.error, 'Expected to have an error');
    }

    @isTest static void doSafQuery_Exception() {
        NKS_SafService.NKS_SafException result;
        NKS_SafService service = new NKS_SafService();
        
        // SingleRequestMock mock = new SingleRequestMock(200,'Success',null, new Map<String, String>());

        // Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            service.doSafQuery(new NKS_SafApexTypes.SafQuery());
        } catch (NKS_SafService.NKS_SafException ex) {
            result = ex;
        } catch (Exception ex) {
            System.assert(false, 'Expected a NKS_SafException');
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected to have caught a NKS_SafException');
    }

    @isTest static void getDokumentoversiktFromSafQueryResponseNotExpectedJSON() {
        NKS_SafApexTypes.Dokumentoversikt result;
        String jsonString = '{'
        +'  "data": {'
        +'   "dokumentoversikt": {'
        +'    "dokumentoversiktBruker": {'
        +'      "journalposter": ['
        +'        {'
        +'          "journalpostId": "111111111",'
        +'          "tittel": "Tittel",'
        +'          "journalposttype": "U",'
        +'          "journalstatus": "FERDIGSTILT",'
        +'          "tema": "OPP",'
        +'          "dokumenter": ['
        +'            {'
        +'              "dokumentInfoId": "22222222",'
        +'              "tittel": "Tittel"'
        +'            }'
        +'          ]'
        +'        }'
        +'      ]'
        +'    }'
        +'   }'
        +'  }'
        +'}';
        
        NKS_SafService service = new NKS_SafService();

        Test.startTest();
            result = service.getDokumentoversiktFromSafQueryResponse(jsonString);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did not expect to get NULL');
        System.assertEquals(null, result.journalposter, 'Expected to get NULL');
    }

    @isTest static void getDokumentoversiktFromSafQueryResponseExpectedJSON() {
        NKS_SafApexTypes.Dokumentoversikt result;
        String jsonString = '{'
        +'  "data": {'
        +'    "dokumentoversiktBruker": {'
        +'      "journalposter": ['
        +'        {'
        +'          "journalpostId": "111111111",'
        +'          "tittel": "Tittel",'
        +'          "journalposttype": "U",'
        +'          "journalstatus": "FERDIGSTILT",'
        +'          "tema": "OPP",'
        +'          "dokumenter": ['
        +'            {'
        +'              "dokumentInfoId": "22222222",'
        +'              "tittel": "Tittel"'
        +'            }'
        +'          ]'
        +'        }'
        +'      ]'
        +'    }'
        +'  }'
        +'}';
        
        NKS_SafService service = new NKS_SafService();

        Test.startTest();
            result = service.getDokumentoversiktFromSafQueryResponse(jsonString);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did not expect to get NULL');
        System.assertEquals(1, result.journalposter.size(), 'Expected to have one Journalpost');
        System.assertEquals('111111111', result.journalposter[0].journalpostId, 'Expected that the journalpost was mapped correctly.');
    }

    @isTest static void getSafDocumentTest() {
        NKS_SafApexTypes.SafGetDocumentResponse result;
        NKS_SafService service = new NKS_SafService();

        Map<String, String> headers = new Map<String, String>();
        headers.put('Content Type','application/pdf');
        headers.put('Content Disposition','inline');

        SingleRequestMock mock = new SingleRequestMock(200,'Success','TEST_BODY_STRING', headers);

        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            result = service.getSafDocument('journalId','documentInfoId','variantFormat');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(true, result.isSuccess, 'result.isSuccess is not set correctly. Expected to get a success');
        System.assertEquals('TEST_BODY_STRING', result.documentString, 'result.documentString is not set correctly. Expected to get the string TEST_BODY_STRING');
        System.assertEquals('application/pdf', result.contentType, 'result.contentType is not set correctly. Expected to get application/pdf');
        System.assertEquals('inline', result.contentDisposition, 'result.contentDisposition is not set correctly. Expected to get inline');
    }

    @isTest static void getSafDocument_Error() {
        NKS_SafApexTypes.SafGetDocumentResponse result;
        NKS_SafService service = new NKS_SafService();

        String errorBody = '{"timestamp":"'+DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX')+'","status":401,"error":"Unauthorized","message":"no valid token found in validation context","path":"/rest/hentdokument/journalId/documentInfoId/variantFormat"}';
        
        SingleRequestMock mock = new SingleRequestMock(401,'Unauthorized',errorBody, new Map<String, String>());

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            result = service.getSafDocument('journalId','documentInfoId','variantFormat');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(false, result.isSuccess, 'result.isSuccess is not set correctly. Expected to get an error');
        System.assertEquals(null, result.documentString, 'result.documentString is not set correctly. Expected to get NULL');
        System.assertEquals(null, result.contentType, 'result.contentType is not set correctly. Expected to get NULL');
        System.assertEquals(null, result.contentDisposition, 'result.contentDisposition is not set correctly. Expected to get NULL');
        System.assertNotEquals(null, result.error, 'result.error is not set corrrectly. Expected a value');
        System.assertEquals(401, result.error.status, 'Expected to get 401');
        System.assertEquals('Unauthorized', result.error.error, 'Expected to get Unauthorized');
        System.assertEquals(true, String.isNotBlank(result.error.message), 'Expected to get a value in message');
        System.assertEquals(true, String.isNotBlank(result.error.path), 'Expected to get a value in path');
        System.assertNotEquals(null, result.error.timestamp, 'Expected to get a value in timestamp');
    }

    @isTest static void getSafDocumentTest_Exception() {
        NKS_SafService.NKS_SafException result;
        NKS_SafService service = new NKS_SafService();

        // SingleRequestMock mock = new SingleRequestMock(401,'Unauthorized',null, null);

        // Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            service.getSafDocument('journalId','documentInfoId','variantFormat');
        } catch(NKS_SafService.NKS_SafException ex) {
            result = ex;
        } catch(Exception ex) {
            System.assert(false, 'Excpected to  have caught a NKS_SafException, not any other exceptions.');
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Excpected to  have caught a NKS_SafException');
    }
}
