global class NKS_ChatJournalHandler extends MyTriggers {

    @testVisible
    private static final String CHAT_JOURNAL_TYPE = 'Chat Journal';
    
    global override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<String> chatIds = new List<String>();
        List<AsyncRequest__c> asyncReqs = new List<AsyncRequest__c>();


        for (LiveChatTranscript chatTrans : (List<LiveChatTranscript>) records) {
            if(hasChangedFields(new String[]{'NKS_Journal_Entry_Created__c'}, chatTrans, triggerOldMap.get(chatTrans.Id))){
                if(chatTrans.NKS_Journal_Entry_Created__c == true && chatTrans.NKS_Journal_Entry_Status__c != 'Completed'){
                    chatIds.add(chatTrans.Id);
                }

                //If list size matches the callout limit, store the ids in an async request and clear the list
                if(chatIds.size() == Limits.getLimitCallouts()) {
                    asyncReqs.add(createAsyncRequest(chatIds));
                    chatIds.clear();
                }
            }
        }

        if(!chatIds.isEmpty()) {
            asyncReqs.add(createAsyncRequest(chatIds));
        }

        insert asyncReqs;
    }

    private AsyncRequest__c createAsyncRequest(List<String> chatIds){
        return new AsyncRequest__c( CRM_Params__c = String.join(chatIds, ';'),
                                    CRM_Status__c = AsyncRequestService.STATUS_PENDING,
                                    CRM_AsyncType__c = CHAT_JOURNAL_TYPE);
    }
}
