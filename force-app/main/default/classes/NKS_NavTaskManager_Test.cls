@isTest
public class NKS_NavTaskManager_Test {
    @TestSetup
    static void makeData() {
        UTIL_TestDataFactory.createRecord(new NavTask__c());
        UTIL_TestDataFactory.createRecord(new NavUnit__c(INT_UnitNumber__c = '4100'));
    }

    @isTest
    static void testTaskPost() {
        String responseBody;
        NKS_NavTaskManager.OppgaveResponse resp = new NKS_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = getTask();

        NKS_NavTaskManager.NavTaskRequest taskRequest = new NKS_NavTaskManager.NavTaskRequest('POST', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.handleNavTaskRequests(new List<NKS_NavTaskManager.NavTaskRequest>{ taskRequest });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Info'] == 1);
    }

    @isTest
    static void testTaskPostFail() {
        String responseBody;
        NKS_NavTaskManager.OppgaveResponse resp = new NKS_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = getTask();

        NKS_NavTaskManager.NavTaskRequest taskRequest = new NKS_NavTaskManager.NavTaskRequest('POST', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(403, 'Forbidden', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.handleNavTaskRequests(new List<NKS_NavTaskManager.NavTaskRequest>{ taskRequest });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Info'] == 1);
    }

    @isTest
    static void testTaskPatch() {
        String responseBody;
        NKS_NavTaskManager.OppgaveResponse resp = new NKS_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        NavTask__c task = getTask();
        task.CRM_Priority__c = 'NORM';
        task.INT_External_Reference__c = 123456789;

        NKS_NavTaskManager.NavTaskRequest taskRequest = new NKS_NavTaskManager.NavTaskRequest('EDIT', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.handleNavTaskRequests(new List<NKS_NavTaskManager.NavTaskRequest>{ taskRequest });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Info'] == 1);
    }

    @isTest
    static void testTaskPatchFail() {
        String responseBody;
        NKS_NavTaskManager.OppgaveResponse resp = new NKS_NavTaskManager.OppgaveResponse();
        resp.id = 123456789;
        resp.tildeltEnhetsnr = '4100';
        resp.versjon = 2;
        NavTask__c task = getTask();
        task.CRM_Priority__c = 'NORM';
        task.INT_External_Reference__c = 123456789;

        NKS_NavTaskManager.NavTaskRequest taskRequest = new NKS_NavTaskManager.NavTaskRequest('EDIT', task);
        taskRequest.themeGroupCode = 'ARBD';
        taskRequest.themeCode = 'AAP';
        taskRequest.subthemeCode = 'ab0039';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(404, 'Not found', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.handleNavTaskRequests(new List<NKS_NavTaskManager.NavTaskRequest>{ taskRequest });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Error'] == 1);
    }

    @isTest
    static void testTaskTypeGet() {
        NKS_NavTaskManager.OppgaveTypeResponse resp = new NKS_NavTaskManager.OppgaveTypeResponse();
        resp.oppgavetype = 'VURD_HENV';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.getTaskTypes('AAP');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Info'] == 1);
    }

    @isTest
    static void testTaskTypeGetFail() {
        NKS_NavTaskManager.OppgaveTypeResponse resp = new NKS_NavTaskManager.OppgaveTypeResponse();
        resp.oppgavetype = 'VURD_HENV';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(404, 'Not found', JSON.serialize(resp), null));

        Test.startTest();
        NKS_NavTaskManager.getTaskTypes('AAP');
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c = 'Error'] == 1);
    }

    private static NavTask__c getTask() {
        return [
            SELECT
                Id,
                NKS_Task_Type__c,
                CRM_DueDate__c,
                INT_Journal_Entry_Id__c,
                CRM_Priority__c,
                NKS_Comments__c,
                NKS_Assignee__c,
                NKS_Task_Version__c,
                NKS_NAV_Case_Reference__c,
                NKS_Henvendelse_BehandlingsId__c
            FROM NavTask__c
            LIMIT 1
        ];
    }
}
