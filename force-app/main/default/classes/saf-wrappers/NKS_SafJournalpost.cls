public with sharing class NKS_SafJournalpost {
    @AuraEnabled public String journalpostId;
    @AuraEnabled public String tittel;
    @AuraEnabled public String journalposttype; //-> Enum Journalposttype
    @AuraEnabled public String journalstatus; //-> Enum
    @AuraEnabled public String tema; //-> Enum
    @AuraEnabled public String temaNavn;
    @AuraEnabled public String behandlingstema;
    @AuraEnabled public String behandlingstemanavn;
    @AuraEnabled public NKS_SafSak sak;
    @AuraEnabled public NKS_SafBruker bruker;
    @AuraEnabled public NKS_SafAvsenderMottaker avsenderMottaker;
    @AuraEnabled public String journalforendeEnhet;
    @AuraEnabled public String journalfortAvNavn;
    @AuraEnabled public String opprettetAvNavn;
    @AuraEnabled public String kanal; //-> Enum
    @AuraEnabled public String kanalnavn;
    @AuraEnabled public String skjerming; //-> Enum
    @AuraEnabled public String datoOpprettet; //->Datetime
    @AuraEnabled public List<NKS_SafRelevantDato> relevanteDatoer;
    @AuraEnabled public String antallRetur;
    @AuraEnabled public String eksternReferanseId;
    @AuraEnabled public List<NKS_SafTilleggsopplysning> tillegsopplysninger;
    @AuraEnabled public List<NKS_SafDokumentInfo> dokumenter;
}