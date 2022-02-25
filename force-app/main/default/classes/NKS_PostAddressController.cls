public with sharing class NKS_PostAddressController {
    private static final String API_CONFIG_NAME = 'Regoppslag_API';
    private static final String SERVICE_NAME = 'POST_REGOPPSLAG_API';
    private static final String SERVICE_AUTH_HEADER = 'Regoppslag';
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
        NKS_PostAddressResponse response = queryRegoppslag('123');
        PostAddress addr = new PostAddress();
        addr.navn = response.navn;
        addr.status = response.status;
        addr.type = response.adresse.type;
        addr.adresselinje1 = response.adresse.adresselinje1;
        addr.adresselinje2 = response.adresse.adresselinje2;
        addr.adresselinje3 = response.adresse.adresselinje3;
        addr.postummer = response.adresse.postnummer;
        addr.poststed = response.adresse.poststed;
        addr.landkode = response.adresse.landkode;
        addr.land = response.adresse.land;
        return addr;
    }
    public class NKS_PostAddressResponse{
        String navn;
        NKS_PostAddressAddress adresse;
        String status;
    }
    public class NKS_PostAddressAddress{
        String type;
        String adresselinje1;
        String adresselinje2;
        String adresselinje3;
        String postnummer;
        String poststed;
        String landkode;
        String land;
    }
    public static NKS_PostAddressResponse queryRegoppslag(String ident){
        String query = '{"ident": "' + ident + '","tema": "GEN"}';
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, SERVICE_NAME);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setBody(query);
        apiCtrl.doCallout();

        NKS_PostAddressResponse response = (NKS_PostAddressResponse) JSON.deserialize(apiCtrl.getResponse().getBody(), NKS_PostAddressResponse.class);
        response.status = String.valueOf(apiCtrl.getResponse().getStatusCode());
        return response;
    }
}
