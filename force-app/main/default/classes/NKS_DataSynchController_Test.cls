@isTest
public class NKS_DataSynchController_Test {
    @isTest
    static void testBankAccountSync() {
        Person__c person = (Person__c) UTIL_TestDataFactory.createRecord(
            new Person__c(INT_ActorId__c = '123456789', Name = '01234567890')
        );

        ApiMock.setTestMock('GET_TPS_BANKKONTO', 200, 'OK');

        Test.startTest();
        NKS_DataSynchController.doBankAccountNumberSync('01234567890');
        Test.stopTest();

        person = [
            SELECT Id, INT_BankAccountNumber__c, INT_BankAccountNumberLastModified__c
            FROM Person__c
            WHERE Id = :person.Id
        ];

        System.assert(String.isNotBlank(person.INT_BankAccountNumber__c), 'Expected bank account number to be set');
        System.assertNotEquals(
            null,
            person.INT_BankAccountNumberLastModified__c,
            'Expected bank account last updated to be set'
        );
    }
}
