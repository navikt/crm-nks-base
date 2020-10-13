public without sharing class ChatAuthController {
    
    @AuraEnabled
    public static void setStatus(Id chatTranscriptId, String status) {
        try {
            LiveChatTranscript lct = new LiveChatTranscript(Id = chatTranscriptId);
            lct.CRM_Authentication_Status__c = status;
            if (status == 'Completed') {
                lct.AccountId = getPersonAccountId();
                lct.ContactId = getPersonContactId(); 
            }
            update lct;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getTypeName() + ' : ' + 'Failed to update authentication status');
        }

    }

    /**
    * @description: Returns the community url used for chat authentication
    * @author Stian Ruud Schikora | 10-01-2020 
    * @return string 
    **/
    @AuraEnabled
    public static string getCommunityAuthUrl(){
        List<Network> community = [SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = 'nks'];
        String communityUrl = community.isEmpty() ? '' : Network.getLoginUrl(community[0].Id);
        communityUrl = communityUrl.removeEnd(communityUrl.substringAfterLast('/'));
        communityUrl += 's/identity-verified?ctid=';

        return communityUrl;
    }

    /**
    * @description: Returns the CRM_Authentication_Status__c, and status of the chat transcript
    * @author Stian Ruud Schikora | 09-04-2020 
    * @param chatTranscriptId [STRING]
    * @return chatInfo [MAP<STRING, STRING>]
    **/
    @AuraEnabled(Cacheable = true)
    public static Map<String, String> getChatInfo(String chatTranscriptId) {
        Map<String, String> chatInfo;
        try {
            LiveChatTranscript trans = [SELECT Id, CRM_Authentication_Status__c, AccountId, LiveChatButton.WindowLanguage, Status FROM LiveChatTranscript WHERE Id =: chatTranscriptId];
            chatInfo = new Map<String, String> {'AUTH_STATUS' => trans.CRM_Authentication_Status__c,
                                                'CONVERSATION_STATUS' => trans.Status,
                                                'ACCOUNTID' => trans.accountId,
                                                'CHAT_LANGUAGE' => String.isNotBlank(trans.LiveChatButton.WindowLanguage) ? trans.LiveChatButton.WindowLanguage : 'no'};
            return chatInfo;
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

    private static Id getPersonAccountId() {
        List<User> users = [SELECT Id, AccountId FROM User WHERE IsPortalEnabled = TRUE AND Id = :UserInfo.getUserId() AND AccountId != null AND Account.IsPersonAccount = TRUE];
        if (users.size() > 0) {
            return users[0].AccountId;
        } else {
            return null;
        }
        //TODO change when winter 21: return [SELECT AccountId FROM User WHERE IsPortalEnabled = TRUE AND Id = :UserInfo.getUserId() AND AccountId != null AND Account.IsPersonAccount = TRUE]?.AccountId;
    }
    private static Id getPersonContactId() {
        List<User> users = [SELECT Id, ContactId FROM User WHERE IsPortalEnabled = TRUE AND Id = :UserInfo.getUserId() AND ContactId != null AND Account.IsPersonAccount = TRUE];
        if (users.size() > 0) {
            return users[0].ContactId;
        } else {
            return null;
        }
        //TODO change when winter 21: return [SELECT ContactId FROM User WHERE IsPortalEnabled = TRUE AND Id = :UserInfo.getUserId() AND ContactId != null AND Account.IsPersonAccount = TRUE]?.ContactId;
    }

}


