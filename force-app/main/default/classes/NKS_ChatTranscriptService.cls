public class NKS_ChatTranscriptService extends ApiController {

    private static final String JOURNAL_API_CREDENTIAL_NAME = 'TBD';
    private static final String JOURNAL_API_PATCH_SERVICE = '/rest/journalpostapi/v1/journalpost/{journalPostId}/ferdigstill';

    private Id AsyncReqId;
    private List<LiveChatTranscript> chatTranscripts;

    public NKS_ChatTranscriptService(List<LiveChatTranscript> chatTranscripts, Id AsyncReqId) {
        this.chatTranscripts = chatTranscripts;
        this.AsyncReqId = AsyncReqId;
    }
    
    /**
    * @description: Handles updates of chat trancript records and storing error messages to async
    * request record. Async request is then updated to only contain the failing transcript ids.
    * @author Stian Ruud Schikora | 10-09-2020 
    **/
    public void updateJournalEntries() {
        List<LiveChatTranscript> completedChats = new List<LiveChatTranscript>();
        List<String> errorSet = new List<String>();
        String errorMessage;

        for (LiveChatTranscript chatTrans : chatTranscripts) {
            boolean success = updateJournalEntry(chatTrans);
            if(success) {
                chatTrans.NKS_Journal_Entry_Status__c = 'Completed';
                completedChats.add(chatTrans);
            }
            else{
                errorMessage += 'Error for chat: ' + chatTrans.Id + ' \nMessage: ' + getResponse().getStatus() + ' : ' + getResponse().getBody() + '\n';
                errorSet.add(chatTrans.Id);
            }
        }

        try{
            update completedChats;
            if(String.isNotBlank(AsyncReqId) && !errorSet.isEmpty()) {
                update new AsyncRequest__c( Id = AsyncReqId, 
                                            CRM_Params__c = String.join(errorSet, ';'), 
                                            CRM_ErrorMessage__c = errorMessage, 
                                            CRM_Status__c = AsyncRequestService.STATUS_ERROR);
            }
        }
        catch(Exception ex) {
            //Handle exception
        }
    }

    /**
    * @description: Creates the journal PATCH request and send for journal completion
    * @author Stian Ruud Schikora | 10-09-2020 
    * @param chatTranscript 
    * @return boolean [Callout success]
    **/
    private boolean updateJournalEntry(LiveChatTranscript chatTranscript) {
        String servicePath = JOURNAL_API_PATCH_SERVICE.replace('{journalPostId}', chatTranscript.NKS_Journal_Entry_ID__c);
        initPatchRequest(servicePath);
        setBody(generatePatchBody(chatTranscript));
        boolean success = false;

        try{
            doCallout();
            Integer resStatusCode = getResponse().getStatusCode();
            success = resStatusCode == 200 || resStatusCode == 201;
        }
        catch(Exception ex){
            //Catch all exceptions and success will be false. Enters retry loop.
        }

        return success;
    }

    
    /**
    * @description: Generates the patch request body with null values supressed
    * @author Stian Ruud Schikora | 10-09-2020 
    * @param chatTranscript 
    * @return String 
    **/
    private String generatePatchBody(LiveChatTranscript chatTranscript) {
        String pdfDoc = EncodingUtil.base64Encode(Blob.toPdf(chatTranscript.body));
        //NKS-66 Need to convert to valid PDF/A 1-b format
        JournalEntryWrapper.DokumentVarianter pdfdocvar = new JournalEntryWrapper.Dokumentvarianter('pdf', pdfDoc, 'ARKIV');
        JournalEntryWrapper.Dokumenter doc = new JournalEntryWrapper.Dokumenter('STANDARD TITLE', null, new List<JournalEntryWrapper.Dokumentvarianter> {pdfdocvar});
        JournalEntryWrapper journalPatch = new JournalEntryWrapper();
        journalPatch.dokumenter = new List<JournalEntryWrapper.Dokumenter>{doc};

        return JSON.serialize(journalPatch, true);
    }

    private void initPatchRequest(String servicePath) {
        Map<String, String> httpHeaders = new Map<String, String>{
                                            'Content-Type' => 'application/json',
                                            'Authorization' => 'Bearer ' + CachedTokensHandler.getAccessToken()
                                        };

        initRequest('Journal_API', 'PATCH_UPDATE_JOURNAL');
        setHeaders(httpHeaders);
    }

}
