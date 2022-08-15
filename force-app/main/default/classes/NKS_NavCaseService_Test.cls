@isTest
public class NKS_NavCaseService_Test {
    @isTest
    static void testGetNavCases() {
        ApiMock.setTestMock('GET_SOGB_NAV_CASES', 200, 'OK');

        Test.startTest();
        List<NKS_NavCaseService.NavCaseWrapper> navCases = NKS_NavCaseService.getNavCases('123456789');
        Test.stopTest();

        System.assert(!navCases.isEmpty());
    }

    @isTest
    static void testGetNavCasesFail() {
        ApiMock.setTestMock('GET_SOGB_NAV_CASES', 500, 'NOT OK');

        Test.startTest();
        try {
            NKS_NavCaseService.getNavCases('123456789');
            System.assert(false, 'Test failed if this is executed. Should have an exception');
        } catch (AuraHandledException ex) {
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false, 'Test failed if this is executed. Should have another exception type');
        }
        Test.stopTest();
    }
}
