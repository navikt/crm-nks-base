public class ChatAuthController {
    
    /**
    * @description: Returns the CRM_Authentication_Status__c of the chat transcript
    * @author Stian Ruud Schikora | 09-04-2020 
    * @param chatTranscriptId [STRING]
    * @return CRM_Authentication_Status__c [STRING]
    **/
    @AuraEnabled(Cacheable = true)
    public static string getAuthStatus(String chatTranscriptId) {
        try {
            return [SELECT Id, CRM_Authentication_Status__c FROM LiveChatTranscript WHERE Id =: chatTranscriptId].CRM_Authentication_Status__c;
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getTypeName() + ' : ' + 'Could not retrieve authentication status');
        }
    }

    /**
    * @description: Sets the CRM_Authentication_Status__c when the authentication process is initiated
    * @author Stian Ruud Schikora | 09-04-2020 
    * @param chatTranscriptId [STRING]
    **/
    @AuraEnabled
    public static void setStatusRequested(String chatTranscriptId) {
        try{
            LiveChatTranscript chatTranscript = new LiveChatTranscript(Id = chatTranscriptId, CRM_Authentication_Status__c = 'Authentication Requested');
            update chatTranscript;
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getTypeName() + ' : ' + 'Failed to update authentication status');
        }
    }
}
