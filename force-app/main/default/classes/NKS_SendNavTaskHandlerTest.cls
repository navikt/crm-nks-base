@isTest
public class NKS_SendNavTaskHandlerTest {
    
    @isTest
    static void testInvokeSendNavTaskFlowException() {
        Test.startTest();
        try {
            Boolean res = NKS_SendNavTaskHandler.invokeSendNavTaskFlow(null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Exception message should not be empty and should indicate an error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest 
    static void testGetProcessingId() {
        Case c = new Case(Subject = 'Test Case', NKS_Henvendelse_BehandlingsId__c = 'SomeProcessingId');
        insert c;

        Test.startTest();
        String result = NKS_SendNavTaskHandler.getProcessingId(c.Id);
        Test.stopTest();

        Assert.areEqual('SomeProcessingId', result, 'Processing ID should match the expected value');
    }
}
