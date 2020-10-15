@isTest
public class NKS_ChatTranscriptService_Test {

    @TestSetup
    static void makeData(){
        List<LiveChatTranscript> transcripts = new List<LiveChatTranscript>();
        for (Integer i = 0; i < 10 ; i++) {
            transcripts.add(new LiveChatTranscript(NKS_Journal_Entry_Created__c = true, Body = 'TESTBODY', NKS_Journal_Entry_ID__c = UTIL_TestDataFactory.generateRandomNumberString(10)));
        }
        UTIL_TestDataFactory.createRecordList(transcripts);
    }

    @isTest
    static void testUpdateJournalEntriesSuccess() {
        Map<String,LiveChatTranscript> transMap = new Map<String, LiveChatTranscript>([SELECT Id, Body, NKS_Journal_Entry_Created__c, NKS_Journal_Entry_Status__c, NKS_Journal_Entry_ID__c FROM LiveChatTranscript]);
        String chatIds = String.join(new List<String>(transMap.keySet()), ';');
        AsyncRequest__c asyncReq = (AsyncRequest__c) UTIL_TestDataFactory.createRecord(new AsyncRequest__c(CRM_Params__c = chatIds));

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '', null));
        Test.startTest();
            NKS_ChatTranscriptService service = new NKS_ChatTranscriptService(transMap.values(), asyncReq.Id);
            service.updateJournalEntries();
        Test.stopTest();

        System.assertEquals(10, [SELECT count() FROM LiveChatTranscript WHERE NKS_Journal_Entry_Status__c = 'Completed']);
    }

    @isTest
    static void testUpdateJournalEntriesFailure() {
        Map<String,LiveChatTranscript> transMap = new Map<String, LiveChatTranscript>([SELECT Id, Body, NKS_Journal_Entry_Created__c, NKS_Journal_Entry_Status__c, NKS_Journal_Entry_ID__c FROM LiveChatTranscript]);
        String chatIds = String.join(new List<String>(transMap.keySet()), ';');
        AsyncRequest__c asyncReq = (AsyncRequest__c) UTIL_TestDataFactory.createRecord(new AsyncRequest__c(CRM_Params__c = chatIds));

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(500, 'Internal Server Error', '', null));
        Test.startTest();
            NKS_ChatTranscriptService service = new NKS_ChatTranscriptService(transMap.values(), asyncReq.Id);
            service.updateJournalEntries();
        Test.stopTest();

        AsyncRequest__c updatedRequest = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM AsyncRequest__c LIMIt 1];

        System.assertEquals(AsyncRequestService.STATUS_ERROR, updatedRequest.CRM_Status__c);
        System.assert(String.isNotBlank(updatedRequest.CRM_ErrorMessage__c));
    }
}
