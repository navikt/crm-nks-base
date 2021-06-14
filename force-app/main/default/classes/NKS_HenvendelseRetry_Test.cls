@isTest
public class NKS_HenvendelseRetry_Test {
    static User retryUser = [SELECT Id FROM User WHERE isActive = TRUE LIMIT 1];

    @isTest
    static void testPostAndJournalError() {
        ApiMock.setTestMock('POST_HENVENDELSE', 200, 'OK');
        UTIL_TestDataFactory.createRecord(
            new Conversation_Note__c(OwnerId = retryUser.Id, NKS_Journal_Status__c = 'Journal Error')
        );

        NKS_HenvendelseRetry retryCtrl = new NKS_HenvendelseRetry();
        Test.startTest();
        retryCtrl.execute(null);
        Test.stopTest();

        Conversation_Note__c handledNote = [
            SELECT Id, NKS_Sent__c, NKS_Journal_Status__c
            FROM Conversation_Note__c
            LIMIT 1
        ];
        System.assertEquals(true, handledNote.NKS_Sent__c);
        System.assertEquals('Journal Completed', handledNote.NKS_Journal_Status__c);
    }

    @isTest
    static void testJournalRetry() {
        ApiMock.setTestMock('POST_HENVENDELSE', 200, 'OK');
        UTIL_TestDataFactory.createRecord(
            new Conversation_Note__c(
                OwnerId = retryUser.Id,
                NKS_Journal_Status__c = 'Journal Error',
                NKS_Henvendelse_BehandlingsId__c = '1234TEST'
            )
        );

        NKS_HenvendelseRetry retryCtrl = new NKS_HenvendelseRetry();
        Test.startTest();
        retryCtrl.execute(null);
        Test.stopTest();

        Conversation_Note__c handledNote = [
            SELECT Id, NKS_Sent__c, NKS_Journal_Status__c, NKS_Number_of_API_Retries__c
            FROM Conversation_Note__c
            LIMIT 1
        ];
        System.assertEquals(true, handledNote.NKS_Sent__c);
        System.assertEquals(1, handledNote.NKS_Number_of_API_Retries__c);
        System.assertEquals('Journal Completed', handledNote.NKS_Journal_Status__c);
    }

    @isTest
    static void testRetryLimitExceeded() {
        UTIL_TestDataFactory.createRecord(
            new Conversation_Note__c(OwnerId = retryUser.Id, NKS_Number_of_API_Retries__c = 2)
        );

        NKS_HenvendelseRetry retryCtrl = new NKS_HenvendelseRetry();
        Test.startTest();
        retryCtrl.execute(null);
        Test.stopTest();

        Conversation_Note__c handledNote = [
            SELECT Id, NKS_Sent__c, NKS_Journal_Status__c
            FROM Conversation_Note__c
            LIMIT 1
        ];
        System.assertEquals(false, handledNote.NKS_Sent__c);
    }
}
