global class NKS_ConvNoteSharingActivation_Batch implements Database.Batchable<sObject> {
    private String query;
    global NKS_ConvNoteSharingActivation_Batch() {
        query = 'SELECT CRM_Account__c, NKS_Incorrectly_Sent__c, CRM_Henvendelse_BehandlingsId__c, CRM_Office_Restriction__c, CRM_Theme_Code__c From Conversation_Note__c WHERE NKS_Incorrectly_Sent__c=false AND CRM_Account__r.CRM_Person__c!=null';
    }

    global NKS_ConvNoteSharingActivation_Batch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Conversation_Note__c> scope) {
        Set<Id> accountIds = new Set<Id>();
        for (Conversation_Note__c note : scope) {
            accountIds.add(note.CRM_Account__c);
        }

        List<Person__c> persons = [
            SELECT INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];

        new NKS_ConversationNoteAccessService().grantAccess(scope, persons);
    }

    global void finish(Database.BatchableContext bc) {
    }
}
