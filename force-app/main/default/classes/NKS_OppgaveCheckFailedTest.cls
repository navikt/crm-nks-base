/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 14-02-2023
 * @last modified by  : mamikals
 **/
@IsTest
public with sharing class NKS_OppgaveCheckFailedTest {
    @TestSetup
    static void makeData() {
        List<Person__c> persons = NKS_TestDataFactory.createPersons(4);
        String personTaskRecordType = Schema.getGlobalDescribe()
            .get('NavTask__c')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('NKS_Person_Task')
            .getRecordTypeId();

        Common_code__c dagTheme = new Common_code__c(
            CRM_Active__c = true,
            CRM_Archive_Theme__c = true,
            CRM_Code__c = 'DAG',
            CRM_Code_set__c = 'Tema',
            Name = 'Dagpenger'
        );
        Common_code__c arbTheme = new Common_code__c(
            CRM_Active__c = true,
            CRM_Archive_Theme__c = true,
            CRM_Code__c = 'ARB',
            CRM_Code_set__c = 'Tema',
            Name = 'Arbeid'
        );
        Common_code__c ytTaskType = new Common_code__c(
            CRM_Active__c = true,
            CRM_Archive_Theme__c = false,
            CRM_Code__c = 'VUR_KONS_YTE',
            CRM_Code_Set__c = 'Oppgavetyper',
            Name = 'Vurder konsekvens for ytelse'
        );
        Common_code__c henvTaskType = new Common_code__c(
            CRM_Active__c = true,
            CRM_Archive_Theme__c = false,
            CRM_Code__c = 'VURD_HENV',
            CRM_Code_Set__c = 'Oppgavetyper',
            Name = 'Vurder henvendelse'
        );
        upsert new List<Common_code__c>{ dagTheme, arbTheme, ytTaskType, henvTaskType };
        List<Common_code__c> themeCodes = new List<Common_code__c>{ dagTheme, arbTheme };
        List<Common_code__c> taskTypeCodes = new List<Common_code__c>{ ytTaskType, henvTaskType };

        List<Integer> orderOfAccounts = new List<Integer>{ 0, 1, 2, 3, 0, 1, 2, 3, 2, 3, 3 };
        List<Integer> orderOfThemes = new List<Integer>{ 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0 };
        List<Integer> orderOfTaskTypes = new List<Integer>{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0 };
        List<NavTask__c> tasks = new List<NavTask__c>();
        Integer extRef;
        for (Integer i = 0; i < 11; i++) {
            if (i < 4) {
                extRef = null;
            } else {
                extref = Integer.valueOf(('1234567' + i).rightPad(9, '9'));
            }
            tasks.add(
                new NavTask__c(
                    CRM_Account__c = persons[orderOfAccounts[i]].CRM_Account__c,
                    CRM_Priority__c = 'NORM',
                    NKS_Theme__c = themeCodes[orderOfThemes[i]].Id,
                    INT_External_Reference__c = extRef,
                    NKS_Status__c = 'Opprettet',
                    NKS_TaskType__c = taskTypeCodes[orderOfTaskTypes[i]].Id,
                    recordTypeId = personTaskRecordType,
                    NKS_Date_Registered__c = Date.today()
                )
            );
        }
        insert tasks;
    }

    @IsTest
    static void testgetFailedOppgaverPersonList() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '[]', null));
        Test.startTest();
        NKS_OppgaveCheckFailed.OppgaveCheckReturnWrapper failedIdents = NKS_OppgaveCheckFailed.getFailedOppgaverPersonList(
            Date.today()
        );
        Test.stopTest();

        System.assertEquals(3, failedIdents.aktoersNeedCheckedList.size());
    }
}
