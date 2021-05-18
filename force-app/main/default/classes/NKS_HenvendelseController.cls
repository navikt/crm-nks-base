public without sharing class NKS_HenvendelseController implements IApiRetry {
    private List<Conversation_Note__c> notesToRetry = new List<Conversation_Note__c>();
    private User runningUser;

    @InvocableMethod(
        label='Henvendelse Request'
        description='Posts the created conversation note to henvendelse'
        category='Henvendelse'
    )
    public static List<String> handleHenvendelseRequest(List<HenvendelseRequest> requests) {
        List<String> respList = new List<String>();
        for (HenvendelseRequest henvReq : requests) {
            switch on henvReq.requestType {
                when 'SEND' {
                    respList.add(
                        postToHenvendelse(
                            henvReq.personIdent,
                            henvReq.navUnitNumber,
                            henvReq.themeGroupCode,
                            henvReq.content
                        )
                    );
                }
                when 'JOURNAL' {
                    henvendelseJournalInit(
                        henvReq.behandlingskjedeId,
                        henvReq.navUnitNumber,
                        henvReq.navCaseId,
                        henvReq.themeCode
                    );
                }
                when else {
                    //UNDEFINED REQUEST TYPE
                }
            }
        }
        return respList;
    }

    /**
     * @description: Posts a conversation note to henvendelse and returns the unique BehandlingsID
     * on success. Throws AuraHandledException if the request fails.
     * @author Stian Ruud Schikora | 05-13-2021
     * @param personIdent
     * @param navUnitNumber
     * @param themeGroupCode
     * @param content
     * @return String
     **/
    private static String postToHenvendelse(
        String personIdent,
        String navUnitNumber,
        String themeGroupCode,
        String content
    ) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        HttpResponse resp = service.sendHenvendelse(personIdent, navUnitNumber, themeGroupCode, content);

        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            return Test.isRunningTest() ? UTIL_TestDataFactory.generateRandomString(10) : resp.getBody();
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Henvendelse post failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            throw new AuraHandledException('Henvendelse post failed');
        }
    }

    /**
     * @description : Posts a behandlingsId for journal initiation to henvendelse
     * Throws AuraEnabledException if request status indicates post failure.
     * @author Stian Ruud Schikora | 05-13-2021
     * @param behandlingskjedeId
     * @param navUnitNumber
     * @param navCaseId
     * @param themeCode
     **/
    private static void henvendelseJournalInit(
        String behandlingskjedeId,
        String navUnitNumber,
        String navCaseId,
        String themeCode
    ) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        HttpResponse resp = service.createHenvendelseJournal(behandlingskjedeId, navUnitNumber, navCaseId, themeCode);
        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Henvendelse journal failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            throw new AuraHandledException('Henvendelse journal failed');
        }
    }

    /**
     * @description: Performs callout to henvendelse to synch conversation note data
     * @author Stian Ruud Schikora | 05-14-2021
     * @param personIdent
     * @param accountId
     **/
    @AuraEnabled
    public static void doHenvendelseSynch(String personIdent, String accountId) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();
        List<NKS_HenvendelseService.HENVENDELSE_TYPES> henvTypes = new List<NKS_HenvendelseService.HENVENDELSE_TYPES>();
        henvTypes.add(NKS_HenvendelseService.HENVENDELSE_TYPES.REFERAT_TELEFON);

        HttpResponse resp = service.getPersonHenvendelser(
            personIdent,
            henvTypes,
            NKS_HenvendelseService.HENVENDELSE_STATUSES.values()
        );
        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            NKS_HenvendelseList henvList = (NKS_HenvendelseList) JSON.deserialize(
                resp.getBody(),
                NKS_HenvendelseList.class
            );
            upserConversationNotes(convertToConversationNotes(henvList.henvendelser, accountId));
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Get henvendelse list failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    private static void upserConversationNotes(List<Conversation_Note__c> convList) {
        try {
            upsert convList NKS_Henvendelse_BehandlingsId__c;
        } catch (Exception ex) {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.exception(ex, convList[0], CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    /**
     * @description: Converts henvendelse data model into Conversation_Note__c
     * @author Stian Ruud Schikora | 05-14-2021
     * @param henvList
     * @param accountId
     * @return List<Conversation_Note__c>
     **/
    private static List<Conversation_Note__c> convertToConversationNotes(
        List<NKS_Henvendelse> henvList,
        String accountId
    ) {
        List<Conversation_Note__c> convList = new List<Conversation_Note__c>();
        for (NKS_Henvendelse henv : henvList) {
            Conversation_Note__c convertedNote = convertToConversationNote(henv, accountId);
            if (convertedNote != null)
                convList.add(convertedNote);
        }

        return convList;
    }

    private static Conversation_Note__c convertToConversationNote(NKS_Henvendelse henv, String accountId) {
        Conversation_Note__c convNote = new Conversation_Note__c();
        convNote.CRM_Account__c = accountId;
        if (henv.metadataListe.metadata == null || henv.metadataListe.metadata.isEmpty())
            return null;
        convNote.CRM_Conversation_Note__c = henv.metadataListe.metadata[0].fritekst;
        convNote.NKS_Henvendelse_BehandlingsId__c = henv.behandlingsId;
        if (henv.journalfortInformasjon != null && String.isNotBlank(henv.journalfortInformasjon.journalpostId)) {
            convNote.NKS_Journal_Status__c = 'Journal Completed';
            convNote.NKS_Theme__r = new Common_Code__c(
                CRM_UniqueKey__c = 'Tema' + henv.journalfortInformasjon.journalfortTema
            );
        } else {
            convNote.NKS_Theme__r = new Common_Code__c(CRM_UniqueKey__c = 'Tema' + henv.tema);
        }

        return convNote;
    }

    //###########################################################//
    //###############    API RETRY HANDLING    ##################//
    //###########################################################//

    /**
     * @description: Queries the failing conversation notes created/owned by the running user
     * @author Stian Ruud Schikora | 05-13-2021
     **/
    public void init() {
        this.notesToRetry = getFailedConversationNotes();
        this.runningUser = [SELECT Id, Department FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    public Boolean hasNext() {
        return this.notesToRetry != null && this.notesToRetry.size() > 0;
    }

    /**
     * @description : Returns the number of callouts needed for the next retry
     * If post and journal failed this requires two separate callouts
     * If post failed and no journal was initiated, only one callout is needed
     * @author Stian Ruud Schikora | 05-13-2021
     * @return Integer
     **/
    public Integer calloutsToConsume() {
        if (hasNext()) {
            if (this.notesToRetry[0].NKS_Sent__c == false) {
                return this.notesToRetry[0].NKS_Journal_Status__c == 'Journal Error' ? 2 : 1;
            } else {
                return this.notesToRetry[0].NKS_Journal_Status__c == 'Journal Error' ? 1 : 0;
            }
        } else {
            return 0;
        }
    }

    public void performRetry() {
        performRetry(this.notesToRetry.remove(0));
    }

    public void performRetry(Conversation_Note__c noteToRetry) {
        try {
            if (noteToRetry != null) {
                if (noteToRetry.NKS_Sent__c == false) {
                    String behandlingsId = postToHenvendelse(
                        noteToRetry.CRM_Account__r.INT_PersonIdent__c,
                        this.runningUser.Department,
                        noteToRetry.NKS_Theme_Group_Code__c,
                        noteToRetry.CRM_Conversation_Note__c
                    );
                    if (behandlingsId != null) {
                        updateCaseBehandlingsId(noteToRetry.CRM_Case__c, behandlingsId);
                    }
                    if (noteToRetry.NKS_Journal_Status__c == 'Journal Error') {
                        henvendelseJournalInit(
                            behandlingsId,
                            this.runningUser.Department,
                            noteToRetry.NKS_Legacy_Case_Id__c,
                            noteToRetry.NKS_Theme_Code__c
                        );
                        //If no exception is thrown from henvendelseJournalInit - Journal is successful
                        setJournalSuccess(noteToRetry.Id);
                    }
                } else {
                    henvendelseJournalInit(
                        noteToRetry.CRM_Case__r.NKS_Henvendelse_BehandlingsId__c,
                        this.runningUser.Department,
                        noteToRetry.NKS_Legacy_Case_Id__c,
                        noteToRetry.NKS_Theme_Code__c
                    );
                    //If no exception is thrown from henvendelseJournalInit - Journal is successful
                    setJournalSuccess(noteToRetry.Id);
                }
            }
        } catch (AuraHandledException auraEx) {
            //Aura exceptions are logged in their respective methods
        } catch (Exception ex) {
            //Pokémon catch because a failure here should NEVER affect the user
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.exception(ex, noteToRetry, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    @testVisible
    @future
    private static void setJournalSuccess(String convNoteId) {
        Conversation_Note__c noteToUpdate;

        try {
            noteToUpdate = new Conversation_Note__c(Id = convNoteId, NKS_Journal_Status__c = 'Journal Completed');
            update noteToUpdate;
        } catch (Exception ex) {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.exception(ex, noteToUpdate, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    @testVisible
    @future
    private static void updateCaseBehandlingsId(String caseId, String behandlingsId) {
        Case caseToUpdate;

        try {
            caseToUpdate = new Case(Id = caseId, NKS_Henvendelse_BehandlingsId__c = behandlingsId);
            update caseToUpdate;
        } catch (Exception ex) {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.exception(ex, caseToUpdate, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    private List<Conversation_Note__c> getFailedConversationNotes() {
        return [
            SELECT
                Id,
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
            WHERE OwnerId = :UserInfo.getUserId() AND (NKS_Sent__c = FALSE OR NKS_Journal_Status__c = 'Journal Error')
            ORDER BY Id
        ];
    }

    //###########################################################//
    //###############     WRAPPER CLASSES      ##################//
    //###########################################################//

    public class HenvendelseRequest {
        @invocableVariable(label='Request Type (SEND or JOURNAL)' required=true)
        public String requestType;
        @invocableVariable(label='Person Identifier (FNR)')
        public String personIdent;
        @invocableVariable(label='Journal NAV Unit')
        public String navUnitNumber;
        @invocableVariable(label='Theme group code')
        public String themeGroupCode;
        @invocableVariable(label='Theme code')
        public String themeCode;
        @invocableVariable(label='NAV Case ID')
        public String navCaseId;
        @invocableVariable(label='BehandlingskjedeID')
        public String behandlingskjedeId;
        @invocableVariable(label='Free text conversation note')
        public String content;

        public HenvendelseRequest() {
        }

        public HenvendelseRequest(
            String requestType,
            String personIdent,
            String navUnitNumber,
            String themeGroupCode,
            String themeCode,
            String navCaseId,
            String behandlingskjedeId,
            String content
        ) {
            this.requestType = requestType;
            this.personIdent = personIdent;
            this.navUnitNumber = navUnitNumber;
            this.themeGroupCode = themeGroupCode;
            this.themeCode = themeCode;
            this.navCaseId = navCaseId;
            this.behandlingskjedeId = behandlingskjedeId;
            this.content = content;
        }
    }
}
