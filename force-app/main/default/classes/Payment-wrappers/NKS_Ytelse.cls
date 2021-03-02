global class NKS_Ytelse {
    //public Ytelsestype ytelsestype; REF KODEVERK
    public Ytelsesperiode ytelsesperiode;
    public List<Ytelseskomponent> ytelseskomponentListe;
    public Double ytelseskomponentersum;
    public List<Trekk> trekkListe;
    public Double trekksum;
    public List<Skatt> skattListe;
    public Double skattsum;
    public Double ytelseNettobeloep;
    public String bilagsnummer;
    //public Aktoer rettighetshaver;
    //public Aktoer refundertForOrg;

    global class Ytelseskomponent {
        public String ytelseskomponenttype;
        public Double satsbeloep;
        public String satstype;
        public Double satsantall;
        public Double ytelseskomponentbeloep;
    }

    global class Ytelsesperiode {
        public date fom;
        public date tom;
    }

    global class Skatt {
        public Double skattebeloep;
    }

    global class Trekk {
        public String trekktype;
        public Double trekkbeloep;
        public String kreditor;
    }
}
