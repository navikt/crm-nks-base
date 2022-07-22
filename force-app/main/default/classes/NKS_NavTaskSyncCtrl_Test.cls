@isTest
public class NKS_NavTaskSyncCtrl_Test {
    @isTest
    static void testSyncOpenAndAssigned() {
        ApiMock.setTestMock('GET_OPPGAVE', 200, 'OK');

        Test.startTest();
        DIA_NavTaskSyncCtrl.syncOpenAndAssigned();
        Test.stopTest();
    }
}
