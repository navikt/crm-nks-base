@isTest
public with sharing class nksDueDateUtility_Test {
    @TestSetup
    static void makeData(){
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'SYK', Name = 'Barnebidrag', CRM_Code_Set__c = 'Tema')
        );
        UTIL_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'VUR_KONS_YTE', Name = 'Barnebidrag', CRM_Code_Set__c = 'Tema')
        );
        List<Common_Code__c> codeList = [SELECT Id FROM Common_Code__c];
        System.debug(codeList);
        UTIL_TestDataFactory.createRecord(new NavTask__c(Name = 'TEST TASK', INT_External_Reference__c = 53339, NKS_Theme__c = codeList.get(1).Id, NKS_TaskType__c = codeList.get(0).Id));
        
    }
    @isTest
    static void setDueDateTest(){
       List<NavTask__c> navList = [SELECT Id, NKS_Theme__c, NKS_TaskType__c FROM NavTask__c];
       System.debug(navList);
       Test.startTest();
       List<Date> dateList = nksDueDateUtility.setDueDate(navList);
       Test.stopTest();
       System.assertEquals(false, dateList.isEmpty());
    }
}
