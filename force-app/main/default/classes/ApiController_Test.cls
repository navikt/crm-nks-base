@isTest
public  class ApiController_Test {

    public class testExtender extends ApiController {}

    @isTest
    public static void testApiController() {
        testExtender ctrl = new testExtender();
        Map<String, String> testParams = new Map<String, String> {'Test1' => 'Test1'};

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{"test":"test"}', null));
        ctrl.setEndpoint('https://testing.com')
            .setNamedCredential('testing', '/testservice')
            .setTimeout(45000)
            .setUrlParams(testParams)
            .setHeaders(testParams)
            .addHeader('header2', 'header2')
            .addUrlParam('urlTest2', 'urlTest2');

        Test.startTest();
            try {
                ctrl.doCallout();
            }
            catch(ApiController.InvalidOperationException ex) {
                System.assertEquals('Cannot perform callout without defining REST method', ex.getMessage());
            }
            ctrl.setMethod('GET');
            ctrl.doCallout();
        Test.stopTest();

        //For test coverage
        ctrl.getRequest();
        ctrl.getEndpoint();

        System.assertEquals(200, ctrl.getResponse().getStatusCode());
    }
}