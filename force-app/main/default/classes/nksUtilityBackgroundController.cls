public with sharing class nksUtilityBackgroundController {
    @AuraEnabled
    public static string getTabName(String recordId) {
        try {
            String tabname;
            SObjectType objectName = Id.valueOf(recordId).getSobjectType();

            if (objectName == Schema.LiveChatTranscript.getSObjectType()) {
                tabname = [
                        SELECT
                            Name,
                            LiveChatButton.DeveloperName,
                            LiveChatButton.MasterLabel
                        FROM LiveChatTranscript
                        WHERE Id = :recordId
                    ]
                    ?.LiveChatButton
                    ?.MasterLabel.replace('_', ' ');
            }
            /*else if(objectName == Schema.Case.getSObjectType()) {
                tabname = [SELECT Name, LiveChatButton.DeveloperName, CaseId FROM LiveChatTranscript WHERE CaseId =: recordId]?.LiveChatButton?.DeveloperName.replace('_',' ');
                //TODO: Finn ut hva case tab name skal være 
            }*/
            return tabname;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string getOnlineId() {
        String statusId = String.valueOf(
            [
                SELECT Id
                FROM ServicePresenceStatus
                WHERE DeveloperName = 'Available_for_Chat'
            ]
            ?.Id
        );
        return statusId.substring(0, 15);
    }
}
