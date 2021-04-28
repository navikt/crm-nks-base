@isTest
public class NKS_PaymentService_Test {
    @isTest
    static void testGetPayments() {
        ApiMock.setTestMock('GET_PERSON_UTBETALINGER', 200, 'OK');

        Test.startTest();
        HttpResponse resp = NKS_PaymentService.getPayments('12345678910', DateTime.now().addDays(-1), DateTime.now());
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode());
    }
}
