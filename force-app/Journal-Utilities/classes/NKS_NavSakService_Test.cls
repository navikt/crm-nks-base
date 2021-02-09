@isTest
public class NKS_NavSakService_Test {
    @isTest
    static void testGetSakNavCases() {
        ApiMock.setTestMock('GET_SAK_NAV_CASES', 200, 'OK');

        Test.startTest();
        List<NKS_NavSakService.SakWrapper> returnList = NKS_NavSakService.getActorCases(
            '12345678910'
        );
        Test.stopTest();

        System.assert(!returnList.isEmpty());
    }

    @isTest
    static void testGetSakNavCasesFail() {
        ApiMock.setTestMock('GET_SAK_NAV_CASES', 404, 'NOT FOUND');
        List<NKS_NavSakService.SakWrapper> returnList = new List<NKS_NavSakService.SakWrapper>();

        Test.startTest();
        try {
            returnList = NKS_NavSakService.getActorCases('12345678910');
        } catch (AuraHandledException ex) {
            //Safely catching the aura handled exception
        }
        Test.stopTest();
        System.assert(returnList.isEmpty());
        System.assert([SELECT COUNT() FROM Application_Log__c] != 0);
    }
}
