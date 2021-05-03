public with sharing class KafkaBrukernotifikasjonKey {
    public String systembruker;
    public String eventId;

    public String key {
        get {
            return systembruker + eventId;
        }
        private set;
    }
}
