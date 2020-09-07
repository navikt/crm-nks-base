@isTest
public class ChatAuthController_Test {
    
    @TestSetup
    static void makeData(){
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript transcript = new LiveChatTranscript(LiveChatVisitorId = visitor.Id);
        insert transcript;
    }

    @isTest
    static void testGetAuthStatus() {
        String authStatus;

        Test.startTest();
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        authStatus = ChatAuthController.getAuthStatus(chatTranscript.Id);

        //Testing exception
        try{
            ChatAuthController.getAuthStatus('FAKEID');
        }
        catch(Exception ex) {
            System.assertEquals(new AuraHandledException('Test').getTypeName(), ex.getTypeName());
        }
        Test.stopTest();

        System.assertEquals('Not Started', authStatus);
    }

    @isTest
    static void testSetStatusRequested() {

        Test.startTest();
        LiveChatTranscript chatTranscript = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        ChatAuthController.setStatusRequested(chatTranscript.Id);

        //Testing exception
        try{
            ChatAuthController.setStatusRequested('FAKEID');
        }
        catch(Exception ex) {
            System.assertEquals(new AuraHandledException('Test').getTypeName(), ex.getTypeName());
        }
        Test.stopTest();

        LiveChatTranscript updatedTranscript = [SELECT Id, CRM_Authentication_Status__c FROM LiveChatTranscript WHERE Id =: chatTranscript.Id];

        System.assertEquals('Authentication Requested', updatedTranscript.CRM_Authentication_Status__c);
    }

}
