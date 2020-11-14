@isTest
public class NKS_NavTaskManager_Test {
    
    @TestSetup
    static void makeData(){
           UTIL_TestDataFactory.createRecord(new NavTask__c());
           UTIL_TestDataFactory.createRecord(new NavUnit__c (INT_UnitNumber__c = '4100'));
    }

    @isTest
    static void testTaskPost(){
        String responseBody;
        NKS_NavTaskManager.OppgaveResponse resp = new NKS_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = [SELECT Id FROM NavTask__c LIMIT 1];


        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
            NKS_NavTaskManager.delegateTask(new List<String>{task.Id});
        Test.stopTest();

        System.assert([SELECT count() FROM NavTask__c WHERE CRM_NavUnit__r.INT_UnitNumber__c = '4100'] == 1);
    }
}
