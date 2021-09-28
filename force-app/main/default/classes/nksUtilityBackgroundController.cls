public with sharing class nksUtilityBackgroundController {
    @AuraEnabled
    public static string getTabName(String recordId) {
        try {
            String tabname;
            SObjectType objectName = Id.valueOf(recordId).getSobjectType();

            if (objectName == Schema.LiveChatTranscript.getSObjectType()) {
                tabname = [
                        SELECT Name, LiveChatButton.DeveloperName, LiveChatButton.MasterLabel
                        FROM LiveChatTranscript
                        WHERE Id = :recordId
                    ]
                    ?.LiveChatButton
                    ?.MasterLabel.replace('_', ' ');
            } else if (objectName == Schema.Case.getSObjectType()) {
                Case c = [SELECT NKS_Puzzel_Queue_Name__c, Id, Origin FROM Case WHERE Id = :recordId LIMIT 1];
                if (c.Origin == 'Phone') {
                    tabname = c.NKS_Puzzel_Queue_Name__c;
                }
            }
            //if c.Origin = web / nav.no
            /*else if(objectName == Schema.Case.getSObjectType()) {
                tabname = [SELECT Name, LiveChatButton.DeveloperName, CaseId FROM LiveChatTranscript WHERE CaseId =: recordId]?.LiveChatButton?.DeveloperName.replace('_',' ');
                //TODO: Finn ut hva case tab name skal være med en chat case
            }*/
            return tabname;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string getOnlineId() {
        String statusId;
        UserAppInfo userAppInfo = [
            SELECT Id, AppDefinitionId
            FROM UserAppInfo
            WHERE UserId = :UserInfo.getUserId()
            LIMIT 1
        ];
        AppDefinition appDefinition = [
            SELECT DurableId, Label
            FROM AppDefinition
            WHERE DurableId = :userAppInfo.AppDefinitionId
            LIMIT 1
        ];

        if (appDefinition.Label.equalsIgnoreCase('NAV Kontaktsenter')) {
            statusId = String.valueOf(
                [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available_for_Chat']
                ?.Id
            );
        } else if (appDefinition.Label.equalsIgnoreCase('NKS STO')) {
            statusId = String.valueOf([SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Skriv_til_oss']?.Id);
        }
        return statusId.substring(0, 15);
    }
}
