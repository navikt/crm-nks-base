@isTest
public class NKS_HenvendelseController_Test {
    static User usr = [SELECT Id FROM User WHERE isActive = TRUE LIMIT 1];
    static Common_Code__c themeGroup = (Common_Code__c) UTIL_TestDataFactory.createRecord(
        new Common_Code__c(Name = 'Arbeid', CRM_Code_Set__c = 'Temagrupper', CRM_Code__c = 'ARBD')
    );
    @isTest
    static void testHenvendelseSend() {
        NKS_HenvendelseController.HenvendelseRequest req = new NKS_HenvendelseController.HenvendelseRequest();
        req.requestType = 'SEND';
        req.personIdent = '12345678910';
        req.navUnitNumber = '4100';
        req.themeGroupCode = 'ARBD';
        req.content = 'TEST NOTE';

        ApiMock.setTestMock('POST_HENVENDELSE', 200, 'OK');

        Test.startTest();
        NKS_HenvendelseController.handleHenvendelseRequest(
            new List<NKS_HenvendelseController.HenvendelseRequest>{ req }
        );
        Test.stopTest();
    }

    @isTest
    static void testHenvendelseSendFail() {
        NKS_HenvendelseController.HenvendelseRequest req = new NKS_HenvendelseController.HenvendelseRequest();
        req.requestType = 'SEND';
        req.personIdent = '12345678910';
        req.navUnitNumber = '4100';
        req.themeGroupCode = 'ARBD';
        req.content = 'TEST NOTE';

        Boolean successfulTest = false;

        ApiMock.setTestMock('POST_HENVENDELSE', 500, 'Internal Server Error');

        Test.startTest();
        List<String> henvResponse = NKS_HenvendelseController.handleHenvendelseRequest(
            new List<NKS_HenvendelseController.HenvendelseRequest>{ req }
        );
        Test.stopTest();

        System.assert(String.isBlank(henvResponse[0]));
    }

    @isTest
    static void testHenvendelseHJournal() {
        NKS_HenvendelseController.HenvendelseRequest req = new NKS_HenvendelseController.HenvendelseRequest();
        req.requestType = 'JOURNAL';
        req.navCaseId = '1234567';
        req.navUnitNumber = '4100';
        req.themeCode = 'DAG';
        req.behandlingskjedeId = '12153CDF125';

        ApiMock.setTestMock('POST_HENVENDELSE_JOURNAL', 200, 'OK');

        Test.startTest();
        NKS_HenvendelseController.handleHenvendelseRequest(
            new List<NKS_HenvendelseController.HenvendelseRequest>{ req }
        );
        Test.stopTest();
    }

    @isTest
    static void testHenvendelseJournalFail() {
        NKS_HenvendelseController.HenvendelseRequest req = new NKS_HenvendelseController.HenvendelseRequest();
        req.requestType = 'JOURNAL';
        req.navCaseId = '1234567';
        req.navUnitNumber = '4100';
        req.themeCode = 'DAG';
        req.behandlingskjedeId = '12153CDF125';

        ApiMock.setTestMock('POST_HENVENDELSE_JOURNAL', 500, 'Internal Server Error');
        Boolean successfulTest = false;

        Test.startTest();
        List<String> henvResp = NKS_HenvendelseController.handleHenvendelseRequest(
            new List<NKS_HenvendelseController.HenvendelseRequest>{ req }
        );
        Test.stopTest();

        System.assert(henvResp[0].equalsIgnoreCase('ERROR'));
    }
}
