@isTest
public class NksRecordInfoController_Test {
    @TestSetup
    static void makeData() {
        NKS_TestDataFactory.createLiveChatTranscripts(1);
    }

    @isTest
    static void getRelatedRecordTest() {
        LiveChatTranscript trans = [SELECT Id FROM LiveChatTranscript LIMIT 1];

        Test.startTest();
        trans = (LiveChatTranscript) NksRecordInfoController.getRelatedRecord(
            String.valueOf(trans.Id),
            'LiveChatVisitorId',
            'LiveChatTranscript'
        );
        Test.stopTest();

        System.assertNotEquals(null, trans.LiveChatVisitorId);
    }
}
