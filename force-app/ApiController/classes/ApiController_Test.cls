@isTest
public class ApiController_Test {
    private static testExtender ctrl = new testExtender();

    public class testExtender extends ApiController {
    }

    @isTest
    public static void testApiController() {
        testExtender ctrl = new testExtender();
        Map<String, String> testParams = new Map<String, String>{
            'Test1' => 'Test1'
        };

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', '{"test":"test"}', null)
        );
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
        } catch (ApiController.InvalidOperationException ex) {
            System.assertEquals(
                'Cannot perform callout without defining REST method',
                ex.getMessage()
            );
        }
        ctrl.setMethod('GET');
        ctrl.doCallout();
        Test.stopTest();

        //For test coverage
        ctrl.getRequest();
        ctrl.getEndpoint();

        System.assertEquals(200, ctrl.getResponse().getStatusCode());
    }

    @isTest
    static void testReplacePathParameters() {
        String testPath = '/testservice/{testparam}/{testparam2}';
        Map<String, String> paramMap = new Map<String, String>{
            'testparam' => 'success',
            'testparam2' => 'success2'
        };
        testExtender ctrl = new testExtender();

        Test.startTest();
        String outputPath = ctrl.replacePathParameters(testPath, paramMap);
        Test.stopTest();

        System.assertEquals('/testservice/success/success2', outputPath);
    }

    @isTest
    static void testInitRequest() {
        Test.startTest();
        ctrl.initRequest('Testing', 'TEST_SERVICE_CONFIG');
        Test.stopTest();

        //When in test context the standard test configuration is returned
        System.assertNotEquals(ctrl.getEndpoint(), null);
    }

    @isTest
    static void testMock() {
        User usr = [SELECT Id FROM User WHERE isActive = TRUE LIMIT 1];
        insert new NKS_APIControllerUseMock__c(
            SetupOwnerId = usr.Id,
            NKS_Status__c = 'OK',
            NKS_StatusCode__c = '200',
            NKS_UseMock__c = true
        );
        Test.startTest();
        System.runAs(usr) {
            ctrl.initRequest('Testing', 'TEST_SERVICE_CONFIG');
            ctrl.doCallout();
        }
        Test.stopTest();

        System.assertEquals('\"TEST\"', ctrl.getResponse().getBody());
    }
}
