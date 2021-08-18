public with sharing class NKS_HenvendelseListController {
    @AuraEnabled(cacheable=true)
    public static List<MessageThread> getPersonHenvendelser(String personIdent) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        List<NKS_HenvendelseService.HENVENDELSE_TYPES> types = new List<NKS_HenvendelseService.HENVENDELSE_TYPES>{
            NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG,
            NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG_DIREKTE,
            NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_SKRIFTLIG,
            NKS_HenvendelseService.HENVENDELSE_TYPES.DELVIS_SVAR_SKRIFTLIG,
            NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_MODIA_UTGAAENDE,
            NKS_HenvendelseService.HENVENDELSE_TYPES.SVAR_SBL_INNGAAENDE,
            NKS_HenvendelseService.HENVENDELSE_TYPES.INFOMELDING_MODIA_UTGAAENDE,
            NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG,
            NKS_HenvendelseService.HENVENDELSE_TYPES.SPORSMAL_SKRIFTLIG_DIREKTE
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
            //Filters out henvendelse with theme SER
            applyThemeFilter(henvList.henvendelser);
            return buildMessageThreads(henvList.henvendelser);
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Get henvendelse list failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();

            if (statusCode == 401) {
                throw new AuraHandledException('Feil med tilganger mot baksystem');
            } else if (statusCode == 500) {
                throw new AuraHandledException(
                    'Feil ved henting av meldinger (' +
                    'Status: ' +
                    resp.getStatus() +
                    ' Melding: ' +
                    resp.getBody() +
                    ')'
                );
            } else {
                throw new AuraHandledException('Feil ved henting av meldinger \n ' + 'Status: ' + resp.getStatus());
            }
        }
    }

    /**
     * @description: NKS-616 filterins out theme SER as full access implementation is not yet implemented
     * @author Stian Ruud Schikora | 07-06-2021
     * @param henvList
     **/
    private static void applyThemeFilter(List<NKS_Henvendelse> henvList) {
        for (Integer i = henvList.size() - 1; i >= 0; i--) {
            //Soft implementation of access control related to SER theme, as not all NKS users should have access to this
            if (
                henvList[i].tema == 'SER' ||
                (henvList[i].journalfortInformasjon != null &&
                henvList[i].journalfortInformasjon.journalfortTema == 'SER')
            ) {
                henvList.remove(i);
            }
        }
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

        List<MessageThread> threadList = threadMap.values();

        for (Integer i = threadList.size() - 1; i > 0; i--) {
            if (true == threadList[i].isDeleted || threadList[i].messageList.isEmpty()) {
                threadList.remove(i);
            }
        }

        threadList.sort();
        return threadList;
    }

    public class MessageThread implements Comparable {
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
        public String incorrectlySentText;
        @AuraEnabled
        public Boolean isDeleted = false;
        @AuraEnabled
        public Boolean isPartiallyAnswered = false;
        @AuraEnabled
        public Boolean isUnanswered = false;
        @AuraEnabled
        public Boolean isClosedWithoutAnswer = false;
        @AuraEnabled
        public String closedWithoutAnswerText;
        @AuraEnabled
        public List<Message> messageList;

        public MessageThread(NKS_Henvendelse henvendelse) {
            messageList = new List<Message>{ new Message(henvendelse) };
            threadId = henvendelse.behandlingskjedeId;
            sortMessageList();
        }

        public void addHenvendelse(NKS_Henvendelse henvendelse) {
            Message msg = new Message(henvendelse);
            if (true == msg.erSlettet) {
                return;
            }
            messageList.add(msg);
            sortMessageList();
        }

        private void sortMessageList() {
            if (messageList.size() > 0) {
                messageList.sort();

                setNewestMessage(messageList[0]);
                setOldestMessage(messageList[messageList.size() - 1]);
            }
        }

        private void setNewestMessage(Message msg) {
            lastMessageTime = msg.opprettetDato;
            lastMessageTitle = msg.tittel;
            lastMessageSummary = msg.fritekst;
            isDeleted = msg.erSlettet;
            isPartiallyAnswered = msg.erDelsvar;
            isUnanswered = setIsUnanswared(msg);
        }

        private void setOldestMessage(Message msg) {
            isIncorrectlySent = msg.erMeldingFeilsendt;
            isClosedWithoutAnswer = msg.ferdigstiltUtenSvar;
            firstMessageTime = msg.opprettetDato;

            if (true == isClosedWithoutAnswer) {
                closedWithoutAnswerText =
                    'Henvendelsen er avsluttet uten å svare bruker ' +
                    NKS_HenvendelseUtil.getDateString(msg.ferdigstiltUtenSvarDato);
            }
            if (true == isIncorrectlySent) {
                incorrectlySentText =
                    'Markert som feilsendt av ' +
                    msg.markertSomFeilsendtAv +
                    ' ' +
                    NKS_HenvendelseUtil.getDateString(msg.markertSomFeilsendtDato);
            }
        }

        private Boolean setIsUnanswared(Message msg) {
            if (messageList.size() > 1) {
                return null;
            }

            if (false == msg.erMeldingFraBruker) {
                return false;
            }

            return !msg.ferdigstiltUtenSvar;
        }

        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            MessageThread compareToThread = (MessageThread) compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (lastMessageTime < compareToThread.lastMessageTime) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (lastMessageTime > compareToThread.lastMessageTime) {
                // Set return value to a negative value.
                returnValue = -1;
            } else if ((lastMessageTime == null) && (compareToThread.lastMessageTime != null)) {
                // nulls-first implementation
                returnValue = -1;
            } else if ((lastMessageTime != null) && (compareToThread.lastMessageTime == null)) {
                // nulls-first implementation
                returnValue = 1;
            }
            return returnValue;
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
        public Boolean erTilknyttetAnsatt = false;
        @AuraEnabled
        public Boolean ferdigstiltUtenSvar = false;
        @AuraEnabled
        public DateTime ferdigstiltUtenSvarDato;
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
        public Datetime markertSomFeilsendtDato;
        @AuraEnabled
        public String oppgaveIdGsak;
        @AuraEnabled
        public Datetime opprettetDato;
        @AuraEnabled
        public String tema;
        @AuraEnabled
        public String tilknyttetEnhet;
        @AuraEnabled
        public Boolean erMeldingFraBruker = false;
        @AuraEnabled
        public Boolean erMeldingFraNav = false;
        @AuraEnabled
        public Boolean erVarselMelding = false;
        @AuraEnabled
        public Boolean erMeldingSporsmal = false;
        @AuraEnabled
        public Boolean erJournalfort = false;
        @AuraEnabled
        public Boolean erMeldingFeilsendt = false;
        @AuraEnabled
        public Boolean erDelsvar = false;
        @AuraEnabled
        public Boolean erLest = false;
        @AuraEnabled
        public Boolean erUlest = false;
        @AuraEnabled
        public Boolean erSlettet = false;
        @AuraEnabled
        public Boolean erMeldingstypeSamtalereferat = false;
        @AuraEnabled
        public String tittel;
        @AuraEnabled
        public DateTime opprettetDatoFormatted;
        @AuraEnabled
        public String journalfortTekst;
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
            if (true == this.ferdigstiltUtenSvar && null != henvendelse.markeringer.ferdigstiltUtenSvar) {
                this.ferdigstiltUtenSvarDato = NKS_HenvendelseUtil.stringToDateTime(
                    henvendelse.markeringer.ferdigstiltUtenSvar.dato
                );
            }
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

            if (true == this.erMeldingFeilsendt && null != henvendelse.markeringer.feilsendt) {
                this.markertSomFeilsendtDato = NKS_HenvendelseUtil.stringToDateTime(
                    henvendelse.markeringer.feilsendt.dato
                );
            }

            this.erDelsvar = NKS_HenvendelseUtil.isPartialyAnswered(henvendelse.henvendelseType);
            this.erLest = erMeldingFraBruker ? false : String.isNotBlank(henvendelse.lestDato);
            this.erUlest = erMeldingFraBruker ? false : String.isBlank(henvendelse.lestDato);
            this.erSlettet = String.isBlank(henvendelse.gjeldendeTemagruppe) || henvendelse.metadataListe == null;
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
