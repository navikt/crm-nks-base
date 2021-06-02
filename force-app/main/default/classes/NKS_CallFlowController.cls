public without sharing class NKS_CallFlowController {
    private static Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
    private static final List<String> QueryFields = new List<String>{ 'puzzel__SessionId__c', 'puzzel__Queue__c' };

    /**
     * @description: Returns the Enquiry log SObject type if it exists
     * @author Stian Ruud Schikora | 05-28-2021
     * @return Schema.SObjectType
     **/
    private static Schema.SObjectType getEnquiryLogObject() {
        return globalDesc.containsKey('puzzel__EnquiryLog__c') ? globalDesc.get('puzzel__EnquiryLog__c') : null;
    }

    @InvocableMethod(
        label='Get Call Queue'
        description='Matches the Puzzel queue name from enquiry log to determine the caller context'
        category='Call Flow'
    )
    public static List<CallQueueResponse> getCallQueueInfo(List<String> sessionIds) {
        List<CallQueueResponse> respList = new List<CallQueueResponse>();

        if (getEnquiryLogObject() == null && !Test.isRunningTest()) {
            for (String puzSessionId : sessionIds) {
                respList.add(new CallQueueResponse('', 'PERSON', 'TEST QUEUE')); //Person is fallback when there is no match
            }
        } else {
            List<Object> enqLogs = getEnquiryLogs(sessionIds);
            Set<String> queueNames = new Set<String>();
            for (Object enqLog : enqLogs) {
                Map<String, Object> enqMap = (Map<String, Object>) enqLog;
                if (enqMap.containsKey('puzzel__Queue__c'))
                    queueNames.add((String) enqMap.get('puzzel__Queue__c'));
            }

            for (Puzzel_Queue_Mapping__mdt queueMapping : getQueueMappings(queueNames)) {
                respList.add(new CallQueueResponse(queueMapping.Theme_Group_Code__c, queueMapping.Caller_Context__c, queueMapping.Puzzel_Queue_Name__c));
            }
        }
        return respList;
    }

    /**
     * @description: Returns the mappings from custom metadata for the defines queue names
     * @author Stian Ruud Schikora | 05-28-2021
     * @param queueNames
     * @return List<Puzzel_Queue_Mapping__mdt>
     **/
    private static List<Puzzel_Queue_Mapping__mdt> getQueueMappings(Set<String> queueNames) {
        return [
            SELECT Puzzel_Queue_Name__c, Theme_Group_Code__c, Caller_Context__c
            FROM Puzzel_Queue_Mapping__mdt
            WHERE Puzzel_Queue_Name__c IN :queueNames
        ];
    }

    /**
     * @description: Queries the enquiry logs matching the sessionId set.
     * @author Stian Ruud Schikora | 05-28-2021
     * @param sessionIds
     * @return List<SObject>
     **/
    private static List<Object> getEnquiryLogs(List<String> sessionIds) {
        fflib_QueryFactory queryFactory = new fflib_QueryFactory(getEnquiryLogObject());

        return Test.isRunningTest()
            ? (List<Object>) JSON.deserializeUntyped(NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG)
            : (List<Object>) JSON.deserializeUntyped(JSON.serialize(Database.query(queryFactory.selectFields(QueryFields).setCondition('puzzel__SessionId__c in :sessionIds').toSOQL())));
    }

    public class CallQueueResponse {
        @invocableVariable
        public String themeGroup;
        @invocableVariable
        public String callerContext;
        @invocableVariable
        public String queueName;

        public CallQueueResponse(String themeGroup, String callerContext, String queueName) {
            this.themeGroup = themeGroup;
            this.callerContext = callerContext;
            this.queueName = queueName;
        }
    }
}