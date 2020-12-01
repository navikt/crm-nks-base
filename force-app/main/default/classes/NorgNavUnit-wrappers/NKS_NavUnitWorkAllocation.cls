public with sharing class NKS_NavUnitWorkAllocation {
    @AuraEnabled public String alternateEnhetId;
    @AuraEnabled public String alternateEnhetName;
    @AuraEnabled public String alternateEnhetNr;
    @AuraEnabled public String behandlingstema;
    @AuraEnabled public String behandlingstype;
    @AuraEnabled public String diskresjonskode;
    @AuraEnabled public String enhetId;
    @AuraEnabled public String enhetNavn;
    @AuraEnabled public String enhetNr;
    @AuraEnabled public String geografiskOmraade;
    @AuraEnabled public Date gyldigFra;
    @AuraEnabled public Date gyldigTil;
    @AuraEnabled public String id;
    @AuraEnabled public String oppgavetype;
    @AuraEnabled public Boolean skalTilLokalkontor;
    @AuraEnabled public String tema;
    @AuraEnabled public String temagruppe;

    public NKS_NavUnitWorkAllocation() {
        this.alternateEnhetId = null;
        this.alternateEnhetName = null;
        this.alternateEnhetNr = null;
        this.behandlingstema = null;
        this.behandlingstype = null;
        this.diskresjonskode = null;
        this.enhetId = null;
        this.enhetNavn = null;
        this.enhetNr = null;
        this.geografiskOmraade = null;
        this.gyldigFra = null;
        this.gyldigTil = null;
        this.id = null;
        this.skalTilLokalkontor = false;
        this.tema = null;
        this.temagruppe = null;
    }
}
