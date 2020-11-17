@isTest
public class ChatAuthController_Test {
    
    @TestSetup
    static void makeData(){
        Case casy = (Case) UTIL_TestDataFactory.createRecord(new Case());
        UTIL_TestDataFactory.createRecord(new LiveChatTranscript(CaseId = casy.Id));
    }

    @isTest
    static void testGetChatStatus() {
        Map<String, String> chatStatuses;

        Test.startTest();
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        chatStatuses = ChatAuthController.getChatInfo(chatTranscript.Id);

        //Testing exception
        try{
            ChatAuthController.getChatInfo('FAKEID');
        }
        catch(Exception ex) {
            System.assertEquals(new AuraHandledException('Test').getTypeName(), ex.getTypeName());
        }
        Test.stopTest();

        System.assertEquals('Not Started', chatStatuses.get('AUTH_STATUS'));
    }

    @isTest
    static void testSetStatusRequested() {

        Test.startTest();
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        LiveChatVisitor visitor = [SELECT Id FROM LiveChatVisitor LIMIT 1];
        ChatAuthController.setStatusRequested(chatTranscript.Id);

        //Testing exception
        try{
            ChatAuthController.setStatusRequested(visitor.Id);
        }
        catch(Exception ex) {
            System.assertEquals(new AuraHandledException('Test').getTypeName(), ex.getTypeName());
        }
        Test.stopTest();

        LiveChatTranscript updatedTranscript = [SELECT Id, CRM_Authentication_Status__c FROM LiveChatTranscript WHERE Id =: chatTranscript.Id];

        System.assertEquals('Authentication Requested', updatedTranscript.CRM_Authentication_Status__c);
    }


    @isTest
    static void testSetStatusCompleted(){
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        
        Test.startTest(); 
        ChatAuthController.setStatusCompleted(chatTranscript.Id);
        Test.stopTest(); 

        LiveChatTranscript updatedTranscript = [SELECT Id, CRM_Authentication_Status__c FROM LiveChatTranscript WHERE Id =: chatTranscript.Id];
        System.assertEquals('Completed', updatedTranscript.CRM_Authentication_Status__c);
    }

    @isTest
    static void testGetCommunityAuthUrl() {
        String communityUrl;

        Test.startTest();
        communityUrl = ChatAuthController.getCommunityAuthUrl();
        Test.stopTest();

        System.assert(String.isNotBlank(communityUrl));
    }
}