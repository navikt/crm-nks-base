@isTest
public class NKS_DataSynchController_Test {
    @isTest
    static void testBankAccountSync() {
        Person__c person = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(INT_ActorId__c = '123456789', Name = '01234567890')
        );

        ApiMock.setTestMock('POST_HENT_AKTIV_KONTO', 200, 'OK');

        Test.startTest();
        NKS_DataSynchController.doBankAccountNumberSync('01234567890');
        Test.stopTest();

        person = [
            SELECT Id, INT_BankAccountNumber__c, INT_BankAccountNumberLastModified__c, INT_BankAccountSource__c
            FROM Person__c
            WHERE Id = :person.Id
        ];

        System.assert(String.isNotBlank(person.INT_BankAccountNumber__c), 'Expected bank account number to be set');
        System.assert(String.isNotBlank(person.INT_BankAccountSource__c), 'Expected bank account source to be set');
        System.assertNotEquals(
            null,
            person.INT_BankAccountNumberLastModified__c,
            'Expected bank account last updated to be set'
        );
    }

    @isTest
    static void testBankAccountSyncHttpError() {
        Person__c person = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(INT_ActorId__c = '123456789', Name = '01234567890')
        );
        ApiMock.setTestMock('POST_HENT_AKTIV_KONTO', 400, 'Bad Request');

        Test.startTest();
        NKS_DataSynchController.doBankAccountNumberSync('01234567890');
        Test.stopTest();

        List<Application_Log__c> logs = [
            SELECT Id
            FROM Application_Log__c
            LIMIT 1
        ];

        Assert.areEqual(1, logs.size());
    }
}
