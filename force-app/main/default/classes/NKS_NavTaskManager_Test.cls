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

        NKS_NavTaskManager.NavTaskRequest taskRequest = new NKS_NavTaskManager.NavTaskRequest('POST', task);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.handleNavTaskRequests(new List<NKS_NavTaskManager.NavTaskRequest>{taskRequest});
        Test.stopTest();

        System.assert([SELECT count() FROM NavTask__c WHERE CRM_NavUnit__r.INT_UnitNumber__c = '4100'] == 1);
    }

    @isTest
    static void testTaskPatch(){
        String responseBody;
        NKS_NavTaskManager.OppgaveResponse resp = new NKS_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = [SELECT Id FROM NavTask__c LIMIT 1];
        task.CRM_Priority__c = 'NORM';
        task.INT_External_Reference__c = 123456789;

        NKS_NavTaskManager.NavTaskRequest taskRequest = new NKS_NavTaskManager.NavTaskRequest('EDIT', task);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
            NKS_NavTaskManager.handleNavTaskRequests(new List<NKS_NavTaskManager.NavTaskRequest>{taskRequest});
        Test.stopTest();

        System.assert([SELECT count() FROM NavTask__c WHERE CRM_Priority__c = 'NORM'] == 1);
    }
}
