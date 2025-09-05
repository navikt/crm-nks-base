public without sharing class NKS_CallFlowController {
    private static final List<String> QUERY_FIELDS = new List<String>{
        'puzzel__SessionId__c',
        'puzzel__Queue__c',
        'puzzel__AccessNumber__c'
    };
    private static final String DEFAULT_CONTEXT = 'PERSON';
    private static final String DEFAULT_QUEUE = 'TEST QUEUE';
    private static final Map<String, Schema.SObjectType> GLOBAL_DESC = Schema.getGlobalDescribe();

    private static Schema.SObjectType getEnquiryLogObject() {
        return GLOBAL_DESC.get('puzzel__EnquiryLog__c');
    }

    private static List<Puzzel_Queue_Mapping__mdt> getQueueMappings(Set<String> queueNames) {
        return [
            SELECT Puzzel_Queue_Name__c, Theme_Group_Code__c, Caller_Context__c
            FROM Puzzel_Queue_Mapping__mdt
            WHERE Puzzel_Queue_Name__c IN :queueNames
        ];
    }

    private static List<SObject> getEnquiryLogs(List<String> sessionIds) {
        if (Test.isRunningTest()) {
            return (List<SObject>) JSON.deserialize(NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG, SObject[].class);
        }

        fflib_QueryFactory qf = new fflib_QueryFactory(getEnquiryLogObject());
        return Database.query(
            qf.selectFields(QUERY_FIELDS).setCondition('puzzel__SessionId__c IN :sessionIds').toSOQL()
        );
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
            for (String puzzelSessionId : sessionIds) {
                logger.error('Missing Enquiry Log object', null, CRM_ApplicationDomain.Domain.NKS);
                responses.add(new CallQueueResponse(null, ''));
            }
            logger.publish();
            return responses;
        }

        List<SObject> enqLogs = getEnquiryLogs(sessionIds);
        Map<String, SObject> enqLogsBySession = new Map<String, SObject>();
        Set<String> queueNames = new Set<String>();

        for (SObject log : enqLogs) {
            String sessionId = (String) log.get('puzzel__SessionId__c');
            if (sessionId != null)
                enqLogsBySession.put(sessionId, log);

            String queue = (String) log.get('puzzel__Queue__c');
            if (queue != null)
                queueNames.add(queue);
        }

        Map<String, Puzzel_Queue_Mapping__mdt> contextMap = new Map<String, Puzzel_Queue_Mapping__mdt>();
        for (Puzzel_Queue_Mapping__mdt queueMapping : getQueueMappings(queueNames)) {
            contextMap.put(queueMapping.Puzzel_Queue_Name__c.toLowerCase(), queueMapping);
        }

        for (String sessionId : sessionIds) {
            SObject log = enqLogsBySession.get(sessionId);

            if (log == null) {
                logger.warning(
                    'No enquiry log for sessionId ' +
                        sessionId +
                        ' with queue map ' +
                        JSON.serialize(enqLogsBySession) +
                        ' and logs ' +
                        JSON.serialize(enqLogs),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
                responses.add(new CallQueueResponse());
                continue;
            }

            String queue = (String) log.get('puzzel__Queue__c');
            queue = String.isBlank(queue) ? '' : queue;
            String accessNumber = (String) log.get('puzzel__AccessNumber__c');
            accessNumber = String.isBlank(accessNumber) ? '' : accessNumber;

            Puzzel_Queue_Mapping__mdt queueMapping = contextMap.get(queue?.toLowerCase());
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

            responses.add(new CallQueueResponse(queueMapping, accessNumber));
        }

        logger.publish();
        return responses;
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
        public CallQueueResponse(Puzzel_Queue_Mapping__mdt mapping, String accessNumber) {
            this.accessNumber = accessNumber;
            if (mapping != null) {
                this.themeGroup = mapping.Theme_Group_Code__c;
                this.callerContext = mapping.Caller_Context__c;
                this.queueName = mapping.Puzzel_Queue_Name__c;
            } else {
                this.themeGroup = '';
                this.callerContext = DEFAULT_CONTEXT;
                this.queueName = DEFAULT_QUEUE;
            }
        }
    }
}
