@isTest
public class NksRecordInfoController_Test {

    @TestSetup
    static void makeData(){
        LiveChatVisitor vis = new LiveChatVisitor();
        insert vis;

        LiveChatTranscript trans = new LiveChatTranscript(LiveChatVisitorId = vis.Id);
        insert trans;
    }


    @isTest
    static void getRelatedRecordTest() {
        LiveChatTranscript trans = [SELECT Id FROM LiveChatTranscript LIMIT 1];

        Test.startTest();
        trans = (LiveChatTranscript) NksRecordInfoController.getRelatedRecord(String.valueOf(trans.Id), 'LiveChatVisitorId', 'LiveChatTranscript');
        Test.stopTest();

        System.assertNotEquals(null, trans.LiveChatVisitorId);
    }

}
