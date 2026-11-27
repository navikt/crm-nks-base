public without sharing class NKS_CallFlowController {
    @InvocableMethod(
        label='Get Call Queue'
        description='Determines caller context and separates the lookup value from Puzzel authentication status'
        category='Call Flow'
    )
    public static List<CallQueueResponse> getInboundCallInfo(List<CallQueueRequest> requests) {
        List<String> sessionIds = new List<String>();
        for (CallQueueRequest request : requests) {
            sessionIds.add(request.sessionIds);
        }
        List<CallQueueResponse> responses = getRawCallQueueInfo(sessionIds);
        for (Integer i = 0; i < requests.size(); i++) {
            String lookupValue = String.isBlank(requests[i].search) ? responses[i].lookupValue : requests[i].search;
            responses[i].lookupValue = NKS_PuzzelCallData.normalizeLookupValue(lookupValue);
        }
        return responses;
    }

    public static List<CallQueueResponse> getCallQueueInfo(List<String> sessionIds) {
        List<CallQueueRequest> requests = new List<CallQueueRequest>();
        for (String sessionId : sessionIds) {
            CallQueueRequest request = new CallQueueRequest();
            request.sessionIds = sessionId;
            requests.add(request);
        }
        return getInboundCallInfo(requests);
    }

    private static List<CallQueueResponse> getRawCallQueueInfo(List<String> sessionIds) {
        LoggerUtility logger = new LoggerUtility('CallFlowController');
        List<CallQueueResponse> responses = new List<CallQueueResponse>();

        if (NKS_PuzzelCallData.getEnquiryLogObject() == null && !Test.isRunningTest()) {
            for (String id : sessionIds) {
                logger.error('Could not find Enquiry Log object type', null, CRM_ApplicationDomain.Domain.NKS);
                responses.add(new CallQueueResponse(null, ''));
            }
            logger.publish();
            return responses;
        }

        List<Object> enquiryLogs = NKS_PuzzelCallData.getEnquiryLogs(sessionIds);
        Map<String, Object> enqLogsBySessionId = new Map<String, Object>();
        Set<String> queueNames = new Set<String>();

        for (Object enquiryLog : enquiryLogs) {
            Map<String, Object> log = (Map<String, Object>) enquiryLog;
            String sessionId = (String) log.get('puzzel__SessionId__c');
            String queueName = (String) log.get('puzzel__Queue__c');

            if (sessionId != null) {
                enqLogsBySessionId.put(sessionId, enquiryLog);
            }
            if (queueName != null) {
                queueNames.add(queueName);
            }
        }

        Map<String, Puzzel_Queue_Mapping__mdt> mappingsByQueue = new Map<String, Puzzel_Queue_Mapping__mdt>();
        for (Puzzel_Queue_Mapping__mdt mapping : getQueueMappings(queueNames)) {
            mappingsByQueue.put(mapping.Puzzel_Queue_Name__c.toLowerCase(), mapping);
        }

        for (String sessionId : sessionIds) {
            Object enquiryLog = enqLogsBySessionId.get(sessionId);

            if (enquiryLog == null) {
                responses.add(new CallQueueResponse());
                continue;
            }

            Map<String, Object> log = (Map<String, Object>) enquiryLog;
            String queue = (String) log.get('puzzel__Queue__c') ?? '';
            String accessNumber = (String) log.get('puzzel__AccessNumber__c') ?? '';

            Puzzel_Queue_Mapping__mdt queueMapping = mappingsByQueue.get(queue.toLowerCase());
            if (queueMapping == null) {
                logger.error(
                    'No queue mapping found for sessionId ' +
                        sessionId +
                        ' with queue name ' +
                        queue +
                        ' and map ' +
                        JSON.serialize(mappingsByQueue),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
            }

            CallQueueResponse response = new CallQueueResponse(queueMapping, accessNumber);
            response.lookupValue = (String) log.get('puzzel__CaseId__c');
            responses.add(response);
        }

        logger.publish();
        return responses;
    }

    private static List<Puzzel_Queue_Mapping__mdt> getQueueMappings(Set<String> queueNames) {
        return [
            SELECT Puzzel_Queue_Name__c, Theme_Group_Code__c, Caller_Context__c
            FROM Puzzel_Queue_Mapping__mdt
            WHERE Puzzel_Queue_Name__c IN :queueNames
            WITH SYSTEM_MODE
        ];
    }

    public class CallQueueRequest {
        // Keep the input name used by existing Flow versions.
        @InvocableVariable
        public String sessionIds;
        @InvocableVariable
        public String search;
    }

    public class CallQueueResponse {
        @InvocableVariable
        public String themeGroup;
        @InvocableVariable
        public String callerContext;
        @InvocableVariable
        public String queueName;
        @InvocableVariable
        public String accessNumber;
        @InvocableVariable
        public String lookupValue;

        public CallQueueResponse() {
        }

        public CallQueueResponse(Puzzel_Queue_Mapping__mdt queueMapping, String accessNumber) {
            if (queueMapping != null) {
                this.themeGroup = queueMapping.Theme_Group_Code__c;
                this.callerContext = queueMapping.Caller_Context__c;
                this.queueName = queueMapping.Puzzel_Queue_Name__c;
            } else {
                this.themeGroup = '';
                this.callerContext = 'PERSON';
                this.queueName = 'TEST QUEUE';
            }
            this.accessNumber = accessNumber;
        }
    }
}
