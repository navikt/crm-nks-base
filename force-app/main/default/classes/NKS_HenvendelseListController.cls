public with sharing class NKS_HenvendelseListController {
    @AuraEnabled(cacheable=true)
    public static List<MessageThread> getPersonHenvendelser(String personIdent) {
        try {
            NKS_HenvendelseService service = new NKS_HenvendelseService();

            List<NKS_HenvendelseService.HENVENDELSE_TYPES> types = new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
                NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_TELEFON,
                NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG
                // NKS_HenvendelseService.SPORSMAL_SKRIFTLIG,
                // NKS_HenvendelseService.SPORSMAL_SKRIFTLIG_DIREKTE,
                // NKS_HenvendelseService.SVAR_SKRIFTLIG,
                // NKS_HenvendelseService.DELVIS_SVAR_SKRIFTLIG,
                // NKS_HenvendelseService.SPORSMAL_MODIA_UTGAAENDE,
                // NKS_HenvendelseService.SVAR_SBL_INNGAAENDE
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

                return buildMessageThreads(henvList.henvendelser);
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
        public List<Message> messageList;

        public MessageThread(NKS_Henvendelse henvendelse) {
            messageList = new List<Message>{ new Message(henvendelse) };
            threadId = henvendelse.behandlingskjedeId;
            sortMessageList();
        }

        public void addHenvendelse(NKS_Henvendelse henvendelse) {
            messageList.add(new Message(henvendelse));
            sortMessageList();
        }

        private void sortMessageList() {
            if (messageList.size() > 0) {
                messageList.sort();
                setFirstMessage(messageList[0]);
                setLastMessage(messageList[messageList.size() - 1]);
            }
        }

        private void setLastMessage(Message msg) {
            lastMessageTime = msg.opprettetDato;
            lastMessageTitle = msg.tittel;
            lastMessageSummary = msg.tekst;
            isDeleted = msg.erSlettet;
            isPartiallyAnswered = msg.erDelsvar;
        }

        private void setFirstMessage(Message msg) {
            isIncorrectlySent = msg.erMeldingFeilsendt;
            firstMessageTime = msg.opprettetDato;
        }
    }

    public class Message implements Comparable {
        @AuraEnabled
        public String aktorId;
        @AuraEnabled
        public String applikasjonsId;
        @AuraEnabled
        public Datetime avsluttetDato;
        @AuraEnabled
        public String behandlingsId;
        @AuraEnabled
        public String behandlingskjedeId;
        @AuraEnabled
        public String behandlingstema;
        @AuraEnabled
        public String brukersEnhet;
        @AuraEnabled
        public String eksternAktor;
        @AuraEnabled
        public Boolean erTilknyttetAnsatt;
        @AuraEnabled
        public Boolean ferdigstiltUtenSvar;
        @AuraEnabled
        public String fnr;
        @AuraEnabled
        public String gjeldendeTemagruppe;
        @AuraEnabled
        public String henvendelseIdGsak;
        @AuraEnabled
        public String henvendelseType;
        @AuraEnabled
        public String journalforerNavIdent;
        @AuraEnabled
        public Datetime journalfortDato;
        @AuraEnabled
        public String journalfortTema;
        @AuraEnabled
        public String journalpostId;
        @AuraEnabled
        public String kontorsperreEnhet;
        @AuraEnabled
        public String korrelasjonsId;
        @AuraEnabled
        public Datetime lestDato;
        @AuraEnabled
        public String fritekst;
        @AuraEnabled
        public String skrevetAv;
        @AuraEnabled
        public String markertSomFeilsendtAv;
        @AuraEnabled
        public String oppgaveIdGsak;
        @AuraEnabled
        public Datetime opprettetDato;
        @AuraEnabled
        public String tema;
        @AuraEnabled
        public String tilknyttetEnhet;
        @AuraEnabled
        public Boolean erMeldingFraBruker;
        @AuraEnabled
        public Boolean erMeldingFraNav;
        @AuraEnabled
        public Boolean erVarselMelding;
        @AuraEnabled
        public Boolean erMeldingSporsmal;
        @AuraEnabled
        public Boolean erJournalfort;
        @AuraEnabled
        public Boolean erMeldingFeilsendt;
        @AuraEnabled
        public Boolean erDelsvar;
        @AuraEnabled
        public Boolean erLest;
        @AuraEnabled
        public Boolean erUlest;
        @AuraEnabled
        public Boolean erSlettet;
        @AuraEnabled
        public Boolean erMeldingstypeSamtalereferat;
        @AuraEnabled
        public String tittel;
        @AuraEnabled
        public DateTime opprettetDatoFormatted;
        @AuraEnabled
        public String journalfortTekst;
        @AuraEnabled
        public String tekst;
        @AuraEnabled
        public Datetime meldingsDato;

        public Message(NKS_Henvendelse henvendelse) {
            this.aktorId = henvendelse.aktorId;
            this.applikasjonsId = henvendelse.applikasjonsId;
            this.avsluttetDato = NKS_HenvendelseUtil.stringToDateTime(henvendelse.avsluttetDato);
            this.behandlingsId = henvendelse.behandlingsId;
            this.behandlingskjedeId = henvendelse.behandlingskjedeId;
            this.behandlingstema = henvendelse.behandlingstema;
            this.brukersEnhet = henvendelse.brukersEnhet;
            this.eksternAktor = henvendelse.eksternAktor;
            this.erTilknyttetAnsatt = henvendelse.erTilknyttetAnsatt;
            this.ferdigstiltUtenSvar = henvendelse.ferdigstiltUtenSvar;
            this.fnr = henvendelse.fnr;
            this.gjeldendeTemagruppe = henvendelse.gjeldendeTemagruppe;
            this.henvendelseIdGsak = henvendelse.henvendelseIdGsak;
            this.henvendelseType = henvendelse.henvendelseType;
            if (null != henvendelse.journalfortInformasjon) {
                this.journalforerNavIdent = henvendelse.journalfortInformasjon.journalforerNavIdent;
                this.journalfortDato = NKS_HenvendelseUtil.stringToDateTime(
                    henvendelse.journalfortInformasjon.journalfortDato
                );
                this.journalfortTema = henvendelse.journalfortInformasjon.journalfortTema;
                this.journalpostId = henvendelse.journalfortInformasjon.journalpostId;
            }
            this.kontorsperreEnhet = henvendelse.kontorsperreEnhet;
            this.korrelasjonsId = henvendelse.korrelasjonsId;
            this.lestDato = NKS_HenvendelseUtil.stringToDateTime(henvendelse.lestDato);
            if (
                null != henvendelse.metadataListe &&
                null != henvendelse.metadataListe.metadata &&
                henvendelse.metadataListe.metadata.size() > 0
            ) {
                this.fritekst = henvendelse.metadataListe.metadata[0].fritekst;
                this.skrevetAv = henvendelse.metadataListe.metadata[0].navident;
            }
            this.markertSomFeilsendtAv = henvendelse.markertSomFeilsendtAv;
            this.oppgaveIdGsak = henvendelse.oppgaveIdGsak;
            this.opprettetDato = NKS_HenvendelseUtil.stringToDateTime(henvendelse.opprettetDato);
            this.tema = henvendelse.tema;
            this.tilknyttetEnhet = henvendelse.tilknyttetEnhet;

            this.erMeldingFraBruker = NKS_HenvendelseUtil.isMessageFromUser(henvendelse.henvendelseType);
            this.erMeldingFraNav = NKS_HenvendelseUtil.isMessageFromNav(henvendelse.henvendelseType);
            this.erVarselMelding = NKS_HenvendelseUtil.isNotificationMessage(henvendelse.henvendelseType);
            this.erMeldingSporsmal = NKS_HenvendelseUtil.isQuestionMessage(henvendelse.henvendelseType);
            this.erJournalfort = this.journalfortDato == null ? false : true;
            this.erMeldingFeilsendt = String.isNotBlank(henvendelse.markertSomFeilsendtAv);
            this.erDelsvar = NKS_HenvendelseUtil.isPartialyAnswered(henvendelse.henvendelseType);
            this.erLest = erMeldingFraBruker ? false : String.isNotBlank(henvendelse.lestDato);
            this.erUlest = erMeldingFraBruker ? false : String.isBlank(henvendelse.lestDato);
            this.erSlettet = String.isBlank(henvendelse.gjeldendeTemagruppe);
            this.erMeldingstypeSamtalereferat = NKS_HenvendelseUtil.isConversationNotes(henvendelse.henvendelseType);
            this.tittel = NKS_HenvendelseUtil.getMessageTitle(henvendelse);
            this.journalfortTekst = getJournalfortTekst();
        }

        private String getJournalfortTekst() {
            if (false == erJournalfort) {
                return null;
            }

            String navIdent = String.isNotBlank(journalforerNavIdent) ? journalforerNavIdent : 'ukjent';
            String journalpostDate = journalfortDato != null ? journalfortDato.format() : 'ukjent dato';
            String themeLabel = String.isNotBlank(journalforerNavIdent)
                ? NKS_HenvendelseUtil.getTemaLabel(journalfortTema)
                : 'ukjent tema';

            return 'Journalført av ' + navIdent + ' ' + journalpostDate + ' på tema ' + themeLabel;
        }

        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            Message compareToMessage = (Message) compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (opprettetDato < compareToMessage.opprettetDato) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (opprettetDato > compareToMessage.opprettetDato) {
                // Set return value to a negative value.
                returnValue = -1;
            } else if ((opprettetDato == null) && (compareToMessage.opprettetDato != null)) {
                // nulls-first implementation
                returnValue = -1;
            } else if ((opprettetDato != null) && (compareToMessage.opprettetDato == null)) {
                // nulls-first implementation
                returnValue = 1;
            }
            return returnValue;
        }
    }
}
