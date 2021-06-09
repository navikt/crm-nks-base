global class NKS_Utbetaling implements Comparable {
    @AuraEnabled
    public Datetime posteringsdato;
    @AuraEnabled
    public NKS_Aktoer utbetaltTil;
    @AuraEnabled
    public Double utbetalingNettobeloep;
    @AuraEnabled
    public String utbetalingsmelding {
        get;
        set {
            utbetalingsmelding = String.isNotBlank(value) ? value.trim() : value;
        }
    }
    @AuraEnabled
    public List<NKS_Ytelse> ytelseListe;
    @AuraEnabled
    public Datetime utbetalingsdato;
    @AuraEnabled
    public Datetime forfallsdato;
    @AuraEnabled
    public Bankkonto utbetaltTilKonto;
    @AuraEnabled
    public String utbetalingsmetode {
        get;
        set {
            utbetalingsmetode = String.isNotBlank(value) ? value.trim() : value;
        }
    }
    @AuraEnabled
    public String utbetalingsstatus {
        get;
        set {
            utbetalingsstatus = String.isNotBlank(value) ? value.trim() : value;
        }
    }

    // Implement the compareTo() method - Newest payments first
    global Integer compareTo(Object compareTo) {
        NKS_Utbetaling compareToUtb = (NKS_Utbetaling) compareTo;
        Integer returnValue = 0;
        Datetime thisDate, compareDate;
        //Primarily sorting by the payment date, but future payment will only have a due date and/or postdate
        thisDate = utbetalingsdato != null ? utbetalingsdato : forfallsdato != null ? forfallsdato : posteringsdato;
        compareDate = compareToUtb.utbetalingsdato != null
            ? compareToUtb.utbetalingsdato
            : compareToUtb.forfallsdato != null ? compareToUtb.forfallsdato : compareToUtb.posteringsdato;

        if (thisDate > compareDate) {
            returnValue = -1;
        } else if (thisDate < compareDate) {
            returnValue = 1;
        }
        return returnValue;
    }

    global class Bankkonto {
        @AuraEnabled
        public String kontonummer {
            get;
            set {
                kontonummer = String.isNotBlank(value) ? value.trim() : value;
            }
        }
        @AuraEnabled
        public String kontotype {
            get;
            set {
                kontotype = String.isNotBlank(value) ? value.trim() : value;
            }
        }
    }
}
