@isTest
public with sharing class NKS_NAVTaskTypeControllerTest {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'VURD_HENV', Name = 'Vurder henvendelse', CRM_Code_Set__c = 'Oppgavetyper')
        );
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(
                CRM_Code__c = 'VUR_KONS_YTE',
                Name = 'Vurder konsekvens for ytelse',
                CRM_Code_Set__c = 'Oppgavetyper'
            )
        );
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'KONT_BRUK', Name = 'Kontakt bruker', CRM_Code_Set__c = 'Oppgavetyper')
        );
    }
    @isTest
    static void testGetTaskTypes() {
        Test.startTest();
        List<NKS_NAVTaskTypeController.CommonCode> tasktypes = NKS_NAVTaskTypeController.getTaskTypes('AAP');
        Test.stopTest();

        System.assertEquals(3, tasktypes.size());
    }
    @isTest
    static void testGetTaskTypesMissingInput() {
        Test.startTest();
        List<NKS_NAVTaskTypeController.CommonCode> tasktypes = NKS_NAVTaskTypeController.getTaskTypes('');
        Test.stopTest();

        System.assertEquals(3, tasktypes.size());
    }
}
