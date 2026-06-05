@isTest
public class NKS_NavCaseService_Test {
    @testSetup
    static void makeData() {
        insert new Common_Code__c(Name = 'Test Theme Name', CRM_Code__c = 'TEST_THEME_CODE', CRM_Code_set__c = 'Tema');
    }

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
