@isTest
public class NKS_PaymentService_Test {
    @isTest
    static void testGetPayments() {
        ApiMock.setTestMock('GET_PERSON_UTBETALINGER', 200, 'OK');

        Test.startTest();
        List<NKS_Utbetaling> payments = NKS_PaymentService.getPayments('12345678910');
        Test.stopTest();

        System.assert(!payments.isEmpty());
    }
}
