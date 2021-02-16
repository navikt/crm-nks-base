public class NKS_Behandlingskjede {
    @AuraEnabled
    public String behandlingskjedeId;
    @AuraEnabled
    public NKS_Kodeverk behandlingskjedetype;
    @AuraEnabled
    public NKS_Kodeverk behandlingstema; //Same data model as NKS_Kodeverk
    @AuraEnabled
    public DateTime start;
    @AuraEnabled
    public DateTime slutt;
    @AuraEnabled
    public DateTime startNAVtid;
    @AuraEnabled
    public DateTime sluttNAVtid;
    @AuraEnabled
    public String sisteBehandlingREF;
    @AuraEnabled
    public NKS_Kodeverk sisteBehandlingstype; //Same data model as NKS_Kodeverk
    @AuraEnabled
    public String sisteBehandlingsstegREF;
    @AuraEnabled
    public NKS_Kodeverk sisteBehandlingsstegtype; //Same data model as NKS_Kodeverk
    @AuraEnabled
    public NKS_Kodeverk sisteVenteaarsak; //Same data model as NKS_Kodeverk
    @AuraEnabled
    public List<String> behandlingsListeRef;
    @AuraEnabled
    public DateTime sisteBehandlingsoppdatering;
    @AuraEnabled
    public NKS_Kodeverk sisteBehandlingsstatus; //Same data model as NKS_Kodeverk
    @AuraEnabled
    public NKS_Kodeverk sisteBehandlingAvslutningsstatus; //Same data model as NKS_Kodeverk
}
