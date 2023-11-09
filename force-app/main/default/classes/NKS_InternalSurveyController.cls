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
                SELECT Id, NKS_Answered__c
                FROM NKS_Survey_Response__c
                WHERE User__c = :UserInfo.getUserId() AND NKS_Survey__c = :surveyId
                LIMIT 1
            ]
            ?.NKS_Answered__c;
        } catch (Exception e) {
            throw new AuraHandledException('Problem getting Survey Response: ' + e.getMessage());
        }
    }
}
