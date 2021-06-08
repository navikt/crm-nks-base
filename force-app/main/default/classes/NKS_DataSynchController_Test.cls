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
}
