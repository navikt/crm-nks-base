@IsTest
private with sharing class NKS_SafService_Test {
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

    @isTest static void doSafQuery() {
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
            result = service.doSafQuery('queryString', new NKS_SafApexTypes.SafQueryVariables());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected something else than null');
        System.assertEquals(true, result.isSuccess, 'result.isSuccess is not set correctly. Expected to get a success');
        System.assertNotEquals(null, result.documentOverview, 'result.documentString is not set correctly. Expected to get the string TEST_BODY_STRING');
        System.assertEquals(1, result.documentOverview.journalposter.size(), 'Expected 1 journalpost record');
    }

    private class WebServiceMock implements HttpCalloutMock  {
        private List<HttpResponse> responseList;

        public HTTPResponse respond(HTTPRequest req) {
            System.debug(this);
            System.debug(responseList);
            return responseList.remove(0);
        }

        
        public void initiateMock() {
            Test.setMock(HttpCalloutMock.class, this);
        }

        public void addResponse(HttpResponse res) {
            if(null == responseList) {
                responseList = new List<HttpResponse>();
            }

            responseList.add(res);
        }


    }
}
