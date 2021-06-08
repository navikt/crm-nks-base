public without sharing class NKS_DataSynchController {
    //###########################################################//
    //###############     HENVENDELSE SYNCH    ##################//
    //###########################################################//

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
     * @description: Removes conversation note older than last year from the synch
     * @author Stian Ruud Schikora | 06-08-2021
     * @param henvList
     **/
    private static void filterHenvendelseList(List<NKS_Henvendelse> henvList) {
        Date today = Date.today();
        for (Integer i = henvList.size() - 1; i >= 0; i--) {
            if (Date.valueOf(henvList[i].opprettetDato) < today.addYears(-1) && !Test.isRunningTest()) {
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
                logger.error(
                    'One or more conversation notes failed to synch for account with ID: ' + convList[0].CRM_Account__c,
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
        if (henv.metadataListe.metadata == null || henv.metadataListe.metadata.isEmpty())
            return null;
        convNote.NKS_Incorrectly_Sent__c = henv.markeringer.feilsendt != null ? true : false;
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
}
