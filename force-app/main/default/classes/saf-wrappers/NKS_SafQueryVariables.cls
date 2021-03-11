public with sharing class NKS_SafQueryVariables {
    @AuraEnabled
    public NKS_SafBrukerIdInput brukerId { get; set; }
    @AuraEnabled
    public NKS_SafFagsakInput fagsakId { get; set; }
    @AuraEnabled
    public String dokumentInfoId { get; set; }
    @AuraEnabled
    public String tilknytning { get; set; } // -> Enum
    @AuraEnabled
    public String fraDato { get; set; }
    @AuraEnabled
    public String tilDato { get; set; }
    @AuraEnabled
    public List<String> tema { get; set; } // -> Enum
    @AuraEnabled
    public List<String> journalposttyper { get; set; } // -> Enum
    @AuraEnabled
    public List<String> journalstatuser { get; set; } // -> Enum
    @AuraEnabled
    public string journalstatus { get; set; } //Enum
    @AuraEnabled
    public Integer foerste { get; set; }
    @AuraEnabled
    public String etter { get; set; }
}
