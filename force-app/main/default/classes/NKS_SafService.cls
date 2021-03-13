/**
 * Service class for making callouts to the SAF API
 * The output is Apex Types defined in the class NKS_SafApexTypes
 * * You should check the SAF documentation before using this class.
 */
public with sharing class NKS_SafService {
    private final String API_CONFIG_NAME = 'SAF_API';
    private final string SERVICE_AUTH_HEADER = 'saf';

    /**
     * Do a query for documents by calling the SAF api
     * @param queryObj apex type holding the query fields and parameters.
     * @return NKS_SafQueryResponse
     */
    public NKS_SafQueryResponse doSafQuery(NKS_SafQuery queryObj) {
        LoggerUtility logger = new LoggerUtility();

        if (String.isBlank(queryObj.variables.fraDato)) {
            queryObj.variables.fraDato = '2016-06-04';
        }

        //Create the result
        NKS_SafQueryResponse queryResult; //= new NKS_SafQueryResponse();
        //queryResult.isSuccess = false;

        String query = JSON.Serialize(queryObj, true);
        system.debug(query);
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'POST_SAF_QUERY');
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setBody(query);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();

        bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');

        if (statusCode == 200) {
            queryResult = (NKS_SafQueryResponse) JSON.deserialize(
                bodyString,
                NKS_SafQueryResponse.class
            ); //.documentOverview = getDokumentoversiktFromSafQueryResponse(bodyString);
            queryResult.isSuccess = true;
        } else {
            if (queryObj.variables != null) {
                queryObj.variables.brukerId = null;
                queryObj.variables.fagsakId = null;
                queryObj.variables.dokumentInfoId = null;
            }

            logger.httpError(
                'Error from NKS_SafService.doSafQuery (brukerId, fagsakId and dokumentInfoId is removed). Query: \n' +
                JSON.Serialize(queryObj, true),
                apiCtrl.getResponse(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();

            queryResult = new NKS_SafQueryResponse();
            queryResult.errors.add((NKS_SafError) JSON.deserialize(bodyString, NKS_SafError.class));
        }

        return queryResult;
    }

    /**
     * Call saf hentdokument and returns the Apex Type SafGetDocumentResponse. Containg the document information.
     */
    public NKS_SafGetDocumentResponse getSafDocument(
        String journalId,
        String documentInfoId,
        String variantFormat
    ) {
        LoggerUtility logger = new LoggerUtility();
        NKS_SafGetDocumentResponse getDocumentResponse = new NKS_SafGetDocumentResponse();
        getDocumentResponse.isSuccess = false;

        Map<String, String> params = new Map<String, String>();
        params.put('journalpostId', journalId);
        params.put('dokumentInfoId', documentInfoId);
        params.put('variantFormat', variantFormat);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_SAF_DOKUMENT', params);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = '';

        if (200 == statusCode) {
            bodyString = EncodingUtil.base64Encode(apiCtrl.getResponse().getBodyAsBlob());
            getDocumentResponse.isSuccess = true;
            getDocumentResponse.documentString = bodyString;
            getDocumentResponse.contentType = apiCtrl.getResponse().getHeader('Content-Type');
            getDocumentResponse.contentDisposition = apiCtrl.getResponse()
                .getHeader('Content-Disposition');
        } else {
            bodyString = apiCtrl.getResponse().getBody();
            logger.httpError(
                'Error from NKS_SafService.getSafDocument. Params: [ journalpostId: ' +
                journalId +
                ', documentInfoId: ' +
                documentInfoId +
                ', variantFormat: ' +
                variantFormat +
                '].',
                apiCtrl.getResponse(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );

            getDocumentResponse.error = (NKS_SafError) JSON.deserialize(
                bodyString,
                NKS_SafError.class
            );
            logger.publish();
        }

        return getDocumentResponse;
    }
}
