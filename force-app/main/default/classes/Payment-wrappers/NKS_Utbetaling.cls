global class NKS_Utbetaling {
    @AuraEnabled
    public date posteringsdato;
    //@AuraEnabled public Aktoer utbetaltTil;
    @AuraEnabled
    public Double utbetalingNettobeloep;
    @AuraEnabled
    public String utbetalingsmelding;
    //@AuraEnabled public List<Ytelse> ytelseListe;
    @AuraEnabled
    public date utbetalingsdato;
    @AuraEnabled
    public date forfallsdato;
    //@AuraEnabled public Bankkonto utbetaltTilKonto;
    @AuraEnabled
    public String utbetalingsmetode;
    @AuraEnabled
    public String utbetalingsstatus;
}
