public with sharing class NKS_CallAuthenticationController {
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

        if (NKS_PuzzelCallData.getEnquiryLogObject() == null && !Test.isRunningTest()) {
            throw new AuraHandledException('Puzzel EnquiryLog is not available.');
        }

        List<Map<String, Object>> matchingLogs = new List<Map<String, Object>>();
        for (
            Object enquiryLog : NKS_PuzzelCallData.getEnquiryLogs(new List<String>{ callCase.NKS_Puzzel_Session_Id__c })
        ) {
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
        if (matchingLogs.size() == 1) {
            String puzzelCaseId = (String) matchingLogs[0].get('puzzel__CaseId__c');
            Boolean isAuthenticated = NKS_PuzzelCallData.getAuthenticationStatus(puzzelCaseId) == 'true';
            response.put('isAuthenticated', isAuthenticated);
            response.put(
                'showUnverified',
                !isAuthenticated &&
                    puzzelCaseId != null &&
                    Pattern.matches('[0-9]{11}', NKS_PuzzelCallData.normalizeLookupValue(puzzelCaseId))
            );
        }
        response.put('shouldRetry', !response.get('isAuthenticated'));
        return response;
    }
}
