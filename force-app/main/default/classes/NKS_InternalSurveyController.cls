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
    public static Object CreateResponseRecord(Integer rating, String comment) {
        try {
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('rating', rating);
            inputs.put('comment', comment);

            Flow.Interview.NKS_Create_Survey_Response interviewInstance = new Flow.Interview.NKS_Create_Survey_Response(
                inputs
            );
            interviewInstance.start();

            return interviewInstance.getVariableValue('responseId');
            system.debug('ResponseId Output Variable: ' + interviewInstance.getVariableValue('responseId'));
            system.debug('Rating Output Variable: ' + interviewInstance.getVariableValue('rating'));
            system.debug('Comment Output Variable: ' + interviewInstance.getVariableValue('comment'));
        } catch (Exception e) {
            throw new AuraHandledException('Problem creating Response record: ' + e.getMessage());
        }
    }
}
