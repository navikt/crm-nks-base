@isTest
public with sharing class NKS_InternalSurveyControllerTest {
    @TestSetup
    static void makeData() {
        NKS_Survey__c testSurvey = new NKS_Survey__c();
        testSurvey.NKS_Title__c = 'Test Survey';
        testSurvey.NKS_Question__c = 'How satisfied are you with the overall user experience of our product/service on a scale of 1 to 5, with 1 being extremely dissatisfied and 5 being extremely satisfied?';
        testSurvey.NKS_Start_Date__c = System.now();
        testSurvey.NKS_End_Date__c = System.now() + 7;
        insert testSurvey;

        NKS_Survey_Response__c testResponse = new NKS_Survey_Response__c();
        testResponse.NKS_Survey__c = testSurvey.Id;
        testResponse.NKS_Participant__c = UserInfo.getUserId();
        testResponse.NKS_Answered__c = false;
        testResponse.NKS_Rating__c = 5;
        testResponse.NKS_Comment__c = 'This is a test response';
        insert testResponse;
    }

    @isTest
    static void testGetSurvey() {
        Test.startTest();
        NKS_Survey__c survey = NKS_InternalSurveyController.getSurvey();
        Test.stopTest();

        System.assertEquals('Test Survey', survey.NKS_Title__c);
    }

    @isTest
    static void testHasAnswered() {
        Id surveyId = [SELECT Id FROM NKS_Survey__c LIMIT 1].Id;
        Test.startTest();
        Boolean hasAnswered = NKS_InternalSurveyController.hasAnswered(surveyId);
        Test.stopTest();

        System.assertEquals(false, hasAnswered);
    }

    @isTest
    static void testGetRecordTypeId() {
        Test.startTest();
        String recordTypeId = NKS_InternalSurveyController.getRecordTypeId('Survey Answered');
        Test.stopTest();

        System.assertNotEquals(null, recordTypeId);
    }

    @isTest
    static void testCreateAnsweredRecord() {
        Id surveyId = [SELECT Id FROM NKS_Survey__c LIMIT 1].Id;
        Test.startTest();
        String res = NKS_InternalSurveyController.createAnsweredRecord(surveyId);
        Test.stopTest();

        System.assertNotEquals(null, res);
    }

    @isTest
    static void testCreateResponseRecord() {
        Id surveyId = [SELECT Id FROM NKS_Survey__c LIMIT 1].Id;
        Test.startTest();
        try {
            String res = NKS_InternalSurveyController.createResponseRecord(surveyId, 4, 'test comment');
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName());
        }
        Test.stopTest();
    }
}
