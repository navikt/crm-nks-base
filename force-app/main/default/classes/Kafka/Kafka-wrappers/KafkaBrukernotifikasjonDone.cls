public with sharing class KafkaBrukernotifikasjonDone {
    public Long tidspunkt;
    public String fodselsnummer;
    public String grupperingsId;

    public DateTime tidspunktFormated {
        get {
            return tidspunkt == null ? null : DateTime.newInstance(tidspunkt);
        }
        private set;
    }
    public KafkaBrukernotifikasjonKey key;
    public Datetime kafkaCreatedDate;
    // public KafkaBrukernotifikasjonDone() {
    //     type = BrukernotifikasjonType.DONE;
    // }
}
