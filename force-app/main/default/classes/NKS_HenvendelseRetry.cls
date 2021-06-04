global without sharing class NKS_HenvendelseRetry implements Queueable, Database.AllowsCallouts {
    private Map<String, List<Conversation_Note__c>> retryMap = new Map<String, List<Conversation_Note__c>>();
    private List<Conversation_Note__c> processedNotes = new List<Conversation_Note__c>();
    private LoggerUtility logger = new LoggerUtility();
    List<Case> casesToUpdate = new List<Case>();

    public NKS_HenvendelseRetry(Map<String, List<Conversation_Note__c>> retryMap) {
        this.retryMap = retryMap;
    }

    public NKS_HenvendelseRetry() {
    }

    global Boolean calloutLimitDanger() {
        return Limits.getLimitCallouts() - Limits.getCallouts() < 5;
    }

    //###########################################################//
    //###############    API RETRY HANDLING    ##################//
    //###########################################################//

    /**
     * @description: Queries the failing conversation notes and initiates the retry map
     * @author Stian Ruud Schikora | 05-13-2021
     **/
    public void init() {
        getFailedConversationNotes();
    }

    global void execute(QueueableContext qc) {
        //If the retryMap is populated, call the init. Else the class is self enqueued with remaining scope
        if (this.retryMap.isEmpty())
            init();

        processRetries();

        if (!this.retryMap.isEmpty())
            enqueueSelf();

        initDml();
        logger.publish();
    }

    private void processRetries() {
        ApiController apiCtrl = new ApiController();
        for (String ownerId : this.retryMap.keySet()) {
            List<Conversation_Note__c> notesToRetry = this.retryMap.remove(ownerId);
            apiCtrl.addServiceAuthHeader('Henvendelse', ownerId); //Sets the authorization header for the owner
            while (!notesToRetry.isEmpty()) {
                if (calloutLimitDanger()) {
                    //If callout limit is close, add remaining notes to scope and re-enqueue
                    this.retryMap.put(ownerId, notesToRetry);
                    return;
                }
                //Processing
                //performRetry(notesToRetry.remove(0));
                performRetry(notesToRetry.remove(0), apiCtrl);
            }
        }
    }

    private void initDml() {
        List<Database.SaveResult> noteUpdates = Database.update(this.processedNotes, false);
        List<Database.SaveResult> caseUpdates = Database.update(this.casesToUpdate, false);

        verifyUpdateResults(noteUpdates);
        verifyUpdateResults(caseUpdates);
    }

    private void verifyUpdateResults(List<Database.SaveResult> upResList) {
        for (Database.SaveResult saveRes : upResList) {
            if (saveRes.isSuccess()) {
                //Successful update
            } else {
                for (Database.Error err : saveRes.getErrors()) {
                }
            }
        }
    }

    /**
     * @description: If i.e. callout limit is reached
     * @author Stian Ruud Schikora | 05-26-2021
     **/
    private void enqueueSelf() {
        System.enqueueJob(this);
    }

    private void performRetry(Conversation_Note__c noteToRetry, ApiController apiCtrl) {
        try {
            if (noteToRetry != null) {
                if (noteToRetry.NKS_Sent__c == false) {
                    String behandlingsId = postToHenvendelse(noteToRetry, apiCtrl);
                    if (behandlingsId != null) {
                        this.casesToUpdate.add(
                            new Case(Id = noteToRetry.CRM_Case__c, NKS_Henvendelse_BehandlingsId__c = behandlingsId)
                        );
                    }
                    if (noteToRetry.NKS_Journal_Status__c == 'Journal Error') {
                        Boolean journalSuccess = henvendelseJournalInit(
                            behandlingsId,
                            noteToRetry.NKS_Owner_Department__c,
                            noteToRetry.NKS_Legacy_Case_Id__c,
                            noteToRetry.NKS_Theme_Code__c,
                            apiCtrl
                        );
                        if (journalSuccess)
                            setJournalSuccess(noteToRetry);
                    }
                } else {
                    Boolean journalSuccess = henvendelseJournalInit(
                        noteToRetry.CRM_Case__r.NKS_Henvendelse_BehandlingsId__c,
                        noteToRetry.NKS_Owner_Department__c,
                        noteToRetry.NKS_Legacy_Case_Id__c,
                        noteToRetry.NKS_Theme_Code__c,
                        apiCtrl
                    );
                    if (journalSuccess)
                        setJournalSuccess(noteToRetry);
                }
                processedNotes.add(noteToRetry);
            }
        } catch (Exception ex) {
            LoggerUtility logger = new LoggerUtility('Henvendelse_Retry');
            logger.exception(ex, noteToRetry, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    private String postToHenvendelse(Conversation_Note__c convNote, ApiController apiCtrl) {
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };

        apiCtrl.initRequest('HENVENDELSE_API', 'POST_HENVENDELSE');
        apiCtrl.setHeaders(httpHeaders);
        addXCorrelationId('X-Correlation created for henvendelse POST', apiCtrl, this.logger);
        apiCtrl.setBody(
            JSON.serialize(
                new SendHenvendelseRequest(
                    convNote.CRM_Account__r.INT_PersonIdent__c,
                    convNote.NKS_Owner_Department__c,
                    convNote.CRM_Conversation_Note__c,
                    convNote.NKS_Theme_Group_Code__c
                )
            )
        );

        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        return statusCode == 200 || statusCode == 201 ? apiCtrl.getResponse().getBody() : null;
    }

    private Boolean henvendelseJournalInit(
        String behandlingskjedeId,
        String journalNavUnit,
        String navCaseId,
        String themeCode,
        ApiController apiCtrl
    ) {
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };

        apiCtrl.initRequest('HENVENDELSE_API', 'POST_HENVENDELSE_JOURNAL');
        apiCtrl.setHeaders(httpHeaders);
        addXCorrelationId('X-Correlation created for henvendelse journal initiation', apiCtrl, this.logger);
        apiCtrl.setBody(
            JSON.serialize(new JournalHenvendelseRequest(behandlingskjedeId, journalNavUnit, navCaseId, themeCode))
        );

        apiCtrl.doCallout();
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        return statusCode == 200 || statusCode == 201;
    }

    private void addXCorrelationId(String message, ApiController apiCtrl, LoggerUtility logger) {
        logger.info(message + '\n' + apiCtrl.getEndpoint(), null);
        apiCtrl.addHeader('X-Correlation-ID', logger.peek().UUID__c); //Adds the unique app log id to the request
    }

    /**
     * @description: Sets the journal completed status for a input conversation note
     * @author Stian Ruud Schikora | 05-26-2021
     * @param convNote
     * @return Conversation_Note__c
     **/
    private Conversation_Note__c setJournalSuccess(Conversation_Note__c convNote) {
        convNote.NKS_Journal_Status__c = 'Journal Completed';
        return convNote;
    }

    /**
     * @description: Queries failed conversation notes and initiates the retryMap
     * retryMap: [Map<String(ownerId)>, List<Conversation_Note__c>]
     * @author Stian Ruud Schikora | 05-26-2021
     **/
    private void getFailedConversationNotes() {
        List<Conversation_Note__c> failedNotes = [
            SELECT
                Id,
                OwnerId,
                NKS_Owner_Department__c,
                Name,
                CRM_Conversation_Note__c,
                NKS_Theme_Group_Code__c,
                NKS_Theme_Code__c,
                NKS_Sent__c,
                NKS_Journal_Status__c,
                NKS_Legacy_Case_Id__c,
                CRM_Account__r.INT_PersonIdent__c,
                CRM_Case__r.NKS_Henvendelse_BehandlingsId__c
            FROM Conversation_Note__c
            WHERE NKS_Sent__c = FALSE OR NKS_Journal_Status__c = 'Journal Error'
            ORDER BY OwnerId
            LIMIT 10000
        ];

        for (Conversation_Note__c convNote : failedNotes) {
            if (this.retryMap.containsKey(convNote.OwnerId)) {
                List<Conversation_Note__c> mapNotes = this.retryMap.get(convNote.OwnerId);
                mapNotes.add(convNote);
                this.retryMap.put(convNote.OwnerId, mapNotes);
            } else {
                this.retryMap.put(convNote.OwnerId, new List<Conversation_Note__c>{ convNote });
            }
        }
    }

    //###########################################################//
    //###############     WRAPPER CLASSES      ##################//
    //###########################################################//

    private class JournalHenvendelseRequest {
        String behandlingskjedeId;
        String journalforendeEnhet;
        String saksId;
        String temakode;

        private JournalHenvendelseRequest(
            String behandlingskjedeId,
            String journalforendeEnhet,
            String saksId,
            String temakode
        ) {
            this.behandlingskjedeId = behandlingskjedeId;
            this.journalforendeEnhet = journalforendeEnhet;
            this.saksId = saksId;
            this.temakode = temakode;
        }
    }

    private class SendHenvendelseRequest {
        private String fnr;
        private String enhet;
        private String fritekst;
        private String temagruppe;
        private String kanal = 'TELEFON'; //Hardkoded for temporary solution as all posts will be phone notes

        private SendHenvendelseRequest(String fnr, String enhet, String fritekst, String temagruppe) {
            this.fnr = fnr;
            this.enhet = enhet;
            this.fritekst = fritekst;
            this.temagruppe = temagruppe;
        }
    }
}
