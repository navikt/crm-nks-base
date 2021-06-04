global without sharing class NKS_HenvendelseController {
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
                    respList.add(
                        henvendelseJournalInit(
                            henvReq.behandlingskjedeId,
                            henvReq.navUnitNumber,
                            henvReq.navCaseId,
                            henvReq.themeCode
                        )
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
            return '';
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
    private static String henvendelseJournalInit(
        String behandlingskjedeId,
        String navUnitNumber,
        String navCaseId,
        String themeCode
    ) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        HttpResponse resp = service.createHenvendelseJournal(behandlingskjedeId, navUnitNumber, navCaseId, themeCode);
        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            return 'OK';
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Henvendelse journal failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return 'ERROR';
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
            filterLastYear(henvList.henvendelser);
            upserConversationNotes(convertToConversationNotes(henvList.henvendelser, accountId));
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Get henvendelse list failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    private static void filterLastYear(List<NKS_Henvendelse> henvList) {
        Date today = Date.today();
        for (Integer i = henvList.size() - 1; i >= 0; i--) {
            if (Date.valueOf(henvList[i].opprettetDato) < today.addYears(-1)) {
                henvList.remove(i);
            }
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
        convNote.NKS_Date_Registered__c = Date.valueOf(henv.opprettetDato);
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
