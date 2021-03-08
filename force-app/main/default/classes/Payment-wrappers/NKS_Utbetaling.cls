global class NKS_Utbetaling implements Comparable {
    @AuraEnabled
    public Datetime posteringsdato;
    @AuraEnabled
    public NKS_Aktoer utbetaltTil;
    @AuraEnabled
    public Double utbetalingNettobeloep;
    @AuraEnabled
    public String utbetalingsmelding;
    @AuraEnabled
    public List<NKS_Ytelse> ytelseListe;
    @AuraEnabled
    public Datetime utbetalingsdato;
    @AuraEnabled
    public Datetime forfallsdato;
    @AuraEnabled
    public Bankkonto utbetaltTilKonto;
    @AuraEnabled
    public String utbetalingsmetode;
    @AuraEnabled
    public String utbetalingsstatus;

    // Implement the compareTo() method - Newest payments first
    global Integer compareTo(Object compareTo) {
        NKS_Utbetaling compareToUtb = (NKS_Utbetaling) compareTo;
        Integer returnValue = 0;
        if (utbetalingsdato > compareToUtb.utbetalingsdato) {
            returnValue = -1;
        } else if (utbetalingsdato < compareToUtb.utbetalingsdato) {
            returnValue = 1;
        }
        return returnValue;
    }

    global class Bankkonto {
        @AuraEnabled
        public String kontonummer;
        @AuraEnabled
        public String kontotype;
    }
}
