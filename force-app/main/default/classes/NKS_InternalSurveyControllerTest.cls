@isTest
public with sharing class NKS_InternalSurveyControllerTest {
    @TestSetup
    static void makeData() {
        NKS_Survey__c testSurvey = new NKS_Survey__c();
        testSurvey.NKS_Title__c = 'Test Survey';
        testSurvey.NKS_Question__c = 'How satisfied are you with the overall user experience of our product/service on a scale of 1 to 5, with 1 being extremely dissatisfied and 5 being extremely satisfied?';
        testSurvey.NKS_Start_Date__c = System.now().addDays(1);
        testSurvey.NKS_End_Date__c = System.now().addDays(7);
        insert testSurvey;

        NKS_Survey_Response__c testResponse = new NKS_Survey_Response__c();
        testResponse.NKS_Survey__c = testSurvey.Id;
        testResponse.NKS_Participant__c = UserInfo.getUserId();
        testResponse.NKS_Rating__c = 5;
        testResponse.NKS_Comment__c = 'This is a test response';
        insert testResponse;

        Profile prof = [SELECT Id FROM Profile WHERE name = 'System Administrator'];

        User user = new User(
            FirstName = 'SFDX',
            LastName = 'Integrasjonsbruker',
            Email = 'SFDX_Iintegrasjonsbruker@nav.apextest',
            Username = 'SFDX_Iintegrasjonsbruker@nav.apextest',
            Alias = 'Geirern',
            LanguageLocaleKey = 'no',
            LocaleSidKey = 'no_NO',
            TimeZoneSidKey = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            ProfileId = prof.Id,
            Department = '1'
        );
        insert user;
    }

    @isTest
    static void testGetSurvey() {
        NKS_Survey__c survey;

        Test.startTest();
        try {
            survey = NKS_InternalSurveyController.getSurvey();
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName());
        }
        Test.stopTest();
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
        NKS_InternalSurveyController.createSurveyResponse(surveyId, 4, 'test comment', false);
        Test.stopTest();
        List<FlowInterview> interview = [SELECT Id, PauseLabel FROM FlowInterview LIMIT 1];
        Assert.areEqual(1, interview.size(), 'IDFK');
    }

    @isTest
    static void testCreateResponseRecord() {
        Id surveyId = [SELECT Id FROM NKS_Survey__c LIMIT 1].Id;
        List<NKS_InternalSurveyController.SurveyResponseInput> inputs = new List<NKS_InternalSurveyController.SurveyResponseInput>();
        NKS_InternalSurveyController.SurveyResponseInput inp1 = new NKS_InternalSurveyController.SurveyResponseInput();
        NKS_InternalSurveyController.SurveyResponseInput inp2 = new NKS_InternalSurveyController.SurveyResponseInput();
        NKS_InternalSurveyController.SurveyResponseInput inp3 = new NKS_InternalSurveyController.SurveyResponseInput();
        inp1.comment = 'Ehhhh';
        inp2.comment = 'Good job';
        inp3.comment = '';
        inp1.rating = 1;
        inp2.rating = 5;
        inp3.rating = 3;
        inp1.surveyId = surveyId;
        inp2.surveyId = surveyId;
        inp3.surveyId = surveyId;

        inputs.add(inp1);
        inputs.add(inp2);
        inputs.add(inp3);

        Test.startTest();
        NKS_InternalSurveyController.createResponseRecord(inputs);
        Test.stopTest();
        List<NKS_Survey_Response__c> responses = [
            SELECT Id, LastModifiedById, CreatedById
            FROM NKS_Survey_Response__c
            WHERE NKS_Survey__c = :surveyId AND RecordType.DeveloperName = 'Survey_response'
        ];
        Assert.areEqual(3, responses.size(), 'Not the correct amount of responses created');
        for (NKS_Survey_response__c response : responses) {
            Assert.areNotEqual(UserInfo.getUserId(), response.CreatedById, 'IDFK');
            Assert.areNotEqual(UserInfo.getUserId(), response.LastModifiedById, 'IDFK');
        }
    }
}
