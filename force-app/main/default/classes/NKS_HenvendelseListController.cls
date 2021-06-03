public with sharing class NKS_HenvendelseListController {
    @AuraEnabled(cacheable=true)
    public static List<MessageThread> getPersonHenvendelser(String personIdent) {
        try {
            NKS_HenvendelseService service = new NKS_HenvendelseService();

            List<NKS_HenvendelseService.HENVENDELSE_TYPES> types = new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_TELEFON,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG
            };

            HttpResponse resp = service.getPersonHenvendelser(
                personIdent,
                types,
                NKS_HenvendelseService.HENVENDELSE_STATUSES.values()
            );

            Integer statusCode = resp.getStatusCode();
            if (statusCode == 200 || statusCode == 201) {
                NKS_HenvendelseList henvList = (NKS_HenvendelseList) JSON.deserialize(
                    resp.getBody(),
                    NKS_HenvendelseList.class
                );

                return buildMessageThreads(henvList.henvendelser); //henvList.henvendelser;
            } else {
                LoggerUtility logger = new LoggerUtility('Henvendelse');
                logger.httpError('Get henvendelse list failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
                logger.publish();
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    private static List<MessageThread> buildMessageThreads(List<NKS_Henvendelse> henvList) {
        Map<String, MessageThread> threadMap = new Map<String, MessageThread>();

        for (NKS_Henvendelse henvendelse : henvList) {
            if (threadMap.containsKey(henvendelse.behandlingskjedeId)) {
                threadMap.get(henvendelse.behandlingskjedeId).addHenvendelse(henvendelse);
            } else {
                MessageThread thread = new MessageThread(henvendelse);
                threadMap.put(thread.threadId, thread);
            }
        }

        return threadMap.values();
    }

    public class MessageThread {
        @AuraEnabled
        public String threadId;
        @AuraEnabled
        public DateTime lastMessageTime;
        @AuraEnabled
        public DateTime firstMessageTime;
        @AuraEnabled
        public String lastMessageSummary;
        @AuraEnabled
        public String lastMessageTitle;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Boolean isIncorrectlySent = false;
        @AuraEnabled
        public Boolean isDeleted = false;
        @AuraEnabled
        public Boolean isPartiallyAnswered = false;
        @AuraEnabled
        public List<NKS_Henvendelse> henvendelseList;

        public MessageThread(NKS_Henvendelse henvendelse) {
            henvendelseList = new List<NKS_Henvendelse>{ henvendelse };
            threadId = henvendelse.behandlingskjedeId;
            setFirstMessage(henvendelse);
            setLastMessage(henvendelse);
        }

        public void addHenvendelse(NKS_Henvendelse henvendelse) {
            if (henvendelse.opprettetDatoFormatted > lastMessageTime) {
                setLastMessage(henvendelse);
            }

            if (henvendelse.opprettetDatoFormatted < firstMessageTime) {
                setFirstMessage(henvendelse);
            }
            henvendelseList.add(henvendelse);
        }

        private void setLastMessage(NKS_Henvendelse henvendelse) {
            lastMessageTime = henvendelse.opprettetDatoFormatted;
            lastMessageTitle = henvendelse.tittel;
            status = '';
            lastMessageSummary = henvendelse.tekst;
            isDeleted = henvendelse.erSlettet;
            isPartiallyAnswered = henvendelse.erDelsvar;
        }

        private void setFirstMessage(NKS_Henvendelse henvendelse) {
            isIncorrectlySent = henvendelse.erMeldingFeilsendt;
            firstMessageTime = henvendelse.opprettetDatoFormatted;
        }
    }
}
