@isTest
public class NKS_PaymentListController_Test {
    @isTest
    static void testGetRecentPayments() {
        ApiMock.setTestMock('GET_PERSON_UTBETALINGER', 200, 'OK');

        Test.startTest();
        List<NKS_Utbetaling> payments = NKS_PaymentListController.getRecentPayments('12345678910');
        Test.stopTest();

        System.assert(!payments.isEmpty());
    }

    @isTest
    static void testGetPaymentHistory() {
        ApiMock.setTestMock('GET_PERSON_UTBETALINGER', 200, 'OK');

        Test.startTest();
        List<NKS_Utbetaling> payments = NKS_PaymentListController.getPaymentHistory('12345678910');
        Test.stopTest();

        System.assert(!payments.isEmpty());
    }
}
