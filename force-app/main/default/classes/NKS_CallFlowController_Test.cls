@isTest
public class NKS_CallFlowController_Test {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_QUEUE = 'TEST_QUEUE';
    public static final String TEST_ACCESSNUMBER = '12345678';

    public static String MOCK_ENQUIRY_LOG =
        '[{"attributes":{"type":"puzzel__EnquiryLog__c"},' +
        '"puzzel__SessionId__c":"' +
        TEST_SESSION_ID +
        '",' +
        '"puzzel__Queue__c":"' +
        TEST_QUEUE +
        '",' +
        '"puzzel__AccessNumber__c":"' +
        TEST_ACCESSNUMBER +
        '"}]';

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
}
