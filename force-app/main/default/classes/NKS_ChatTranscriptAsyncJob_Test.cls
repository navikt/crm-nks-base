@isTest
public class NKS_ChatTranscriptAsyncJob_Test {

    @TestSetup
    static void makeData(){
        LiveChatTranscript chatTrans = (LiveChatTranscript) TestDataFactory.createRecord(new LiveChatTranscript());
    }
    
    @isTest
    static void testAsyncJob(){
        LiveChatTranscript chatTrans = [SELECT Id FROM LiveChatTranscript LIMIT 1];

        
        Test.startTest();
        TestDataFactory.createRecord(new AsyncRequest__c(CRM_Params__c = String.valueOf(ChatTrans.Id), CRM_AsyncType__c = 'Chat Journal'));
        Test.stopTest();
        
    }
}
