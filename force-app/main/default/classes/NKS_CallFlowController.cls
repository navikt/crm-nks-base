public without sharing class NKS_CallFlowController {
    private static final List<String> QueryFields = new List<String>{
        'puzzel__SessionId__c',
        'puzzel__Queue__c',
        'puzzel__AccessNumber__c'
    };
    private static Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

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
        LoggerUtility logger = new LoggerUtility('CallFlowController');
        List<CallQueueResponse> respList = new List<CallQueueResponse>();

        if (getEnquiryLogObject() == null && !Test.isRunningTest()) {
            for (String puzSessionId : sessionIds) {
                logger.error('Could not find Enquiry Log schema', null, CRM_ApplicationDomain.Domain.NKS);
                respList.add(new CallQueueResponse(null, '')); //Person is fallback when there is no match
            }
        } else {
            List<Object> enqLogs = getEnquiryLogs(sessionIds);
            Map<String, Object> enqLogsMap = new Map<String, Object>();
            Set<String> queueNames = new Set<String>();
            for (Object enqLog : enqLogs) {
                Map<String, Object> enqMap = (Map<String, Object>) enqLog;
                if (enqMap.containsKey('puzzel__SessionId__c'))
                    enqLogsmap.put((String) enqMap.get('puzzel__SessionId__c'), enqLog);
                if (enqMap.containsKey('puzzel__Queue__c'))
                    queueNames.add((String) enqMap.get('puzzel__Queue__c'));
            }

            Map<String, Puzzel_Queue_Mapping__mdt> contextMap = new Map<String, Puzzel_Queue_Mapping__mdt>();
            for (Puzzel_Queue_Mapping__mdt queueMapping : getQueueMappings(queueNames)) {
                contextMap.put(queueMapping.Puzzel_Queue_Name__c.toLowerCase(), queueMapping);
            }

            for (String sessionId : sessionIds) {
                Object enqLog = enqLogsMap.get(sessionId);
                if (enqLog == null) {
                    logger.warning(
                        'Could not find enquiry log for sessionId ' +
                            sessionId +
                            ' with queue map ' +
                            JSON.serialize(enqLogsMap) +
                            ' with and logs ' +
                            JSON.serialize(enqLogs),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                    respList.add(new CallQueueResponse());
                    continue;
                }
                Map<String, Object> enqMap = (Map<String, Object>) enqLog;
                String queue = enqMap.containsKey('puzzel__Queue__c') ? (String) enqMap.get('puzzel__Queue__c') : '';
                String accessNumber = enqMap.containsKey('puzzel__AccessNumber__c')
                    ? (String) enqMap.get('puzzel__AccessNumber__c')
                    : '';
                Puzzel_Queue_Mapping__mdt queueMapping = contextMap.get(queue.toLowerCase());
                if (queueMapping == null) {
                    logger.error(
                        'Could not find queue mapping for sessionId ' +
                            sessionId +
                            ' with queue name ' +
                            queue +
                            ' and map ' +
                            JSON.serialize(contextMap),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                }
                respList.add(new CallQueueResponse(queueMapping, accessNumber));
            }
        }
        logger.publish();
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
            : (List<Object>) JSON.deserializeUntyped(
                  JSON.serialize(
                      Database.query(
                          queryFactory.selectFields(QueryFields)
                              .setCondition('puzzel__SessionId__c in :sessionIds')
                              .toSOQL()
                      )
                  )
              );
    }

    public class CallQueueResponse {
        @invocableVariable
        public String themeGroup;
        @invocableVariable
        public String callerContext;
        @invocableVariable
        public String queueName;
        @invocableVariable
        public String accessNumber;

        public CallQueueResponse() {
        }

        public CallQueueResponse(Puzzel_Queue_Mapping__mdt mapping, String accessNumber) {
            if (mapping != null) {
                this.themeGroup = mapping.Theme_Group_Code__c;
                this.callerContext = mapping.Caller_Context__c;
                this.queueName = mapping.Puzzel_Queue_Name__c;
            } else {
                this.themeGroup = '';
                this.callerContext = 'PERSON';
                this.queueName = 'TEST QUEUE';
            }
            this.accessNumber = accessNumber;
        }
    }
}
