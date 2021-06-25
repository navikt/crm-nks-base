@IsTest
private with sharing class NKS_HenvendelseListController_Test {
    @IsTest
    static void getPersonHenvendelserSuccess() {
        ApiMock.setTestMock('GET_HENVENDELSER', 200, 'OK');
        List<NKS_HenvendelseListController.MessageThread> result;
        Test.startTest();
        result = NKS_HenvendelseListController.getPersonHenvendelser('1234567890');
        Test.stopTest();
    }

    @IsTest
    static void getPersonHenvendelserError() {
        ApiMock.setTestMock('GET_HENVENDELSER', 500, 'Error');

        Test.startTest();
        try {
            NKS_HenvendelseListController.getPersonHenvendelser('1234567890');
        } catch (AuraHandledException ex) {
            System.assert(true, 'Correct exception');
        } catch (Exception ex) {
            System.assert(false, 'Wrong exception');
        }
        Test.stopTest();
    }
}
