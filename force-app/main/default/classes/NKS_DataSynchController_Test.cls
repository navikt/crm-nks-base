@isTest
public class NKS_DataSynchController_Test {
    @isTest
    static void testHenvendelseSynch() {
        UTIL_TestDataFactory.createRecord(new Person__c());
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code_Set__c = 'Tema', CRM_Code__c = 'DAG', Name = 'Dagpenger')
        );

        ApiMock.setTestMock('GET_HENVENDELSER', 200, 'OK');

        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE IsPersonAccount = TRUE LIMIT 1];
        NKS_DataSynchController.doHenvendelseSynch('123456789', acc.Id);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Conversation_Note__c] > 0);
        System.assert([SELECT COUNT() FROM Conversation_Note__c WHERE NKS_Incorrectly_Sent__c = TRUE] > 0);
    }

    @isTest
    static void testBankAccountSync() {
        Person__c person = (Person__c) UTIL_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789'));

        ApiMock.setTestMock('GET_TPS_BANKKONTO', 200, 'OK');

        Test.startTest();
        NKS_DataSynchController.doBankAccountNumberSync('123456789');
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
