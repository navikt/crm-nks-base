public with sharing class KafkaBrukernotifikasjonOppgave {
    public Long tidspunkt;
    public String fodselsnummer;
    public String grupperingsId;

    public String tekst;
    public String link;
    public Integer sikkerhetsnivaa;
    public Boolean eksternVarsling;

    public DateTime tidspunktFormated {
        get {
            return tidspunkt == null ? null : DateTime.newInstance(tidspunkt);
        }
        private set;
    }
}
