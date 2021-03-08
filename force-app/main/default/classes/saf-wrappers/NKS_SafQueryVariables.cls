public with sharing class NKS_SafQueryVariables {
    @AuraEnabled public NKS_SafBrukerIdInput brukerId;
    @AuraEnabled public NKS_SafFagsakInput fagsakId;
    @AuraEnabled public String dokumentInfoId;
    @AuraEnabled public String tilknytning; // -> Enum
    @AuraEnabled public String fraDato;
    @AuraEnabled public String tilDato;
    @AuraEnabled public List<String> tema; // -> Enum
    @AuraEnabled public List<String> journalposttyper; // -> Enum
    @AuraEnabled public List<String> journalstatuser; // -> Enum
    @AuraEnabled public Integer foerste;
    @AuraEnabled public String etter;
}