@isTest
public class NKS_SendNavTaskHandlerTest {
    @testSetup
    static void setupTestData() {
        NavUnit__c navUnit = new NavUnit__c(Name = 'Test Unit', INT_UnitNumber__c = '1234');
        insert navUnit;
    }

    @isTest
    static void testInvokeSendNavTaskFlowException() {
        Test.startTest();
        try {
            Boolean res = NKS_SendNavTaskHandler.invokeSendNavTaskFlow(null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage() != null,
                'Exception message should not be empty and should indicate an error: ' + e.getMessage()
            );
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

    @isTest
    static void testGetNavUnitInfo() {
        NavUnit__c testNavUnit = [SELECT Id FROM NavUnit__c LIMIT 1];

        Test.startTest();
        NavUnit__c result = NKS_SendNavTaskHandler.getNavUnitInfo(testNavUnit.Id);
        Test.stopTest();

        Assert.areEqual('Test Unit', result.Name, 'The Name field should match.');
        Assert.areEqual('1234', result.INT_UnitNumber__c, 'The INT_UnitNumber__c field should match.');
    }

    @IsTest
    static void testGetNavUnitInfoException() {
        Exception ex;

        Test.startTest();
        try {
            NKS_SendNavTaskHandler.getNavUnitInfo(null);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        Assert.areNotEqual(null, ex);
    }
}
