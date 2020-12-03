public with sharing class NKS_NavTaskManager {

    @InvocableMethod(label='Process NAV task' category='Task Handling')
    public static List<NavTaskResponse> handleNavTaskRequests(List<NavTaskRequest> taskRequests) {
        List<NavTaskResponse> responseList = new List<NavTaskResponse>();

        for (NavTaskRequest taskRequest : taskRequests) {
            switch on (taskRequest.requestType){
                when 'POST' {
                    responseList.add(postTask(taskRequest));
                }
                when 'EDIT' {
                    responseList.add(patchEditTask(taskRequest));
                }
            }
        }

        return responseList;
    }

    /**
    * @description: Performs a callout to Oppgave for delegating a NAV task to an external system
    * Task is updated with the external reference and the NAV unit number the task was delegated to
    * @author Stian Ruud Schikora | 11-03-2020 
    * @param task [NavTask__c]
    **/
    public static NavTaskResponse postTask(NavTaskRequest taskRequest) {
        NavTaskResponse resp = new NavTaskResponse();
        NavTask__c task = taskRequest.task;
        Map<String, String> httpHeaders = new Map<String, String>{'Content-Type' => 'application/json', 'accept' => 'application/json'};
        //Static context requires own instance of the API controller
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('Oppgave_API', 'POST_CREATE_OPPGAVE');
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.setBody(createOppgaveJsonRequest(taskRequest));

        //Creates a log entry used as the unique request X-Correlation-ID
        LoggerUtility logger = new LoggerUtility();
        addXCorrelation(apiCtrl, logger, task);

        try{
            apiCtrl.doCallout();
            Integer statusCode = apiCtrl.getResponse().getStatusCode();
            if(statusCode == 200 || statusCode == 201) {
                OppgaveResponse apiResp = (OppgaveResponse) JSON.deserialize(apiCtrl.getResponse().getBody(), OppgaveResponse.class);
                task.INT_External_Reference__c = apiResp.id;
                task.CRM_NavUnit__r = new NavUnit__c(INT_UnitNumber__c = apiResp.tildeltEnhetsnr); //Setting the appropriate NAV unit received from the API

                resp.setResponse(true, null, task);
            }
            else{
                logError(apiCtrl, logger, task);
                resp.setResponse(false, logger.peek().UUID__c, task);
            }
        }
        catch(Exception ex) {
            logger.exception(ex, task);
            resp.setResponse(false, logger.peek().UUID__c, task);
        }
        finally{
            logger.publish();
        }

        return resp;
    }

    
    /**
     * @description: Performs callout to oppgave API to perform a patch edit of a previously
     * submitted NAV task. Throws an OppgaveException if the callout is unsuccessful
     * @author Stian Ruud Schikora | 11-15-2020 
     * @param task [NavTask__c]
     **/
    public static NavTaskResponse patchEditTask(NavTaskRequest taskRequest) {
        NavTaskResponse resp = new NavTaskResponse();
        NavTask__c task = taskRequest.task;
        Map<String, String> httpHeaders = new Map<String, String>{'Content-Type' => 'application/json', 'accept' => 'application/json'};
        
        //Static context requires own instance of the API controller
        ApiController apiCtrl = new ApiController();
        //External reference for the specific task as a URL path paramter
        Map<String, String> paramMap = new Map<String, String> {'id' => String.valueOf(task.INT_External_Reference__c)};
        apiCtrl.initRequest('Oppgave_API', 'PATCH_EDIT_OPPGAVE', paramMap);
        apiCtrl.addServiceAuthHeader('Oppgave');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.setBody(createOppgaveJsonRequest(taskRequest));
        
        //Creates a log entry used as the unique request X-Correlation-ID
        LoggerUtility logger = new LoggerUtility();
        addXCorrelation(apiCtrl, logger, task);
        
        try{
            apiCtrl.doCallout();
            Integer statusCode = apiCtrl.getResponse().getStatusCode();
            if(statusCode == 200 || statusCode == 201) {
                resp.setResponse(true, null, task);
            }
            else{
                logError(apiCtrl, logger, task);
                resp.setResponse(false, logger.peek().UUID__c, task);
            }
        }
        catch(Exception ex){
            logger.exception(ex, task);
            resp.setResponse(false, logger.peek().UUID__c, task);
        }
        finally{
            logger.publish();
        }

        return resp;
    }

    /**
    * @description: Adds the required X-Correlation header to the API request
    * @author Stian Ruud Schikora | 11-27-2020 
    * @param apiCtrl 
    * @param logger 
    * @param task 
    **/
    private static void addXCorrelation(ApiController apiCtrl, LoggerUtility logger, NavTask__c task) {
        logger.info('Delegating task via Oppgave API: \n' + apiCtrl.getRequest().getBody(), task);
        apiCtrl.addHeader('X-Correlation-ID', logger.peek().UUID__c); //Adds the unique app log id to the request
    }

    /**
    * @description: Adds an error entry to the logger with data from the API response
    * @author Stian Ruud Schikora | 11-27-2020 
    * @param apiCtrl 
    * @param logger 
    **/
    private static void logError(ApiController apiCtrl, LoggerUtility logger, NavTask__c task) {
        logger.error('Error posting NAV task to oppgave: \n ' + 'Status: ' + String.valueOf(apiCtrl.getResponse().getStatusCode()) + '- ' + apiCtrl.getResponse().getStatus() + '\n' + 'Body: ' + apiCtrl.getResponse().getBody(), task);
        logger.peek().Payload__c = JSON.serializePretty(JSON.deserializeUntyped(apiCtrl.getRequest().getBody()));
    }
    
    /**
    * @description: Converts the NavTask to a serialized oppgave request
    * @author Stian Ruud Schikora | 11-27-2020 
    * @param task 
    * @return String 
    **/
    private static String createOppgaveJsonRequest(NavTaskRequest taskRequest) {
        return JSON.serialize(new OppgaveRequest(taskRequest), true);
    }

    //#################################################
    //#### Invocable request and response wrappers ####
    //#################################################

    public class NavTaskRequest{

        @invocableVariable(label = 'Request type for the NAV task, valid valued are POST or EDIT' required = true)
        public String requestType;
        @invocableVariable
        public NavTask__c task;
        @invocableVariable
        public String themeGroupCode;
        @invocableVariable
        public String themeCode;
        @invocableVariable
        public String subthemeCode;
        @invocableVariable
        public String actorId;
        

        public NavTaskRequest(){
            this.requestType = null;
            this.task = null;
        }

        public NavTaskRequest(String requestType, NavTask__c task){
            this.requestType = requestType;
            this.task = task;
        }
    }

    public class NavTaskResponse{
        @invocableVariable public Boolean success;
        @invocableVariable public String errorMessage;
        @invocableVariable public NavTask__c task;

        public NavTaskResponse(){
            this.success = false;
            this.errorMessage = null;
            this.task = null;
        }

        public void setResponse(Boolean success, String errorMessage, NavTask__c task){
            this.success = success;
            this.errorMessage = errorMessage;
            this.task = task;
        }

        public NavTaskResponse(Boolean success, String errorMessage, NavTask__c task) {
            this.success = success;
            this.errorMessage = errorMessage;
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
        private String prioritet; // [HOY, NORM, LAV], 
        
        public OppgaveRequest(){
            
        }

        //Constructor for converting a NavTaskRequest to a valid API oppgave request
        public OppgaveRequest(NavTaskRequest taskRequest) {
            NavTask__c task = taskRequest.task;

            DateTime dueDate = task.CRM_DueDate__c;
            fristFerdigstillelse = dueDate.format('yyyy-MM-dd');
            journalpostId = task.INT_Journal_Entry_Id__c;
            prioritet = String.valueOf(task.CRM_Priority__c); //Using String.valueOf() as there is an issue when this is passed from a flow pickslit: https://trailblazer.salesforce.com/issues_view?id=a1p3A0000003fH1QAI
            aktoerId = taskRequest.actorId;
            oppgavetype = String.valueOf(task.NKS_Task_Type__c);
            aktivDato = Datetime.now().format('yyyy-MM-dd');
            beskrivelse = task.CRM_Comments__c;
            temagruppe = taskRequest.themeGroupCode;
            tema = taskRequest.themeCode;
            behandlingstema = taskRequest.subthemeCode;
        }

    }
}