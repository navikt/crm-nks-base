@isTest
public with sharing class nksUtilityBackgroundControllerTest {
    @TestSetup
    static void makeData(){
        NKS_TestDataFactory.createLiveChatTranscripts(1);
        NKS_TestDataFactory.createPersons(1); 
        NKS_TestDataFactory.createCase('Test0'); 

    }

    @isTest
    static void nksUtilityBackgroundControllerTest() {
        LiveChatTranscript lct = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1]; 

        Test.startTest();
        String tablabelchat = (String) nksUtilityBackgroundController.getTabName(lct.Id); 
        String tablabelcase = (String) nksUtilityBackgroundController.getTabName(c.Id); 
        Test.stopTest();

        System.assertEquals(null, tablabelchat, 'Should be null because there is no chat button connected to the transcript');
        System.assertEquals(null, tablabelcase, 'Should be null because there is no chat connected to the case');
    }
}

