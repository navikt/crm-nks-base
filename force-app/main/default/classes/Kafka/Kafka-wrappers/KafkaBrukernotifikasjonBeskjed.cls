public with sharing class KafkaBrukernotifikasjonBeskjed {
    public Long tidspunkt;
    public String fodselsnummer;
    public String grupperingsId;

    public Long synligFremTil;
    public String tekst;
    public String link;
    public Integer sikkerhetsnivaa;
    public Boolean eksternVarsling;

    public DateTime synligFremTilFormated {
        get {
            return synligFremTil == null ? null : DateTime.newInstance(synligFremTil);
        }
        private set;
    }

    public DateTime tidspunktFormated {
        get {
            return tidspunkt == null ? null : DateTime.newInstance(tidspunkt);
        }
        private set;
    }
}
