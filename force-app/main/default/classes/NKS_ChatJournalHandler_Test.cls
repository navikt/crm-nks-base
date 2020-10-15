@isTest
public class NKS_ChatJournalHandler_Test {

    @TestSetup
    static void makeData(){
        UTIL_TestDataFactory.createRecordList(new LiveChatTranscript(), 10);
    }

    @isTest
    static void testCreateAsyncRequest() {
        Set<String> chatIds = new Set<String>();
        List<LiveChatTranscript> transcripts = [SELECT Id, NKS_Journal_Entry_Created__c, NKS_Journal_Entry_Status__c FROM LiveChatTranscript];

        for (LiveChatTranscript trans : transcripts) {
            trans.NKS_Journal_Entry_Created__c = true;
            chatIds.add(trans.Id);
        }

        Test.startTest();
        update transcripts;
        Test.stopTest();

        AsyncRequest__c asyncReq = [SELECT Id, CRM_Params__c FROM AsyncRequest__c WHERE CRM_Status__c =: AsyncRequestService.STATUS_PENDING AND CRM_AsyncType__c =: NKS_ChatJournalHandler.CHAT_JOURNAL_TYPE LIMIT 1];
        Set<String> crmParams = new Set<String> (asyncReq.CRM_Params__c.split(';'));

        System.assertEquals(chatIds, crmParams);
    }
}
