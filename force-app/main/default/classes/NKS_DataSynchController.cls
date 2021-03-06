public without sharing class NKS_DataSynchController {
    //###########################################################//
    //###############     HENVENDELSE SYNCH    ##################//
    //###########################################################//

    private static Map<String, Id> themeGroupMap {
        get {
            if (themeGroupMap == null) {
                themeGroupMap = new Map<String, Id>();
                for (Common_Code__c themeGroup : [
                    SELECT Id, CRM_Code__c
                    FROM Common_Code__c
                    WHERE CRM_Code_Set__c = 'Temagrupper'
                ]) {
                    themeGroupMap.put(themeGroup.CRM_Code__c, themeGroup.Id);
                }
            }
            return themeGroupMap;
        }
        set {
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
            filterHenvendelseList(henvList.henvendelser);
            upserConversationNotes(convertToConversationNotes(henvList.henvendelser, accountId));
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Get henvendelse list failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    /**
     * @description: Removes conversation note older than 2 last years from the synch
     * @author Stian Ruud Schikora | 06-08-2021
     * @param henvList
     **/
    private static void filterHenvendelseList(List<NKS_Henvendelse> henvList) {
        Date today = Date.today();
        for (Integer i = henvList.size() - 1; i >= 0; i--) {
            if (Date.valueOf(henvList[i].opprettetDato) < today.addYears(-2) && !Test.isRunningTest()) {
                henvList.remove(i);
            }
        }
    }

    /**
     * @description: Performs upsert of synched conversation notes from henvendelse.
     * Publishes application log if there are any errors.
     * @author Stian Ruud Schikora | 06-08-2021
     * @param convList
     **/
    private static void upserConversationNotes(List<Conversation_Note__c> convList) {
        LoggerUtility logger = new LoggerUtility('Henvendelse');
        List<Database.UpsertResult> upsResList = Database.upsert(
            convList,
            Conversation_Note__c.NKS_Henvendelse_BehandlingsId__c,
            false
        );
        for (Database.UpsertResult upsRes : upsResList) {
            if (!upsRes.isSuccess()) {
                //Logs one error event connected to account and breaks loop
                String errorMessage = '';
                for (Database.Error error : upsRes.getErrors()) {
                    errorMessage = error.getMessage();
                }
                logger.warning(
                    'One or more conversation notes failed to synch for account with ID: ' +
                    convList[0].CRM_Account__c +
                    '\n' +
                    'Excample error: ' +
                    errorMessage,
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
                break;
            }
        }
        logger.publish();
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

    /**
     * @description: Casts a NKS_Henvendelse wrapper to an instance of Conversation_Note__c
     * @author Stian Ruud Schikora | 06-08-2021
     * @param henv
     * @param accountId
     * @return Conversation_Note__c
     **/
    private static Conversation_Note__c convertToConversationNote(NKS_Henvendelse henv, String accountId) {
        Conversation_Note__c convNote = new Conversation_Note__c();
        convNote.CRM_Account__c = accountId;
        if (henv.metadataListe == null || henv.metadataListe.metadata == null || henv.metadataListe.metadata.isEmpty())
            return null;
        if (henv.markeringer != null) {
            convNote.NKS_Incorrectly_Sent__c = henv.markeringer.feilsendt != null ? true : false;
        }
        convNote.NKS_Theme_Group__c = themeGroupMap.containsKey(henv.gjeldendeTemagruppe)
            ? themeGroupMap.get(henv.gjeldendeTemagruppe)
            : null;
        convNote.NKS_Is_Read__c = String.isNotBlank(henv.lestDato) ? true : false;
        convNote.CRM_Conversation_Note__c = henv.metadataListe.metadata[0].fritekst;
        convNote.NKS_Created_By__c = henv.metadataListe.metadata[0].navident;
        convNote.NKS_Date_Time_Registered__c = String.isNotBlank(henv.opprettetDato)
            ? Datetime.valueOf(henv.opprettetDato.replace('T', ' '))
            : null;
        convNote.NKS_Henvendelse_BehandlingsId__c = henv.behandlingsId;
        if (henv.journalfortInformasjon != null && String.isNotBlank(henv.journalfortInformasjon.journalpostId)) {
            convNote.NKS_Journal_Status__c = 'Journal Completed';
            convNote.NKS_Theme__r = new Common_Code__c(
                CRM_UniqueKey__c = 'Tema' + henv.journalfortInformasjon.journalfortTema
            );
        }

        return convNote;
    }
}
