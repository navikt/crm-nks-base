/**
 * @description
 * Controller class for NKS Custom Survey Solution
 */
public without sharing class NKS_InternalSurveyController {
    /**
     * @description Function to get Survey
     * @author Sara Mohammadi | 22-11-2023
     * @return NKS_Survey__c
     **/
    @AuraEnabled(cacheable=true)
    public static NKS_Survey__c getSurvey() {
        DateTime currentTime = System.now();
        try {
            return [
                SELECT Id, NKS_Background_Color__c, NKS_Question__c, NKS_Title__c, NKS_Start_Date__c, NKS_End_Date__c
                FROM NKS_Survey__c
                WHERE NKS_Start_Date__c <= :currentTime AND NKS_End_Date__c >= :currentTime
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Problem getting Survey: ' + e.getMessage());
        }
    }

    /**
     * @description Function to check if user has answered Survey
     * @author Sara Mohammadi | 22-11-2023
     * @param surveyId
     * @return True if answered, False otherwise
     **/
    @AuraEnabled(cacheable=true)
    public static Boolean hasAnswered(String surveyId) {
        Id recordTypeId = getRecordTypeId('Survey Answered');
        try {
            return [
                SELECT NKS_Answered__c
                FROM NKS_Survey_Response__c
                WHERE
                    NKS_Participant__c = :UserInfo.getUserId()
                    AND NKS_Survey__c = :surveyId
                    AND recordTypeId = :recordTypeId
                LIMIT 1
            ]
            ?.NKS_Answered__c;
        } catch (Exception e) {
            throw new AuraHandledException('Problem getting Survey Response: ' + e.getMessage());
        }
    }

    /**
     * @description Function to get recordTypeId for NKS_Survey_Response__c
     * @author Sara Mohammadi | 22-11-2023
     * @param recordTypeName
     * @return recordTypeId
     **/
    @AuraEnabled(cacheable=true)
    public static String getRecordTypeId(String recordTypeName) {
        return Schema.SObjectType.NKS_Survey_Response__c.getRecordTypeInfosByName()
            .get(recordTypeName)
            .getRecordTypeId();
    }

    /**
     * @description Function to create NKS_Survey_Response__c object with recordType Answered
     * @author Sara Mohammadi | 22-11-2023
     * @param surveyId
     * @return surveyResponseId
     **/
    @AuraEnabled
    public static void createAnsweredRecord(String surveyId, Integer rating, String comment, Boolean isCanceled) {
        try {
            NKS_Survey_Response__c sr = new NKS_Survey_Response__c(
                RecordTypeId = getRecordTypeId('Survey Answered'),
                NKS_Survey__c = surveyId,
                NKS_Participant__c = UserInfo.getUserId(),
                NKS_Answered__c = true
            );
            insert sr;

            if (!isCanceled) {
                createResponseRecord(surveyId, rating, comment);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Problem creating Answered record: ' + e.getMessage());
        }
    }

    /**
     * @description Function to create NKS_Survey_Response__c object with recordType Response
     * @author Sara Mohammadi | 22-11-2023
     * @param surveyId
     * @param rating
     * @param comment
     * @return surveyResponseId
     **/
    private static void createResponseRecord(String surveyId, Integer rating, String comment) {
        Datetime scheduledTime = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        Id integrationUserId = [SELECT Id FROM User WHERE NKS_FullName__c = 'SFDX Integrasjonsbruker']?.Id;

        try {
            NKS_Survey_Response__c sr = new NKS_Survey_Response__c(
                CreatedById = integrationUserId,
                CreatedDate = scheduledTime,
                LastModifiedById = integrationUserId,
                LastModifiedDate = scheduledTime,
                RecordTypeId = NKS_InternalSurveyController.getRecordTypeId('Survey Response'),
                NKS_Survey__c = surveyId,
                NKS_Rating__c = rating,
                NKS_Comment__c = comment
            );
            insert sr;
        } catch (Exception e) {
            throw new AuraHandledException('Problem creating Response record: ' + e.getMessage());
        }
    }
}
