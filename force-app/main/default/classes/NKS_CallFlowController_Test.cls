@isTest
public class NKS_CallFlowController_Test {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_QUEUE = 'TEST_QUEUE';
    public static final String TEST_ACCESSNUMBER = '12345678';

    public static String MOCK_ENQUIRY_LOG =
        '[{"puzzel__SessionId__c":"' +
        TEST_SESSION_ID +
        '", "puzzel__Queue__c": "' +
        TEST_QUEUE +
        '", "puzzel__AccessNumber__c": "' +
        TEST_ACCESSNUMBER +
        '"}]';

    @TestSetup
    static void grantCallCaseAccess() {
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'NKS_Case' LIMIT 1].Id;
        if (
            [
                SELECT COUNT()
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSetId
            ] == 0
        ) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSetId);
        }
    }

    @isTest
    static void testGetCallQueueInfo() {
        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> resp = NKS_CallFlowController.getCallQueueInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        Assert.areEqual('ARBD', resp[0].themeGroup);
        Assert.areEqual(TEST_QUEUE, resp[0].queueName);
        Assert.areEqual(TEST_ACCESSNUMBER, resp[0].accessNumber);
    }

    @isTest
    static void testGetCallQueueInfo_InvalidId() {
        List<Application_Log__c> beforeLogs = [
            SELECT Id
            FROM Application_Log__c
            WHERE Category__c = 'CallFlowController'
        ];
        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> resp = NKS_CallFlowController.getCallQueueInfo(
            new List<String>{ 'INVALID_ID' }
        );
        Test.stopTest();
        List<Application_Log__c> afterLogs = [
            SELECT Id
            FROM Application_Log__c
            WHERE Category__c = 'CallFlowController'
        ];

        Assert.areEqual(0, beforeLogs.size());
        Assert.areEqual(0, afterLogs.size());
        Assert.areEqual(null, resp[0].themeGroup);
        Assert.areEqual(null, resp[0].queueName);
        Assert.areEqual(null, resp[0].accessNumber);
    }

    @IsTest
    static void testMissingSessionInBulkDoesNotLogCallData() {
        String lookupValue = '00000000001';
        String payload = '"' + lookupValue + '","authenticated":"true"';
        MOCK_ENQUIRY_LOG = JSON.serialize(
            new List<Object>{
                new Map<String, Object>{
                    'puzzel__SessionId__c' => TEST_SESSION_ID,
                    'puzzel__Queue__c' => TEST_QUEUE,
                    'puzzel__CaseId__c' => payload
                }
            }
        );

        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> responses = NKS_CallFlowController.getCallQueueInfo(
            new List<String>{ TEST_SESSION_ID, 'MISSING_SESSION' }
        );
        Test.stopTest();

        Assert.areEqual(lookupValue, responses[0].lookupValue);
        Assert.isNull(responses[1].lookupValue);
        List<Application_Log__c> logs = [
            SELECT Id
            FROM Application_Log__c
            WHERE Category__c = 'CallFlowController'
        ];
        Assert.areEqual(0, logs.size());
    }

    @IsTest
    static void testCallQueueResponseNullMapping() {
        NKS_CallFlowController.CallQueueResponse response;

        Test.startTest();
        response = new NKS_CallFlowController.CallQueueResponse(null, '12345678');
        Test.stopTest();

        Assert.areEqual('PERSON', response.callerContext);
        Assert.areEqual('TEST QUEUE', response.queueName);
    }

    @IsTest
    static void testInboundLookupNormalizesIdentifiersRegardlessOfAuthentication() {
        List<NKS_CallFlowController.CallQueueRequest> requests = new List<NKS_CallFlowController.CallQueueRequest>();
        List<String> expectedValues = new List<String>();
        for (String identifier : new List<String>{ '00000000001', '000000001', '12345678', '+4712345678' }) {
            requests.add(makeCallQueueRequest(identifier, TEST_SESSION_ID));
            expectedValues.add(identifier);
            for (String status : new List<String>{ 'true', 'false', 'error' }) {
                requests.add(
                    makeCallQueueRequest('"' + identifier + '", "authenticated" : "' + status + '"', TEST_SESSION_ID)
                );
                expectedValues.add(identifier);
            }
        }

        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> responses = NKS_CallFlowController.getInboundCallInfo(requests);
        Test.stopTest();

        Assert.areEqual(expectedValues.size(), responses.size());
        for (Integer i = 0; i < expectedValues.size(); i++) {
            Assert.areEqual(expectedValues[i], responses[i].lookupValue);
            Assert.areEqual(TEST_QUEUE, responses[i].queueName);
            Assert.areEqual(TEST_ACCESSNUMBER, responses[i].accessNumber);
        }
    }

    @IsTest
    static void testLegacyIdentifiersWorkWithoutAuthenticationStatus() {
        List<String> identifiers = new List<String>{ '00000000001', '000000001', '12345678', '+4712345678' };
        List<Object> logs = new List<Object>();
        List<NKS_CallFlowController.CallQueueRequest> requests = new List<NKS_CallFlowController.CallQueueRequest>();
        for (Integer i = 0; i < identifiers.size(); i++) {
            String sessionId = 'LEGACY_' + i;
            logs.add(
                new Map<String, Object>{
                    'puzzel__SessionId__c' => sessionId,
                    'puzzel__Queue__c' => TEST_QUEUE,
                    'puzzel__CaseId__c' => identifiers[i]
                }
            );
            requests.add(makeCallQueueRequest(identifiers[i], sessionId));
            requests.add(makeCallQueueRequest(null, sessionId));
        }
        MOCK_ENQUIRY_LOG = JSON.serialize(logs);

        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> responses = NKS_CallFlowController.getInboundCallInfo(requests);
        Test.stopTest();

        Assert.areEqual(identifiers.size() * 2, responses.size());
        for (Integer i = 0; i < identifiers.size(); i++) {
            Assert.areEqual(identifiers[i], responses[i * 2].lookupValue);
            Assert.areEqual(identifiers[i], responses[i * 2 + 1].lookupValue);
            Assert.areEqual(TEST_QUEUE, responses[i * 2].queueName);
            Assert.areEqual(TEST_QUEUE, responses[i * 2 + 1].queueName);
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Application_Log__c WHERE Category__c = 'CallFlowController']);
    }

    @IsTest
    static void testMalformedSearchIsNotTruncatedIntoAnIdentifier() {
        List<String> values = new List<String>{
            '"00000000001","authenticated":"True"',
            '"00000000001","authenticated":true',
            '"00000000001","authenticated":"true","authenticated":"false"',
            '"00000000001","authenticated":"true"suffix',
            '"00000000001","authenticated":"true',
            '"00000 000001","authenticated":"true"',
            '"","authenticated":"true"',
            '00000000001.authenticatedOK'
        };
        List<NKS_CallFlowController.CallQueueRequest> requests = new List<NKS_CallFlowController.CallQueueRequest>();
        for (String value : values) {
            requests.add(makeCallQueueRequest(value, TEST_SESSION_ID));
        }

        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> responses = NKS_CallFlowController.getInboundCallInfo(requests);
        Test.stopTest();

        for (Integer i = 0; i < values.size(); i++) {
            Assert.areEqual(values[i], responses[i].lookupValue);
        }
    }

    @IsTest
    static void testMissingSearchUsesOnlyTheMatchingSessionAndDoesNotOverrideExplicitSearch() {
        MOCK_ENQUIRY_LOG = JSON.serialize(
            new List<Object>{
                new Map<String, Object>{
                    'puzzel__SessionId__c' => TEST_SESSION_ID,
                    'puzzel__Queue__c' => TEST_QUEUE,
                    'puzzel__CaseId__c' => '"00000000001","authenticated":"false"'
                },
                new Map<String, Object>{
                    'puzzel__SessionId__c' => 'SECOND_SESSION',
                    'puzzel__Queue__c' => TEST_QUEUE,
                    'puzzel__CaseId__c' => '000000001'
                }
            }
        );
        List<NKS_CallFlowController.CallQueueRequest> requests = new List<NKS_CallFlowController.CallQueueRequest>{
            makeCallQueueRequest(null, 'SECOND_SESSION'),
            makeCallQueueRequest('', TEST_SESSION_ID),
            makeCallQueueRequest('12345678', TEST_SESSION_ID),
            makeCallQueueRequest(null, 'MISSING_SESSION')
        };

        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> responses = NKS_CallFlowController.getInboundCallInfo(requests);
        Test.stopTest();

        Assert.areEqual('000000001', responses[0].lookupValue);
        Assert.areEqual('00000000001', responses[1].lookupValue);
        Assert.areEqual('12345678', responses[2].lookupValue);
        Assert.isNull(responses[3].lookupValue);
    }

    @IsTest
    static void testIncomingLookupWorksBeforeEnquiryLogArrives() {
        MOCK_ENQUIRY_LOG = '[]';
        List<String> values = new List<String>{
            '00000000001',
            '000000001',
            '12345678',
            '+4712345678',
            '"00000000001","authenticated":"false"'
        };
        List<NKS_CallFlowController.CallQueueRequest> requests = new List<NKS_CallFlowController.CallQueueRequest>();
        for (String value : values) {
            requests.add(makeCallQueueRequest(value, TEST_SESSION_ID));
        }

        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> responses = NKS_CallFlowController.getInboundCallInfo(requests);
        Test.stopTest();

        for (Integer i = 0; i < 4; i++) {
            Assert.areEqual(values[i], responses[i].lookupValue);
        }
        Assert.areEqual('00000000001', responses[4].lookupValue);
    }

    @IsTest
    static void testAuthenticationRequiresCaseId() {
        try {
            NKS_CallFlowController.getCallAuthenticationStatus(null);
            Assert.fail('A missing case ID must be reported.');
        } catch (AuraHandledException expected) {
            Assert.isNotNull(expected);
        }
    }

    @IsTest
    static void testAuthenticatedPuzzelFragment() {
        Case callCase = makeCallCase();
        List<String> authenticatedValues = new List<String>{
            '"CASE123","authenticated":"true"',
            '"CASE123", "authenticated" : "true"'
        };

        Test.startTest();
        for (String value : authenticatedValues) {
            setAuthenticationLog(value, TEST_SESSION_ID);
            Map<String, Boolean> response = getAuthenticationStatus(callCase.Id);
            Assert.isTrue(response.get('isAuthenticated'));
            Assert.isFalse(response.get('shouldRetry'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testUnverifiedAndMalformedPuzzelFragments() {
        Case callCase = makeCallCase();
        List<String> unverifiedValues = new List<String>{
            '"CASE123","authenticated":"false"',
            '"CASE123","authenticated":"error"',
            '"CASE123","authenticated":""',
            '"CASE123","authenticated":null',
            '"CASE123","authenticated":"True"',
            '"CASE123","authenticated":"true',
            '"CASE123","authenticated":"true","authenticated":"false"',
            '"CASE123","authenticated":"false","authenticated":"true"',
            '"","authenticated":"true"',
            '"CASE 123","authenticated":"true"',
            '"CASE\\123","authenticated":"true"',
            '"CASE123","unauthenticated":"true"',
            'prefix"CASE123","authenticated":"true"',
            '"CASE123","authenticated":"true"suffix'
        };

        Test.startTest();
        for (String value : unverifiedValues) {
            setAuthenticationLog(value, TEST_SESSION_ID);
            Map<String, Boolean> response = getAuthenticationStatus(callCase.Id);
            Assert.isFalse(response.get('isAuthenticated'), 'Unexpected authentication for value: ' + value);
            Assert.isTrue(response.get('shouldRetry'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testMissingAndLegacyAuthenticationFormatsAreRejected() {
        Case callCase = makeCallCase();
        List<String> unverifiedValues = new List<String>{ null, '', 'CASE123', 'CASE123.authenticatedOK' };

        Test.startTest();
        for (String value : unverifiedValues) {
            setAuthenticationLog(value, TEST_SESSION_ID);
            Map<String, Boolean> response = getAuthenticationStatus(callCase.Id);
            Assert.isFalse(response.get('isAuthenticated'), 'Unexpected authentication for value: ' + value);
            Assert.isTrue(response.get('shouldRetry'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testUnverifiedPersonBadgeSupportsCurrentAndNewPuzzelFormats() {
        Case callCase = makeCallCase();
        List<String> unverifiedValues = new List<String>{
            '00000000001',
            '"00000000001","authenticated":"false"',
            '"00000000001","authenticated":"error"'
        };

        Test.startTest();
        for (String value : unverifiedValues) {
            setAuthenticationLog(value, TEST_SESSION_ID);
            Map<String, Boolean> response = getAuthenticationStatus(callCase.Id);
            Assert.isFalse(response.get('isAuthenticated'));
            Assert.isTrue(response.get('showUnverified'));
        }
        setAuthenticationLog('"00000000001","authenticated":"true"', TEST_SESSION_ID);
        Map<String, Boolean> authenticated = getAuthenticationStatus(callCase.Id);
        Test.stopTest();

        Assert.isTrue(authenticated.get('isAuthenticated'));
        Assert.isFalse(authenticated.get('showUnverified'));
        Assert.areEqual(0, [SELECT COUNT() FROM Application_Log__c WHERE Category__c = 'CallFlowController']);
    }

    @IsTest
    static void testUnverifiedBadgeRequiresAnUnambiguousPersonLookup() {
        Case callCase = makeCallCase();
        List<String> otherValues = new List<String>{
            null,
            '',
            '000000001',
            '12345678',
            '+4712345678',
            '"000000001","authenticated":"false"',
            '"12345678","authenticated":"error"',
            '"00000000001","authenticated":"True"',
            '"00000000001","authenticated":"true"suffix'
        };

        Test.startTest();
        for (String value : otherValues) {
            setAuthenticationLog(value, TEST_SESSION_ID);
            Assert.isFalse(getAuthenticationStatus(callCase.Id).get('showUnverified'));
        }
        setAuthenticationLog('00000000001', 'ANOTHER_SESSION');
        Assert.isFalse(getAuthenticationStatus(callCase.Id).get('showUnverified'));
        Test.stopTest();
    }

    @IsTest
    static void testDelayedLogAndSessionIsolation() {
        Case callCase = makeCallCase();
        setAuthenticationLog('"CASE123","authenticated":"true"', 'ANOTHER_SESSION');

        Test.startTest();
        Map<String, Boolean> pending = getAuthenticationStatus(callCase.Id);
        setAuthenticationLog('"CASE123","authenticated":"true"', TEST_SESSION_ID);
        Map<String, Boolean> arrived = getAuthenticationStatus(callCase.Id);
        Test.stopTest();

        Assert.isFalse(pending.get('isAuthenticated'));
        Assert.isTrue(pending.get('shouldRetry'));
        Assert.isTrue(arrived.get('isAuthenticated'));
    }

    @IsTest
    static void testStatusRequiresAccountPhoneAndSession() {
        Case callCase = makeCallCase();
        Id accountId = callCase.AccountId;
        setAuthenticationLog('"CASE123","authenticated":"true"', TEST_SESSION_ID);

        Test.startTest();
        callCase.AccountId = null;
        update as system callCase;
        Map<String, Boolean> noAccount = getAuthenticationStatus(callCase.Id);
        callCase.AccountId = accountId;
        callCase.Origin = 'Web';
        update as system callCase;
        Map<String, Boolean> nonCall = getAuthenticationStatus(callCase.Id);
        callCase.Origin = 'Phone';
        callCase.NKS_Puzzel_Session_Id__c = null;
        update as system callCase;
        Map<String, Boolean> noSession = getAuthenticationStatus(callCase.Id);
        Test.stopTest();

        Assert.isFalse(noAccount.get('isAuthenticated'));
        Assert.isFalse(noAccount.get('shouldRetry'));
        Assert.isFalse(noAccount.get('showUnverified'));
        Assert.isFalse(nonCall.get('isAuthenticated'));
        Assert.isFalse(nonCall.get('shouldRetry'));
        Assert.isFalse(nonCall.get('showUnverified'));
        Assert.isFalse(noSession.get('isAuthenticated'));
        Assert.isFalse(noSession.get('shouldRetry'));
        Assert.isFalse(noSession.get('showUnverified'));
    }

    @IsTest
    static void testAmbiguousLogsDoNotAuthenticate() {
        Case callCase = makeCallCase();
        setAuthenticationLog('"CASE123","authenticated":"true"', TEST_SESSION_ID);
        List<Object> logs = (List<Object>) JSON.deserializeUntyped(MOCK_ENQUIRY_LOG);
        logs.add(new Map<String, Object>{ 'puzzel__SessionId__c' => TEST_SESSION_ID });
        MOCK_ENQUIRY_LOG = JSON.serialize(logs);

        Test.startTest();
        Map<String, Boolean> response = getAuthenticationStatus(callCase.Id);
        Test.stopTest();

        Assert.isFalse(response.get('isAuthenticated'));
        Assert.isFalse(response.get('shouldRetry'));
        Assert.isFalse(response.get('showUnverified'));
    }

    private static Map<String, Boolean> getAuthenticationStatus(Id caseId) {
        Map<String, Boolean> response;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            response = NKS_CallFlowController.getCallAuthenticationStatus(caseId);
        }
        return response;
    }

    private static Case makeCallCase() {
        Account account = new Account(Name = 'BankID call test');
        insert account;
        Case callCase = new Case(AccountId = account.Id, Origin = 'Phone', NKS_Puzzel_Session_Id__c = TEST_SESSION_ID);
        insert as system callCase;
        return callCase;
    }

    private static void setAuthenticationLog(String caseId, String sessionId) {
        MOCK_ENQUIRY_LOG = JSON.serialize(
            new List<Object>{
                new Map<String, Object>{ 'puzzel__SessionId__c' => sessionId, 'puzzel__CaseId__c' => caseId }
            }
        );
    }

    private static NKS_CallFlowController.CallQueueRequest makeCallQueueRequest(String search, String sessionId) {
        NKS_CallFlowController.CallQueueRequest request = new NKS_CallFlowController.CallQueueRequest();
        request.search = search;
        request.sessionIds = sessionId;
        return request;
    }
}
