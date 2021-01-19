public class KafkaOppgave {
    public Integer id;
    public String tildeltEnhetsnr; //Enheten oppgaven er tildelt. Dersom enhet ikke er angitt, så vil oppgaven automatisk fordeles iht. standard arbeidsfordelingsregler (se norg2)
    public String opprettetAvEnhetsnr;
    public String aktoerId;
    public String journalpostId;
    public String journalpostkilde;
    public String behandlesAvApplikasjon;
    public String orgnr;
    public String tilordnetRessurs;
    public String beskrivelse;
    public String temagruppe;
    public String tema;
    public String behandlingstema;
    public String oppgavetype; // REQUIRED
    public String behandlingstype;
    public String aktivDato; //Datestring, REQUIRED 
    public String fristFerdigstillelse; //Datestring
    public String prioritet; // [HOY, NORM, LAV], 
    public String status; //ENUM: [OPPRETTET, AAPNET, UNDER_BEHANDLING, FERDIGSTILT, FEILREGISTRERT]
    public Integer versjon;
}