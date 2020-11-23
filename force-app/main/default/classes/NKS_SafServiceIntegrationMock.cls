public with sharing class NKS_SafServiceIntegrationMock {
    public class SafServiceMockException extends Exception {}

    public static HTTPResponse mockGetDocumentResponse(Integer statusCode) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(statusCode);
        
        if(200 == statusCode) {
            resp.setStatus('OK');
            resp.setBody(NKS_SafServiceDocumentStringMock.getDocumentStringMock());
            resp.setHeader('Content Type','application/pdf');
            resp.setHeader('Content Disposition','inline');
        } else if(400 == statusCode) {
            resp.setStatus('Bad Request');
            resp.setBody(getSafError(statuscode, 'Bad Request', 'Ugyldig input. JournalpostId og dokumentInfoId må være tall og variantFormat må være en gyldig kodeverk-verdi som ARKIV eller ORIGINAL.','/rest/hentdokument'));
        } else if(401 == statusCode) {
            resp.setStatus('Unauthorized');
            resp.setBody(getSafError(statuscode, 'Unauthorized', 'Vi kan ikke autorisere bruker gjennom token eller system som har gitt token er ukjent for saf.','/rest/hentdokument'));
        } else if(403 == statusCode) {
            resp.setStatus('Forbidden');
            resp.setBody(getSafError(statuscode, 'Forbidden', 'Vi kan ikke gi tilgang til dokumentet på grunn av sikkerhet eller personvern.','/rest/hentdokument'));
        } else if(404 == statusCode) {
            resp.setStatus('Not Found');
            resp.setBody(getSafError(statuscode, 'Not Found', 'Dokumentet ble ikke funnet i fagarkivet.','/rest/hentdokument'));
        } else if(503 == statusCode) {
            resp.setStatus('Service Unavailable');
            resp.setBody('Service Unavailable');
        } else {
            throw new SafServiceMockException('Missing status code');
        }
        
        return resp;
    }
    
    public static HTTPResponse mockPostQueryStringResponse(Integer statusCode) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(statusCode);
        
        if(200 == statusCode) {
            resp.setStatus('OK');
            resp.setBody(NKS_SafServiceQureyStringMock.getQueryString());
            resp.setHeader('Content Type','application/pdf');
            resp.setHeader('Content Disposition','inline');
        } else if(400 == statusCode) {
            resp.setStatus('Bad Request');
            resp.setBody(getSafError(statuscode, 'Bad Request', 'Validation error of type FieldUndefined: ....','/graphql'));
        } else if(401 == statusCode) {
            resp.setStatus('Unauthorized');
            resp.setBody(getSafError(statuscode, 'Unauthorized', 'Vi kan ikke autorisere bruker gjennom token eller system som har gitt token er ukjent for saf.','/graphql'));
        } else {
            throw new SafServiceMockException('Missing status code');
        }

        return resp;
    }
    
    private static string getSafError(Integer statusCode, String error, String message, String path) {
        NKS_SafApexTypes.SafError safError = new NKS_SafApexTypes.SafError();
        safError.timestamp = DateTime.now();
        safError.status = statusCode;
        safError.error = error;
        safError.message = message;
        safError.path = path;
        
        return JSON.serialize(safError,true);
    }

}
