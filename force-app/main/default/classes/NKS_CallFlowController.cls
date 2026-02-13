public without sharing class NKS_CallFlowController {
    private static final List<String> QUERY_FIELDS = new List<String>{
        'puzzel__SessionId__c',
        'puzzel__Queue__c',
        'puzzel__AccessNumber__c'
    };

    private static Schema.SObjectType getEnquiryLogObject() {
        try {
            return ((SObject) Type.forName('puzzel__EnquiryLog__c').newInstance()).getSObjectType();
        } catch (Exception e) {
            // Will be null in scratch orgs without Puzzel package
            return null;
        }
    }

    @InvocableMethod(
        label='Get Call Queue'
        description='Matches the Puzzel queue name from enquiry log to determine the caller context'
        category='Call Flow'
    )
    public static List<CallQueueResponse> getCallQueueInfo(List<String> sessionIds) {
        LoggerUtility logger = new LoggerUtility('CallFlowController');
        List<CallQueueResponse> responses = new List<CallQueueResponse>();

        if (getEnquiryLogObject() == null && !Test.isRunningTest()) {
            for (String id : sessionIds) {
                logger.error('Could not find Enquiry Log object type', null, CRM_ApplicationDomain.Domain.NKS);
                responses.add(new CallQueueResponse(null, ''));
            }
            logger.publish();
            return responses;
        }

        List<Object> enquiryLogs = getEnquiryLogs(sessionIds);
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
                logger.warning(
                    'No enquiry log found for sessionId ' +
                        sessionId +
                        ' with queue map ' +
                        JSON.serialize(enqLogsBySessionId) +
                        ' and with logs ' +
                        JSON.serialize(enquiryLogs),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
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

            responses.add(new CallQueueResponse(queueMapping, accessNumber));
        }

        logger.publish();
        return responses;
    }

    private static List<Puzzel_Queue_Mapping__mdt> getQueueMappings(Set<String> queueNames) {
        return [
            SELECT Puzzel_Queue_Name__c, Theme_Group_Code__c, Caller_Context__c
            FROM Puzzel_Queue_Mapping__mdt
            WHERE Puzzel_Queue_Name__c IN :queueNames
        ];
    }

    private static List<Object> getEnquiryLogs(List<String> sessionIds) {
        if (Test.isRunningTest()) {
            return (List<Object>) JSON.deserializeUntyped(NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG);
        }

        fflib_QueryFactory qf = new fflib_QueryFactory(getEnquiryLogObject());
        String soql = qf.selectFields(QUERY_FIELDS).setCondition('puzzel__SessionId__c IN :sessionIds').toSOQL();

        // Instead of just returning SObject records we have to serialize and then deserialize into an Object due to the fact that Puzzel Enquiry Log is a managed package object and won't be visible in scratch orgs
        return (List<Object>) JSON.deserializeUntyped(JSON.serialize(Database.query(soql)));
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
