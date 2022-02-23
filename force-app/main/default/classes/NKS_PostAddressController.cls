public with sharing class NKS_PostAddressController {
    public class PostAddress{
        @AuraEnabled
        public String navn;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String adresselinje1;
        @AuraEnabled
        public String adresselinje2;
        @AuraEnabled
        public String adresselinje3;
        @AuraEnabled
        public String postummer;
        @AuraEnabled
        public String poststed;
        @AuraEnabled
        public String landkode;
        @AuraEnabled
        public String land;
    }
    @AuraEnabled(cacheable=true)
    public static PostAddress getPostAddress() {
        PostAddress addr = new PostAddress();
        addr.navn = 'Test Person';
        addr.status = '200';
        addr.type = 'NorskPostadresse';
        addr.adresselinje1 = 'Postboks 5 St Olavs Plass';
        addr.adresselinje2 = '';
        addr.adresselinje3 = '';
        addr.postummer = '0130';
        addr.poststed = 'OSLO';
        addr.landkode = 'NO';
        addr.land = 'Norge';
        return addr;
    }
}
