public with sharing class NKS_InternalSurveyController {
    @AuraEnabled(cacheable=true)
    public static NKS_Survey__c getSurvey() {
        try {
            return [
                SELECT Id, Background_Color__c, NKS_Question__c, NKS_Title__c
                FROM NKS_Survey__c
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Problem getting Survey: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean hasAnswered(String surveyId) {
        try {
            return [
                SELECT Id, NKS_Answered__c, NKS_Participant__c
                FROM NKS_Survey_Response__c
                WHERE NKS_Participant__c = :UserInfo.getUserId() AND NKS_Survey__c = :surveyId
                LIMIT 1
            ]
            ?.NKS_Answered__c;
        } catch (Exception e) {
            throw new AuraHandledException('Problem getting Survey Response: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeId(String recordTypeName) {
        return Schema.SObjectType.NKS_Survey_Response__c.getRecordTypeInfosByName()
            .get(recordTypeName)
            .getRecordTypeId();
    }

    @AuraEnabled
    public static NKS_Survey_Response__c createAnsweredRecord(String surveyId) {
        try {
            NKS_Survey_Response__c answered = new NKS_Survey_Response__c(
                RecordTypeId = getRecordTypeId('Survey Answered'),
                NKS_Survey__c = surveyId,
                NKS_Participant__c = UserInfo.getUserId(),
                NKS_Answered__c = true
            );
            insert answered;

            return answered;
        } catch (Exception e) {
            throw new AuraHandledException('Problem creating Answered record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static string createResponseRecord(String surveyId, Integer rating, String comment) {
        Datetime scheduledTime = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));

        try {
            NKS_Survey_Response__c sr = new NKS_Survey_Response__c(
                CreatedById = '0051l000008rYxp',
                CreatedDate = scheduledTime,
                LastModifiedById = '0051l000008rYxp',
                LastModifiedDate = scheduledTime,
                RecordTypeId = NKS_InternalSurveyController.getRecordTypeId('Survey Response'),
                NKS_Survey__c = surveyId,
                NKS_Rating__c = rating,
                NKS_Comment__c = comment
            );
            insert sr;

            System.debug('response id: ' + sr.Id);
            return sr.Id;
        } catch (Exception e) {
            System.debug('Problem creating NKS_Survey_Response__c via API: ' + e.getMessage());
        }
        return null;
    }
}
