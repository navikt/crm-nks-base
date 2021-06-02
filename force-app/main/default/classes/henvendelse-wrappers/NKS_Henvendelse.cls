public class NKS_Henvendelse {
    @AuraEnabled
    public String aktorId;
    @AuraEnabled
    public String applikasjonsId;
    @AuraEnabled
    public String avsluttetDato;
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
    public NKS_JournalfortInformasjon journalfortInformasjon;
    @AuraEnabled
    public String kontorsperreEnhet;
    @AuraEnabled
    public String korrelasjonsId;
    @AuraEnabled
    public String lestDato;
    //public Markeringer markeringer;
    @AuraEnabled
    public NKS_HenvendelseMetadataListe metadataListe;
    @AuraEnabled
    public String markertSomFeilsendtAv;
    @AuraEnabled
    public String oppgaveIdGsak;
    @AuraEnabled
    public String opprettetDato;
    @AuraEnabled
    public String tema;
    @AuraEnabled
    public String tilknyttetEnhet;

    @AuraEnabled
    public Boolean erMeldingFraBruker {
        get {
            return NKS_HenvendelseUtil.isMessageFromUser(henvendelseType);
        }
    }

    @AuraEnabled
    public Boolean erMeldingFraNav {
        get {
            return NKS_HenvendelseUtil.isMessageFromNav(henvendelseType);
        }
    }

    @AuraEnabled
    public Boolean erVarselMelding {
        get {
            return NKS_HenvendelseUtil.isNotificationMessage(henvendelseType);
        }
    }

    @AuraEnabled
    public Boolean erMeldingSporsmal {
        get {
            return NKS_HenvendelseUtil.isQuestionMessage(henvendelseType);
        }
    }

    @AuraEnabled
    public Boolean erJournalfort {
        get {
            return journalfortInformasjon == null ? false : journalfortInformasjon.journalfortDato != null;
        }
    }

    @AuraEnabled
    public Boolean erMeldingFeilsendt {
        get {
            return String.isNotBlank(markertSomFeilsendtAv);
        }
    }

    @AuraEnabled
    public Boolean erDelsvar {
        get {
            return NKS_HenvendelseUtil.isPartialyAnswared(henvendelseType);
        }
    }

    @AuraEnabled
    public Boolean erLest {
        get {
            return erMeldingFraBruker ? false : String.isNotBlank(lestDato);
        }
    }

    @AuraEnabled
    public Boolean erUlest {
        get {
            return erMeldingFraBruker ? false : String.isBlank(lestDato);
        }
    }

    @AuraEnabled
    public Boolean erMeldingstypeSamtalereferat {
        get {
            return NKS_HenvendelseUtil.isConversationNotes(henvendelseType);
        }
    }

    @AuraEnabled
    public String tittel {
        get {
            return NKS_HenvendelseUtil.getMessageTitle(this);
        }
    }

    @AuraEnabled
    public DateTime opprettetDatoFormatted {
        get {
            return NKS_HenvendelseUtil.stringToDateTime(opprettetDato);
        }
    }

    @AuraEnabled
    public String journalfortText {
        get {
            if (false == erJournalfort) {
                return null;
            }

            String navIdent = String.isNotBlank(journalfortInformasjon.journalforerNavIdent)
                ? journalfortInformasjon.journalforerNavIdent
                : 'ukjent';
            String journalpostDate = String.isNotBlank(journalfortInformasjon.journalfortDato)
                ? journalfortInformasjon.journalfortDato
                : 'ukjent dato';
            String themeLabel = String.isNotBlank(journalfortInformasjon.journalforerNavIdent)
                ? NKS_HenvendelseUtil.getTemaLabel(journalfortInformasjon.journalfortTema)
                : 'ukjent tema';

            return 'Journalført av ' + navIdent + ' ' + journalpostDate + ' på tema ' + themeLabel;
        }
    }
}
