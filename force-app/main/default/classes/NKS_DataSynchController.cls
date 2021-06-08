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
}
