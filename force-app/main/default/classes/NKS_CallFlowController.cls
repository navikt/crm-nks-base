public without sharing class NKS_CallFlowController {
    // Puzzel appends a property to a quoted lookup value, rather than sending standalone JSON.
    private static final Pattern AUTHENTICATION_PAYLOAD = Pattern.compile(
        '"([^"\\s\\\\]+)",\\s*"authenticated"\\s*:\\s*"(true|false|error)"'
    );
    private static final List<String> QUERY_FIELDS = new List<String>{
        'puzzel__SessionId__c',
        'puzzel__Queue__c',
        'puzzel__AccessNumber__c',
        'puzzel__CaseId__c'
    };

    @AuraEnabled
    public static Map<String, Boolean> getCallAuthenticationStatus(Id caseId) {
        Map<String, Boolean> response = new Map<String, Boolean>{
            'isAuthenticated' => false,
            'showUnverified' => false,
            'shouldRetry' => false
        };
        if (caseId == null) {
            throw new AuraHandledException('A call case ID is required.');
        }

        List<Case> cases = [
            SELECT AccountId, Origin, NKS_Puzzel_Session_Id__c
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
        if (cases.isEmpty()) {
            throw new AuraHandledException('The call case is not accessible.');
        }
        Case callCase = cases[0];
        if (
            callCase.Origin != 'Phone' ||
            callCase.AccountId == null ||
            String.isBlank(callCase.NKS_Puzzel_Session_Id__c)
        ) {
            return response;
        }

        if (getEnquiryLogObject() == null && !Test.isRunningTest()) {
            throw new AuraHandledException('Puzzel EnquiryLog is not available.');
        }

        List<Map<String, Object>> matchingLogs = new List<Map<String, Object>>();
        for (Object enquiryLog : getEnquiryLogs(new List<String>{ callCase.NKS_Puzzel_Session_Id__c })) {
            Map<String, Object> log = (Map<String, Object>) enquiryLog;
            if ((String) log.get('puzzel__SessionId__c') == callCase.NKS_Puzzel_Session_Id__c) {
                matchingLogs.add(log);
            }
        }
        if (matchingLogs.size() > 1) {
            LoggerUtility logger = new LoggerUtility('CallFlowController');
            logger.error('Multiple EnquiryLogs found for call case ' + caseId, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return response;
        }
        Boolean isAuthenticated = false;
        if (matchingLogs.size() == 1) {
            String puzzelCaseId = (String) matchingLogs[0].get('puzzel__CaseId__c');
            if (puzzelCaseId != null) {
                Matcher payload = AUTHENTICATION_PAYLOAD.matcher(puzzelCaseId);
                isAuthenticated = payload.matches() && payload.group(2) == 'true';
                response.put(
                    'showUnverified',
                    !isAuthenticated && Pattern.matches('[0-9]{11}', normalizeLookupValue(puzzelCaseId))
                );
            }
        }
        response.put('isAuthenticated', isAuthenticated);
        response.put('shouldRetry', !isAuthenticated);
        return response;
    }

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
        description='Determines caller context and separates the lookup value from Puzzel authentication status'
        category='Call Flow'
    )
    public static List<CallQueueResponse> getInboundCallInfo(List<CallQueueRequest> requests) {
        List<String> sessionIds = new List<String>();
        for (CallQueueRequest request : requests) {
            sessionIds.add(request.sessionIds);
        }
        List<CallQueueResponse> responses = getCallQueueInfo(sessionIds);
        for (Integer i = 0; i < requests.size(); i++) {
            if (!String.isBlank(requests[i].search)) {
                responses[i].lookupValue = normalizeLookupValue(requests[i].search);
            }
        }
        return responses;
    }

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
            response.lookupValue = normalizeLookupValue((String) log.get('puzzel__CaseId__c'));
            responses.add(response);
        }

        logger.publish();
        return responses;
    }

    private static String normalizeLookupValue(String value) {
        if (value == null) {
            return null;
        }
        Matcher payload = AUTHENTICATION_PAYLOAD.matcher(value);
        return payload.matches() ? payload.group(1) : value;
    }

    private static List<Puzzel_Queue_Mapping__mdt> getQueueMappings(Set<String> queueNames) {
        return [
            SELECT Puzzel_Queue_Name__c, Theme_Group_Code__c, Caller_Context__c
            FROM Puzzel_Queue_Mapping__mdt
            WHERE Puzzel_Queue_Name__c IN :queueNames
            WITH SYSTEM_MODE
        ];
    }

    private static List<Object> getEnquiryLogs(List<String> sessionIds) {
        if (Test.isRunningTest()) {
            return (List<Object>) JSON.deserializeUntyped(NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG);
        }

        fflib_QueryFactory qf = new fflib_QueryFactory(getEnquiryLogObject());
        String soql = qf.selectFields(QUERY_FIELDS).setCondition('puzzel__SessionId__c IN :sessionIds').toSOQL();

        // Instead of just returning SObject records we have to serialize and then deserialize into an Object due to the fact that Puzzel Enquiry Log is a managed package object and won't be visible in scratch orgs
        return (List<Object>) JSON.deserializeUntyped(JSON.serialize(Database.query(soql, AccessLevel.SYSTEM_MODE)));
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
