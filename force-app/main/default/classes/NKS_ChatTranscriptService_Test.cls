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
    
}
