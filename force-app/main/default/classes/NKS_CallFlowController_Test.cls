@isTest
public class NKS_CallFlowController_Test {
    public static final String TEST_SESSION_ID = '1234TEST';
    public static final String TEST_QUEUE = 'TEST_QUEUE';

    public static final String MOCK_ENQUIRY_LOG =
        '[{"puzzel__SessionId__c":"' +
        TEST_SESSION_ID +
        '", "puzzel__Queue__c": "' +
        TEST_QUEUE +
        '"}]';

    @isTest
    static void testGetCallQueueInfo() {
        Test.startTest();
        List<NKS_CallFlowController.CallQueueResponse> resp = NKS_CallFlowController.getCallQueueInfo(
            new List<String>{ TEST_SESSION_ID }
        );
        Test.stopTest();

        System.assertEquals(resp[0].themeGroup, 'ARBD');
    }
}
