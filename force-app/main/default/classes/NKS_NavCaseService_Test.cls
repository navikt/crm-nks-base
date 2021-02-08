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
}
