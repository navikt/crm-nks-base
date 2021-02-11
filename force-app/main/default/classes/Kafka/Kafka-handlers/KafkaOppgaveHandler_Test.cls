@isTest
public class KafkaOppgaveHandler_Test {

    static KafkaOppgaveHandler handler = new KafkaOppgaveHandler();
    
    @TestSetup
    static void makeData(){
        UTIL_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789'));
    }

    @isTest
    static void testMessageProcessing() {
        List<KafkaMessage__c> messages = new List<KafkaMessage__c>();
        messages.add(new KafkaMessage__c(CRM_Key__c = '123456789' /* ,Mock value*/ ));

        Test.startTest();
        handler.processMessages(messages);
        Test.stopTest();

        System.assert([SELECT count() FROM NavTask__c] != 0);
    }
}
