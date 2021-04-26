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
        public String ytelseskomponenttype {
            get;
            set {
                ytelseskomponenttype = String.isNotBlank(value) ? value.trim() : value;
            }
        }
        @AuraEnabled
        public Double satsbeloep;
        @AuraEnabled
        public String satstype {
            get;
            set {
                satstype = String.isNotBlank(value) ? value.trim() : value;
            }
        }
        @AuraEnabled
        public Double satsantall;
        @AuraEnabled
        public Double ytelseskomponentbeloep;
    }

    global class Ytelsestype {
        @AuraEnabled
        public String value {
            get;
            set {
                this.value = String.isNotBlank(value) ? value.trim() : value;
            }
        }
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
        public String trekktype {
            get;
            set {
                trekktype = String.isNotBlank(value) ? value.trim() : value;
            }
        }
        @AuraEnabled
        public Double trekkbeloep;
        @AuraEnabled
        public String kreditor {
            get;
            set {
                kreditor = String.isNotBlank(value) ? value.trim() : value;
            }
        }
    }
}
