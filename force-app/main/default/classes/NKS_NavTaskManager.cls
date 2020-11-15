public with sharing class NKS_NavTaskManager {

    @InvocableMethod(label='Process NAV task')
    public static void handleNavTaskRequests(List<NavTaskRequest> taskRequests) {
        Map<Id, NavTask__c> taskMap = queryTasks(taskRequests);

        for (NavTaskRequest taskRequest : taskRequests) {
            switch on (taskRequest.requestType){
                when 'POST' {
                    postTask(taskMap.get(taskRequest.task.Id));
                }
                when 'EDIT' {
                    patchEditTask(taskRequest.task);
                }
            }
        }
    }

    private static Map<Id, NavTask__c> queryTasks(List<NavTaskRequest> taskRequests){
        Set<Id> taskIds = new Set<Id>();
        for (NavTaskRequest taskRequest : taskRequests) {
            taskIds.add(taskRequest.task.Id);
        }

        return new Map<Id, NavTask__c> ([SELECT Id, CRM_Comments__c, CRM_DueDate__c, CRM_Priority__c, CRM_Account__r.CRM_Person__r.INT_ActorId__c,
                        NKS_Theme__r.CRM_Code__c, NKS_Subtheme__r.CRM_Code__c, NKS_Theme_Group__c, INT_External_Reference__c FROM NavTask__c WHERE Id IN: taskIds]);
    }

    /**
    * @description: Performs a callout to Oppgave for delegating a NAV task to an external system
    * Task is updated with the external reference and the NAV unit number the task was delegated to
    * @author Stian Ruud Schikora | 11-03-2020 
    * @param task [NavTask__c]
    **/
    public static void postTask(NavTask__c task) {
        //Static context requires own instance of the API controller
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('Oppgave_API', 'POST_CREATE_OPPGAVE');
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setBody(createOppgaveJsonRequest(task));

        //Creates a log entry used as the unique request X-Correlation-ID
        LoggerUtility logger = new LoggerUtility();
        logger.info('Delegating task via Oppgave API: \n' + apiCtrl.getRequest().getBody(), task);
        apiCtrl.addHeader('X-Correlation-ID', logger.peek().UUID__c); //Adds the unique app log id to the request
        logger.publish();

        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if(statusCode == 200 || statusCode == 201) {
            OppgaveResponse resp = (OppgaveResponse) JSON.deserialize(apiCtrl.getResponse().getBody(), OppgaveResponse.class);
            task.INT_External_Reference__c = resp.id;
            task.CRM_NavUnit__r = new NavUnit__c(INT_UnitNumber__c = resp.tildeltEnhetsnr); //Setting the appropriate NAV unit received from the API
            update task;
        }
        else{
            throw new OppgaveException('Error delegating outbound NAV task: ' + apiCtrl.getResponse().getStatus());
        }
    }

    /**
    * @description: Performs callout to oppgave API to perform a patch edit of a previously
    * submitted NAV task. Throws an OppgaveException if the callout is unsuccessful
    * @author Stian Ruud Schikora | 11-15-2020 
    * @param task [NavTask__c]
    **/
    public static void patchEditTask(NavTask__c task) {
        //Static context requires own instance of the API controller
        ApiController apiCtrl = new ApiController();
        //External reference for the specific task as a URL path paramter
        Map<String, String> paramMap = new Map<String, String> {'id' => String.valueOf(task.INT_External_Reference__c)};
        apiCtrl.initRequest('Oppgave_API', 'PATCH_EDIT_OPPGAVE', paramMap);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setBody(JSON.serialize(task, true));

        //Creates a log entry used as the unique request X-Correlation-ID
        LoggerUtility logger = new LoggerUtility();
        logger.info('Delegating task via Oppgave API: \n' + apiCtrl.getRequest().getBody(), task);
        apiCtrl.addHeader('X-Correlation-ID', logger.peek().UUID__c); //Adds the unique app log id to the request
        logger.publish();

        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if(statusCode == 200 || statusCode == 201) {
            update task;
        }
        else{
            throw new OppgaveException('Error updating the NAV task: ' + apiCtrl.getResponse().getStatus());
        }
    }

    private static String createOppgaveJsonRequest(NavTask__c task) {
        return JSON.serialize(new OppgaveRequest(task), true);
    }

    public class OppgaveException extends Exception {}

    public class NavTaskRequest{

        @invocableVariable(label = 'Request type for the NAV task, valid valued are POST or EDIT' required = true)
        public String requestType;
        @invocableVariable
        public NavTask__c task;

        public NavTaskRequest(){
            this.requestType = null;
            this.task = null;
        }

        public NavTaskRequest(String requestType, NavTask__c task){
            this.requestType = requestType;
            this.task = task;
        }
    }

    //### API WRAPPERS ###//

    @testVisible
    private class OppgaveResponse{
        @testVisible
        private Long id;
        @testVisible
        private String tildeltEnhetsnr;
    }

    private class OppgaveRequest {
        private String tildeltEnhetsnr; //Enheten oppgaven er tildelt. Dersom enhet ikke er angitt, så vil oppgaven automatisk fordeles iht. standard arbeidsfordelingsregler (se norg2)
        private String opprettetAvEnhetsnr;
        private String aktoerId;
        private String journalpostId;
        private String journalpostkilde;
        private String behandlesAvApplikasjon;
        private String orgnr;
        private String tilordnetRessurs;
        private String beskrivelse;
        private String temagruppe;
        private String tema;
        private String behandlingstema;
        private String oppgavetype; // REQUIRED
        private String behandlingstype;
        private String aktivDato; //Datestring, REQUIRED 
        private String fristFerdigstillelse; //Datestring
        private String prioritet; // [HOY, NORM, LAV], Required

        //Constructor for converting a NavTask__c to a valid API oppgave request
        public OppgaveRequest(NavTask__c task) {
            fristFerdigstillelse = JSON.serialize(task.CRM_DueDate__c);
            prioritet = task.CRM_Priority__c;
            aktoerId = task.CRM_Account__r.CRM_Person__r.INT_ActorId__c;
            oppgavetype = 'DEFAULT'; //NED PICKLIST FIELD? Values are defined in kodeverk
            aktivDato = JSON.serialize(Date.today()); //WHAT SHOULD WE USE HERE?
            beskrivelse = task.CRM_Comments__c;
            temagruppe = task.NKS_Theme_Group__c;
            tema = task.NKS_Theme__r.CRM_Code__c;
            behandlingstema = task.NKS_Subtheme__r.CRM_Code__c;
        }

    }
}