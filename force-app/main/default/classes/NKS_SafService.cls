/**
 * Service class for making callouts to the SAF API
 * The output is Apex Types defined in the class NKS_SafApexTypes
 * * Check the SAF documentation before using this class.
 * ! Including mocks, they should be removed before pulled into master
 * TODO: Go through and check that everything is in sync with the ApiController class
 */
public with sharing class NKS_SafService extends ApiController {

    /**
     * Do a query for documents by calling the SAF api
     * TODO: Better exception handling
     * ! Not yet available in APIM
     * @param query String of the query towards SAF, check the SAF documentation for details.
     * @param queryVariables apex type holding all the possible query varaibles for a SAF query.
     */
    public NKS_SafApexTypes.SafQueryResponse doSafQuery(NKS_SafApexTypes.SafQuery queryObj) {
        //Create the result
        NKS_SafApexTypes.SafQueryResponse queryResult = new NKS_SafApexTypes.SafQueryResponse();
        queryResult.isSuccess = false;
        
		try{
            String queryString = JSON.Serialize(queryObj, true);
            getRequest().setBody(queryString);
            
            //Prepare the request
            initPostQueryRequest();
            
            // SETTING MOCK DATA
            resp = NKS_SafServiceMock.mockPostQueryStringSuccess(200);
            
            //Do the callout
            // doCallout();

            //Prepare the response
            Integer resStatusCode = getResponse().getStatusCode();
			String JSONContent = getResponse().getBody();
            
            //If success add the result and set as a success, if not add the query result error.
			if(resStatusCode == 200) {
				queryResult.documentOverview = getDokumentoversiktFromSafQueryResponse(JSONContent);
                queryResult.isSuccess = true;
                System.debug(queryResult.documentOverview);

			} else {
				queryResult.error = (NKS_SafApexTypes.SafError) JSON.deserialize(JSONContent,NKS_SafApexTypes.SafError.class);
            }
            
        } catch(Exception ex){
            throw new NKS_SafException('Failed when trying to run query towards SAF.', ex);
        }
		
		return queryResult;
	}
    
    /**
     * private method used by the method doSafQuery in this class.
     * To make things simpler we remove the data object from the response and only return the Dokumentoversikt object using the JSON Parser
     * @param JSONContent String with the content returned from the saf query
     */
    @TestVisible
	private NKS_SafApexTypes.Dokumentoversikt getDokumentoversiktFromSafQueryResponse(String JSONContent) {
		JSONParser parser = JSON.createParser(JSONContent);
        
        // Go throgh the JSON tokens to find the Dokumentoversikt object
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
	
		return (NKS_SafApexTypes.Dokumentoversikt) parser.readValueAs(NKS_SafApexTypes.Dokumentoversikt.class);
	}

	/**
    * Call saf hentdokument and returns the Apex Type SafGetDocumentResponse. Containg the document information.
    * ? Should we throw an exception if the reponse does not have one of the expected status codes
	*/
	public NKS_SafApexTypes.SafGetDocumentResponse getSafDocument(String journalId, String documentInfoId, String variantFormat) {
        NKS_SafApexTypes.SafGetDocumentResponse getDocumentResponse = new NKS_SafApexTypes.SafGetDocumentResponse();
        getDocumentResponse.isSuccess = false;
        
		try{
            //Set the path and add the paramt
            Map<String,String> params = new Map<String,String>();
            params.put('journalpostId',journalId);
            params.put('dokumentInfoId',documentInfoId);
            params.put('variantFormat',variantFormat);

            initGetDocumentRequest(params);
            
            //Prepare the returned data.
            
            // SETTING MOCK DATA
            resp = NKS_SafServiceMock.mockGetDocumentString(200);

            // doCallout();

            Integer resStatusCode = getResponse().getStatusCode();
            String body = getResponse().getBody();
            
            // If success add the document data, content type and content disposition
			if(resStatusCode == 200) {
				getDocumentResponse.isSuccess = true;
                getDocumentResponse.documentString = body;
                getDocumentResponse.contentType = getResponse().getHeader('Content Type');
                getDocumentResponse.contentDisposition = getResponse().getHeader('Content Disposition');
			} else {
                getDocumentResponse.error = (NKS_SafApexTypes.SafError) JSON.deserialize(body,NKS_SafApexTypes.SafError.class);
			}
        }
        catch(Exception ex){
			throw new NKS_SafException('Failed when trying to get document from SAF.', ex);
        }
		
		return getDocumentResponse;
	}

    /**
    * Add the correct path, content-type and authorization token for the saf POST graphQL callout
    */
	public void initPostQueryRequest() {
        initRequest('SAF_API', 'POST_SAF_QUERY');
        setAuthHeaders();
    }

    /**
    * Add the correct content-type and the users authorization token for the SAF GET hentDokument callout
    */
	private void initGetDocumentRequest(Map<String,String> params) {
        initRequest('SAF_API', 'GET_SAF_DOKUMENT',params);
        setAuthHeaders();
    }

    private void setAuthHeaders() {
        addServiceAuthHeader('saf');
        addSubscriptionKey();
    }
	
    public class NKS_SafException extends Exception {}
}
