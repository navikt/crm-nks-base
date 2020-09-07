public class ChatAuthController {
    
    @AuraEnabled
    public static void setStatus(Id chatTranscriptId, String status) {
        try {
            LiveChatTranscript lct = new LiveChatTranscript(Id = chatTranscriptId);
            lct.CRM_Authentication_Status__c = status;
            if (status == 'Completed') {
                lct.ContactId = getPersonAccountId(chatTranscriptId);
            }
            update lct;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getTypeName() + ' : ' + 'Failed to update authentication status');
        }

    }

    /**
    * @description: Returns the CRM_Authentication_Status__c, and status of the chat transcript
    * @author Stian Ruud Schikora | 09-04-2020 
    * @param chatTranscriptId [STRING]
    * @return chatStatuses [MAP<STRING, STRING>]
    **/
    @AuraEnabled(Cacheable = true)
    public static Map<String, String> getChatStatus(String chatTranscriptId) {
        Map<String, String> chatStatuses;
        try {
            LiveChatTranscript trans = [SELECT Id, CRM_Authentication_Status__c, Status FROM LiveChatTranscript WHERE Id =: chatTranscriptId];
            chatStatuses = new Map<String, String> {'AUTH_STATUS' => trans.CRM_Authentication_Status__c, 'CONVERSATION_STATUS' => trans.Status};
            return chatStatuses;
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
    public static void setStatusRequested(Id chatTranscriptId) {
        setStatus(chatTranscriptId, 'Authentication Requested');
    }

    @AuraEnabled
    public static void setStatusCompleted(Id chatTranscriptId) {
        setStatus(chatTranscriptId, 'Completed');
    }

    private static Id getPersonAccountId(Id chatTranscriptId) {
        List<User> users = [SELECT Id, Account.PersonContactId FROM User WHERE IsPortalEnabled = TRUE AND Id = :UserInfo.getUserId() AND AccountId != null AND Account.IsPersonAccount = TRUE];
        if (users.size() > 0) {
            return users[0].Account.PersonContactId;
        } else {
            return null;
        }
    }


}


