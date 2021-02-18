@isTest
public class NKS_ChatTranscriptService_Test {
    @TestSetup
    static void makeData() {
        String botConversation = '22:15:14 - bot:\n';
        botConversation += 'Det er mange som vil snakke med oss nå. Hold chatten åpen og følg med, så svarer vi deg så snart vi kan.\n';
        botConversation += '22:15:14 - bot:\n';
        botConversation = 'Jeg setter deg over, et øyeblikk.\n';

        Case botCase = (Case) UTIL_TestDataFactory.createRecord(
            new Case(Description = botConversation)
        );

        List<LiveChatTranscript> transcripts = new List<LiveChatTranscript>();
        for (Integer i = 0; i < 10; i++) {
            transcripts.add(
                new LiveChatTranscript(
                    NKS_Journal_Entry_Created__c = true,
                    Body = 'TESTBODY',
                    CaseId = botCase.Id,
                    NKS_Journal_Entry_ID__c = UTIL_TestDataFactory.generateRandomNumberString(
                        10
                    )
                )
            );
        }
        UTIL_TestDataFactory.createRecordList(transcripts);
    }

    @isTest
    static void testStoreConversation() {
        LiveChatTranscript transcript = [
            SELECT Id, NKS_Conversation__c
            FROM LiveChatTranscript
            LIMIT 1
        ];

        StaticResource testConversation = [
            SELECT Id, Body
            FROM StaticResource
            WHERE Name = 'NKS_Chat_Conversation_Mock'
        ];
        String conversation = testConversation.Body.toString();

        Test.startTest();
        NKS_ChatTranscriptService.storeConversation(
            transcript.Id,
            conversation
        );
        Test.stopTest();

        transcript = [
            SELECT Id, NKS_Conversation__C
            FROM LiveChatTranscript
            WHERE Id = :transcript.Id
        ];

        System.assert(String.isNotBlank(transcript.NKS_Conversation__c));
    }
}
