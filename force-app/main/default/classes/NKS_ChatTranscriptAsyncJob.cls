public without sharing class NKS_ChatTranscriptAsyncJob extends AsyncJob {
    
    public override void execute(AsyncRequest__c ar) {
        //Async requests are created via trigger to ensure numbers of records handled per job conforms to governor limits
        Set<String> chatIds = new Set<String> (ar.CRM_Params__c.split(';'));
        List<LiveChatTranscript> chatsToHandle = [SELECT Id, Body, NKS_Journal_Entry_ID__c, NKS_Journal_Entry_Status__c FROM LiveChatTranscript WHERE Id IN: chatIds];

        new NKS_ChatTranscriptService(chatsToHandle, ar.Id).updateJournalEntries();
    }

    
}
