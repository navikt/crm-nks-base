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
        Assert.areEqual(1, afterLogs.size());
        Assert.areEqual(null, resp[0].themeGroup);
        Assert.areEqual(null, resp[0].queueName);
        Assert.areEqual(null, resp[0].accessNumber);
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
        List<String> unverifiedValues = new List<String>{
            null,
            '',
            'CASE123',
            'CASE123.authenticatedOK'
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
        Assert.isFalse(nonCall.get('isAuthenticated'));
        Assert.isFalse(nonCall.get('shouldRetry'));
        Assert.isFalse(noSession.get('isAuthenticated'));
        Assert.isFalse(noSession.get('shouldRetry'));
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
}
