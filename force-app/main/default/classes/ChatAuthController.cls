public without sharing class ChatAuthController {
    @AuraEnabled
    public static void setStatus(Id chatTranscriptId, String status) {
        List<SObject> recordsToUpdate = new List<SObject>();

        try {
            LiveChatTranscript lct = getChatTranscript(chatTranscriptId);
            lct.CRM_Authentication_Status__c = status;
            recordsToUpdate.add(lct);

            if (status == 'Completed') {
                Id accountId = getPersonAccountId();
                Id contactId = getPersonContactId();
                lct.AccountId = accountId;
                lct.ContactId = contactId;
                lct.NKS_Authentication_Timestamp__c = DateTime.now();

                if (String.isNotBlank(lct.CaseId)) {
                    Case casy = new Case(
                        Id = lct.CaseId,
                        AccountId = accountId,
                        ContactId = contactId
                    );
                    recordsToUpdate.add(casy);
                }
            }
            update recordsToUpdate;
        } catch (Exception ex) {
            throw new AuraHandledException(
                ex.getTypeName() +
                ' : ' +
                'Failed to update authentication status'
            );
        }
    }

    private static LiveChatTranscript getChatTranscript(Id chatTranscriptId) {
        return [
            SELECT Id, CaseId
            FROM LiveChatTranscript
            WHERE Id = :chatTranscriptId
        ];
    }

    /**
     * @description: Returns the community url used for chat authentication
     * @author Stian Ruud Schikora | 10-01-2020
     * @return string
     **/
    @AuraEnabled
    public static string getCommunityAuthUrl() {
        List<Network> community = [
            SELECT Id, Name, UrlPathPrefix
            FROM Network
            WHERE Name = 'nks'
        ];
        String communityUrl = community.isEmpty()
            ? ''
            : Network.getLoginUrl(community[0].Id);
        communityUrl = communityUrl.removeEnd(
            communityUrl.substringAfterLast('/')
        );
        communityUrl += 's/identity-verified?ctid=';

        return communityUrl;
    }

    /**
     * @description: Returns the CRM_Authentication_Status__c, and status of the chat transcript
     * @author Stian Ruud Schikora | 09-04-2020
     * @param chatTranscriptId [STRING]
     * @return chatInfo [MAP<STRING, STRING>]
     **/
    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getChatInfo(String chatTranscriptId) {
        Map<String, String> chatInfo;
        try {
            LiveChatTranscript trans = [
                SELECT
                    Id,
                    CRM_Authentication_Status__c,
                    AccountId,
                    Account.CRM_Person__c,
                    CaseId,
                    LiveChatButton.WindowLanguage,
                    Status
                FROM LiveChatTranscript
                WHERE Id = :chatTranscriptId
            ];
            chatInfo = new Map<String, String>{
                'AUTH_STATUS' => trans.CRM_Authentication_Status__c,
                'CONVERSATION_STATUS' => trans.Status,
                'ACCOUNTID' => trans.accountId,
                'CASEID' => trans.CaseId,
                'PERSONID' => trans.Account.CRM_Person__c,
                'CHAT_LANGUAGE' => String.isNotBlank(
                        trans.LiveChatButton.WindowLanguage
                    )
                    ? trans.LiveChatButton.WindowLanguage
                    : 'no'
            };
            return chatInfo;
        } catch (Exception ex) {
            throw new AuraHandledException(
                ex.getTypeName() +
                ' : ' +
                'Could not retrieve authentication status'
            );
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
        return [
            SELECT AccountId
            FROM User
            WHERE
                IsPortalEnabled = TRUE
                AND Id = :UserInfo.getUserId()
                AND AccountId != NULL
                AND Account.IsPersonAccount = TRUE
        ]
        ?.AccountId;
    }
    private static Id getPersonContactId() {
        return [
            SELECT ContactId
            FROM User
            WHERE
                IsPortalEnabled = TRUE
                AND Id = :UserInfo.getUserId()
                AND ContactId != NULL
                AND Account.IsPersonAccount = TRUE
        ]
        ?.ContactId;
    }
}
