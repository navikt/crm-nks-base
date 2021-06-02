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
        // String iconName {
        //     get {
        //         return getIconName();
        //     }
        // }
        // String iconAltText;
        // String messageType;
        @AuraEnabled
        public DateTime lastMessageTime;
        @AuraEnabled
        public String lastMessageSummary;
        @AuraEnabled
        public String lastMessageTitle;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public List<NKS_Henvendelse> henvendelseList;

        public MessageThread(NKS_Henvendelse henvendelse) {
            henvendelseList = new List<NKS_Henvendelse>{ henvendelse };
            threadId = henvendelse.behandlingskjedeId;
            // setIcon();
            setLastMessage(henvendelse);
        }

        public void addHenvendelse(NKS_Henvendelse henvendelse) {
            if (henvendelse.opprettetDatoFormatted > lastMessageTime) {
                setLastMessage(henvendelse);
            }
            henvendelseList.add(henvendelse);
        }

        private void setLastMessage(NKS_Henvendelse henvendelse) {
            lastMessageTime = DateTime.now(); // henvendelse.opprettetDatoFormatted;
            lastMessageTitle = henvendelse.tittel;
            status = '';
        }

        // private String getIconName() {
        //     switch on messageType {
        //         when 'SAMTALEREFERAT_OPPMOTE' {
        //             return 'utility:task';
        //         }
        //         when 'SAMTALEREFERAT_TELEFON' {
        //             return 'utility:call';
        //         }
        //         when 'OPPGAVE_VARSEL' {
        //             return 'utility:task';
        //         }
        //         when 'DOKUMENT_VARSEL' {
        //             return 'utility:display_text';
        //         }
        //         when else {
        //             return '';
        //         }
        //         // comments
        //         // anywhere_chat
        //     }
        // }

        // private boolean isUnanswared() {
        //     // if(henvendelseList.size() > 1) {
        //     //     return false;
        //     // }

        //     // if(!isMessageFromUser) {
        //     //     return false;
        //     // }
        //     return false;
        // }
    }
}
