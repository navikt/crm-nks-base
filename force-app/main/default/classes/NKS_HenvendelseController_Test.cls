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
        try {
            NKS_HenvendelseController.handleHenvendelseRequest(
                new List<NKS_HenvendelseController.HenvendelseRequest>{ req }
            );
        } catch (AuraHandledException auraEx) {
            successfulTest = true;
        }
        Test.stopTest();

        System.assert(successfulTest);
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
        try {
            NKS_HenvendelseController.handleHenvendelseRequest(
                new List<NKS_HenvendelseController.HenvendelseRequest>{ req }
            );
        } catch (AuraHandledException auraEx) {
            successfulTest = true;
        }
        Test.stopTest();

        System.assert(successfulTest);
    }

    @isTest
    static void testRetry() {
        Conversation_Note__c testNote = (Conversation_Note__c) UTIL_TestDataFactory.createRecord(
            new Conversation_Note__c(
                NKS_Theme_Group__c = themeGroup.Id,
                NKS_Journal_Status__c = 'Journal Error',
                NKS_Legacy_Case_Id__c = '1234567',
                OwnerId = usr.Id
            )
        );

        ApiMock.setTestMock('POST_HENVENDELSE', 200, 'OK');
        Test.startTest();
        System.runAs(usr) {
            ApiRetryMaster retryMaster = new ApiRetryMaster();
            retryMaster.initiateRetry();
        }
        Test.stopTest();

        Conversation_Note__c updatedNote = [
            SELECT Id, NKS_Sent__c, NKS_Journal_Status__c
            FROM Conversation_Note__c
            WHERE Id = :testNote.Id
            LIMIT 1
        ];

        System.assertEquals(true, updatedNote.NKS_Sent__c);
        System.assertEquals('Journal Completed', updatedNote.NKS_Journal_Status__c);
    }

    @isTest
    static void testJournalRetry() {
        Conversation_Note__c testNote = (Conversation_Note__c) UTIL_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Case__c = (String) UTIL_TestDataFactory.createRecord(
                        new Case(NKS_Henvendelse_BehandlingsId__c = '1234567')
                    )
                    .get('Id'),
                NKS_Theme_Group__c = themeGroup.Id,
                NKS_Journal_Status__c = 'Journal Error',
                NKS_Legacy_Case_Id__c = '1234567',
                OwnerId = usr.Id
            )
        );

        ApiMock.setTestMock('POST_HENVENDELSE_JOURNAL', 200, 'OK');
        Test.startTest();
        System.runAs(usr) {
            ApiRetryMaster retryMaster = new ApiRetryMaster();
            retryMaster.initiateRetry();
        }
        Test.stopTest();

        Conversation_Note__c updatedNote = [
            SELECT Id, NKS_Sent__c, NKS_Journal_Status__c
            FROM Conversation_Note__c
            WHERE Id = :testNote.Id
            LIMIT 1
        ];

        System.assertEquals(true, updatedNote.NKS_Sent__c);
        System.assertEquals('Journal Completed', updatedNote.NKS_Journal_Status__c);
    }

    @isTest
    static void testExceptions() {
        Test.startTest();
        NKS_HenvendelseController.setJournalSuccess('12345678');
        NKS_HenvendelseController.upateCaseBehandlingsId('12345678', '1234567CHGB');
        Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM Application_Log__c WHERE Category__c = 'Henvendelse' AND Log_Level__c = 'Critical'] ==
            2
        );
    }
}
