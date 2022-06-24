public with sharing class NKS_BostedAddressController {
    public class BostedAddress {
        @AuraEnabled
        public String adressenavn;
        @AuraEnabled
        public String husnummer;
        @AuraEnabled
        public String husbokstav;
        @AuraEnabled
        public String tilleggsnavn;
        @AuraEnabled
        public String bruksenhetsnummer;
        @AuraEnabled
        public String postnummer;
        @AuraEnabled
        public String endringRegistrertDato;
        @AuraEnabled
        public String landkode;
        @AuraEnabled
        public String region;
        @AuraEnabled
        public String recId;
    }

    /* Queries */
    @TestVisible
    private static PDL_API_Response queryBostedAddressFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.bostedsadresse.selectAll(true);
        query.hentPerson.oppholdsadresse.selectAll(true);
        return query.execute();
    }

    /*
     * @brief  Function to get Bosted Address for a person
     * @param recordId:Id
     * @param objectApiName:String
     * @return address:List<BostedAddress>
     */
    @AuraEnabled(cacheable=true)
    public static List<BostedAddress> getBostedAddress(Id recordId, String objectApiName) {
        Id personId;
        if (objectApiName == 'Case') {
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;
        }

        List<BostedAddress> boAddress = new List<BostedAddress>();

        String personIdent = [SELECT Id, Name FROM Person__c WHERE Id = :personId]?.Name;
        if (personIdent == null) {
            return boAddress;
        }
        PDL_API_Response addressData;

        try {
            addressData = queryBostedAddressFromPDL(personIdent);
            boAddress = getAddressData(addressData);
        } catch (Exception e) {
            BostedAddress b = new BostedAddress();
            b.recId = e.getMessage();
            boAddress.add(b);
            return boAddress;
        }
        return boAddress;
    }

    @TestVisible
    private static List<BostedAddress> getAddressData(PDL_API_Response addressData) {
        List<BostedAddress> addrData = new List<BostedAddress>();
        BostedAddress boAddr = new BostedAddress();
        if (addressData.data.hentPerson.bostedsadresse.size() > 0) {
            if (
                addressData.data.hentPerson.bostedsadresse[0]?.vegadresse != null ||
                addressData.data.hentPerson.bostedsadresse[0]?.matrikkeladresse != null
            ) {
                addrData.addAll(getBostedVegMatrikkAddress(addressData, boAddr));
                return addrData;
            }
        }
        if (addressData.data.hentPerson.oppholdsadresse.size() > 0) {
            addrData.addAll(getOppholdsAddress(addressData, boAddr));
            return addrData;
        }
        boAddr.adressenavn = 'Ikke registrert';
        addrData.add(boAddr);
        return addrData;
    }

    /* Help functions to get Bosted Veg or Matrikkel address */
    @TestVisible
    private static List<BostedAddress> getBostedVegMatrikkAddress(PDL_API_Response addressData, BostedAddress boAddr) {
        List<BostedAddress> addList = new List<BostedAddress>();
        if (addressData.data.hentPerson.bostedsadresse[0]?.vegadresse != null) {
            PDL_Vegadresse vegAddr = addressData.data.hentPerson.bostedsadresse[0]?.vegadresse;
            boAddr.adressenavn = vegAddr?.adressenavn != null ? (vegAddr?.adressenavn).toUpperCase() : null;
            boAddr.bruksenhetsnummer = vegAddr?.bruksenhetsnummer != null
                ? (vegAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            boAddr.postnummer = vegAddr?.postnummer;
            boAddr.tilleggsnavn = vegAddr?.tilleggsnavn != null ? (vegAddr?.tilleggsnavn).toUpperCase() : null;
            boAddr.husbokstav = vegAddr?.husbokstav != null ? (vegAddr?.husbokstav).toUpperCase() : null;
            boAddr.husnummer = vegAddr?.husnummer != null ? (vegAddr?.husnummer).toUpperCase() : null;
            boAddr.recId = '1';
        }
        if (addressData.data.hentPerson.bostedsadresse[0]?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = addressData.data.hentPerson.bostedsadresse[0]?.matrikkeladresse;
            boAddr.bruksenhetsnummer = matAddr?.bruksenhetsnummer != null
                ? (matAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            boAddr.postnummer = matAddr?.postnummer;
            boAddr.tilleggsnavn = matAddr?.tilleggsnavn != null ? (matAddr?.tilleggsnavn).toUpperCase() : null;
            boAddr.recId = '2';
        }
        PDL_Metadata meta = addressData.data.hentPerson.bostedsadresse[0]?.metadata;
        if (meta != null)
            boAddr.endringRegistrertDato = formatDateString(String.valueOf(meta?.endringer[0]?.registrert.date()));
        addList.add(boAddr);
        return addList;
    }

    /* Help functions to get oppholds Address */
    @TestVisible
    private static List<BostedAddress> getOppholdsAddress(PDL_API_Response addressData, BostedAddress opAddr) {
        List<BostedAddress> addListOp = new List<BostedAddress>();
        if (addressData.data.hentPerson.oppholdsadresse[0]?.vegadresse != null) {
            PDL_Vegadresse vegAddr = addressData.data.hentPerson.oppholdsadresse[0]?.vegadresse;
            opAddr.adressenavn = vegAddr?.adressenavn != null ? (vegAddr?.adressenavn).toUpperCase() : null;
            opAddr.bruksenhetsnummer = vegAddr?.bruksenhetsnummer != null
                ? (vegAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            opAddr.postnummer = vegAddr?.postnummer;
            opAddr.tilleggsnavn = vegAddr?.tilleggsnavn != null ? (vegAddr?.tilleggsnavn).toUpperCase() : null;
            opAddr.husbokstav = vegAddr?.husbokstav != null ? (vegAddr?.husbokstav).toUpperCase() : null;
            opAddr.husnummer = vegAddr?.husnummer != null ? (vegAddr?.husnummer).toUpperCase() : null;
            opAddr.recId = '3';
        } else if (addressData.data.hentPerson.oppholdsadresse[0]?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = addressData.data.hentPerson.oppholdsadresse[0]?.matrikkeladresse;
            opAddr.bruksenhetsnummer = matAddr?.bruksenhetsnummer != null
                ? (matAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            opAddr.postnummer = matAddr?.postnummer;
            opAddr.tilleggsnavn = matAddr?.tilleggsnavn != null ? (matAddr?.tilleggsnavn).toUpperCase() : null;
            opAddr.recId = '4';
        } else if (addressData.data.hentPerson.oppholdsadresse[0]?.utenlandskAdresse != null) {
            PDL_UtenlandskAdresse utenlandsAddr = addressData.data.hentPerson.oppholdsadresse[0]?.utenlandskAdresse;
            opAddr.adressenavn = utenlandsAddr?.adressenavnNummer != null
                ? (utenlandsAddr?.adressenavnNummer).toUpperCase()
                : null;
            opAddr.bruksenhetsnummer = utenlandsAddr?.bygningEtasjeLeilighet != null
                ? (utenlandsAddr?.bygningEtasjeLeilighet).toUpperCase()
                : null;
            opAddr.postnummer = utenlandsAddr?.postkode;
            opAddr.tilleggsnavn = utenlandsAddr?.bySted != null ? (utenlandsAddr?.bySted).toUpperCase() : null;
            opAddr.region = utenlandsAddr?.regionDistriktOmraade != null
                ? (utenlandsAddr?.regionDistriktOmraade).toUpperCase()
                : null;
            opAddr.landkode = utenlandsAddr?.landkode != null ? (utenlandsAddr?.landkode).toUpperCase() : null;
            opAddr.recId = '5';
        }
        PDL_Metadata meta = addressData.data.hentPerson.oppholdsadresse[0]?.metadata;
        if (meta != null)
            opAddr.endringRegistrertDato = formatDateString(String.valueOf(meta?.endringer[0]?.registrert.date()));

        addListOp.add(opAddr);
        return addListOp;
    }

    @TestVisible
    private static String formatDateString(String d) {
        if (d != null) {
            list<String> lstSplitDate = d.split('-');
            return String.valueOf(lstSplitDate[2]) +
                '.' +
                String.valueOf(lstSplitDate[1]) +
                '.' +
                String.valueOf(lstSplitDate[0]);
        }
        return null;
    }
}
