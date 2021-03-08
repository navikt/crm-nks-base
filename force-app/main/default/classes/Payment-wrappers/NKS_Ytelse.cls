global class NKS_Ytelse {
    @AuraEnabled
    public Ytelsestype ytelsestype;
    @AuraEnabled
    public Ytelsesperiode ytelsesperiode;
    @AuraEnabled
    public List<Ytelseskomponent> ytelseskomponentListe;
    @AuraEnabled
    public Double ytelseskomponentersum;
    @AuraEnabled
    public List<Trekk> trekkListe;
    @AuraEnabled
    public Double trekksum;
    @AuraEnabled
    public List<Skatt> skattListe;
    @AuraEnabled
    public Double skattsum;
    @AuraEnabled
    public Double ytelseNettobeloep;
    @AuraEnabled
    public String bilagsnummer;
    @AuraEnabled
    public NKS_Aktoer rettighetshaver;
    @AuraEnabled
    public NKS_Aktoer refundertForOrg;

    global class Ytelseskomponent {
        @AuraEnabled
        public String ytelseskomponenttype;
        @AuraEnabled
        public Double satsbeloep;
        @AuraEnabled
        public String satstype;
        @AuraEnabled
        public Double satsantall;
        @AuraEnabled
        public Double ytelseskomponentbeloep;
    }

    global class Ytelsestype {
        @AuraEnabled
        public String value;
        public String kodeRef;
        public String kodeverksRef;
    }

    global class Ytelsesperiode {
        @AuraEnabled
        public Datetime fom;
        @AuraEnabled
        public Datetime tom;
    }

    global class Skatt {
        @AuraEnabled
        public Double skattebeloep;
    }

    global class Trekk {
        @AuraEnabled
        public String trekktype;
        @AuraEnabled
        public Double trekkbeloep;
        @AuraEnabled
        public String kreditor;
    }
}
