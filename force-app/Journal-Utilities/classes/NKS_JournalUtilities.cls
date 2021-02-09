//Utility class used to allow flow to retrieve the AD token from the session cache
public class NKS_JournalUtilities {

    @InvocableMethod(label = 'Journal Utility Request' description = 'Post journal entry or generate compliant document' category = 'Journal')
    public static List<UtilityResponse> handleRequest(List<utilityRequest> request) {
        List<UtilityResponse> returnList = new List<UtilityResponse>();
        
        switch on (request[0].requestType){
            when 'GENERATE_DOCUMENT' {
                returnList.add(generateDocument(request[0].documentString));
            }
            when 'BASE_64_ENCODE' {
                String document = EncodingUtil.base64Encode(Blob.valueOf(request[0].documentString));
                returnList.add(new UtilityResponse(true, document, null, null, null));
            }
            when 'POST_JOURNAL' {
                returnList.add(postJournal(request[0].journalRequest, request[0].referenceId));
            }
        }

        return returnList;
    }

    /**
    * @description: Performs a callout to dokarkiv API to post a journal entry
    * Returns the journalpostId in the utilityResponse upon a successful callout
    * @author Stian Ruud Schikora | 11-24-2020 
    * @param journalRequest 
    * @return UtilityResponse 
    **/
    public static UtilityResponse postJournal(NKS_JournalEntryWrapper journalRequest, Id referenceId) {
        ApiController apiCtrl = new ApiController();
        UtilityResponse resp = new UtilityResponse();

        Map<String, String> httpHeaders = new Map<String, String>{'Content-Type' => 'application/json'};

        apiCtrl.initRequest('Journal_API', 'POST_CREATE_JOURNAL');
        apiCtrl.addServiceAuthHeader('Dokarkiv');
        apiCtrl.addUrlParam('forsoekFerdigstill', 'true');
        apiCtrl.setBody(JSON.serialize(journalRequest, true));
        apiCtrl.setHeaders(httpHeaders);

        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if(statusCode == 200 || statusCode == 201) {
            resp.success = true;
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(apiCtrl.getResponse().getBody()); 
            resp.journalpostId = (String) responseMap.get('journalpostId');
            Boolean journalCompleted = (Boolean) responseMap.get('journalpostferdigstilt');
            resp.journalPostStatus = journalCompleted ? 'Completed' : 'In Progress';
        }
        else{
            resp.success = false;
            //Creates a log entry for troubleshooting
            LoggerUtility logger = new LoggerUtility();
            SObject objectRef = String.isNotBlank(referenceId) ? referenceId.getSobjectType().newSObject(referenceId) : null;
            logger.error('Error posting journal entry \n ' + 'Status: ' + apiCtrl.getResponse().getStatus() + '\n' + 'Body: ' + apiCtrl.getResponse().getBody(), objectRef);
            String errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
            logger.publish();
            resp.errorMessage = errorRef;
        }

        return resp;
    }

    /**
    * @description: Base 64 encode an input string, used for generating valid document for journal API
    * @author Stian Ruud Schikora | 09-17-2020 
    * @param stringToEncode [STRING]
    * @return String 
    **/
    public static UtilityResponse generateDocument(String documentString) {
        String document = EncodingUtil.base64Encode(blob.toPdf(documentString));

        return new UtilityResponse(true, document, null, null, null);
    }

    public class utilityRequest{

        public utilityRequest(){
            this.requestType = null;
            this.documentString = null;
            this.journalRequest = null;
        }

        public utilityRequest(String requestType, String documentString, NKS_JournalEntryWrapper journalRequest){
            this.requestType = requestType;
            this.documentString = documentString;
            this.journalRequest = journalRequest;
        }

        @invocableVariable(label = 'Type of Apex action to perform (Valid actions are: GENERATE_DOCUMENT, BASE_64_ENCODE and POST_JOURNAL)' required = true)
        public String requestType;

        @invocableVariable
        public String documentString;

        @invocableVariable(label= 'Reference to salesforce record to be stored on journal entry')
        public Id referenceId;

        @invocableVariable
        public NKS_JournalEntryWrapper journalRequest;
    }

    public class UtilityResponse{
        
        @invocableVariable public Boolean success;
        @invocableVariable public String documentString;
        @invocableVariable public String journalpostId;
        @invocableVariable public String journalPostStatus;
        @invocableVariable public String errorMessage;

        public UtilityResponse() {
            this.success = false;
            this.documentString = null;
            this.journalpostId = null;
            this.journalPostStatus = null;
            this.errorMessage = null;
        }

        public UtilityResponse(Boolean success, String documentString, String journalpostId, String errorMessage, String journalPostStatus){
            this.success = success;
            this.documentString = documentString;
            this.journalpostId = journalpostId;
            this.journalPostStatus = journalPostStatus;
            this.errorMessage = errorMessage;
        }
    }
    
}
