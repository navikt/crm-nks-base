public with sharing class KafkaBrukernotifikasjonStatusoppdatering {
    public Long tidspunkt;
    public String fodselsnummer;
    public String grupperingsId;

    public String tekst;
    public String link;
    public Integer sikkerhetsnivaa;
    public Boolean eksternVarsling;
    public String statusGlobal;
    public String statusIntern;
    public String sakstema;

    public DateTime tidspunktFormated {
        get {
            return tidspunkt == null ? null : DateTime.newInstance(tidspunkt);
        }
        private set;
    }
}
