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
    static void testStoreConversation() {
        LiveChatTranscript transcript = [SELECT Id, NKS_Conversation__c FROM LiveChatTranscript LIMIT 1];

        StaticResource testConversation = [SELECT Id, Body FROM StaticResource WHERE Name = 'NKS_Chat_Conversation_Mock'];
        String conversation = testConversation.Body.toString();

        Test.startTest();
        NKS_ChatTranscriptService.storeConversation(transcript.Id, conversation);
        Test.stopTest();

        transcript = [SELECT Id, NKS_Conversation__C FROM LiveChatTranscript WHERE Id =: transcript.Id];

        System.assert(String.isNotBlank(transcript.NKS_Conversation__c));
    }

}
