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

    /* Queries */
    /*@TestVisible
    private static PDL_API_Response queryOppholdsAddressFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.oppholdsadresse.selectAll(true);
        //query.hentIdenter.selectAll();
        return query.execute();
    }*/

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
        system.debug('Person Ident at start after query>>>>>>' + personIdent);
        if (personIdent == null) {
            return boAddress;
        }
        PDL_API_Response addressData;

        try {
            addressData = queryBostedAddressFromPDL(personIdent);
            boAddress = getAddressData(addressData);
            System.debug('PDL_API_Response Data::::::' + addressData);
        } catch (Exception e) {
            BostedAddress b = new BostedAddress();
            b.recId = e.getMessage();
            boAddress.add(b);
            System.debug('Inside Error message::::::' + boAddress);
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
                system.debug('Inside adress data not null from queryBostedAddressFromPDL' + addressData);
                addrData.addAll(getBostedVegMatrikkAddress(addressData, boAddr));
                return addrData;
            }
        }
        //addresssData = oppholdsAddressData;
        if (addressData.data.hentPerson.oppholdsadresse.size() > 0) {
            System.debug('Inside If from queryOppholdsAddressFromPDL' + addressData);
            addrData.addAll(getOppholdsAddress(addressData, boAddr));
            return addrData;
        }
        //BostedAddress noAddress = new BostedAddress();
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
            boAddr.adressenavn = vegAddr?.adressenavn;
            boAddr.bruksenhetsnummer = vegAddr?.bruksenhetsnummer;
            boAddr.postnummer = vegAddr?.postnummer;
            boAddr.tilleggsnavn = vegAddr?.tilleggsnavn;
            boAddr.husbokstav = vegAddr?.husbokstav;
            boAddr.husnummer = vegAddr?.husnummer;
            boAddr.recId = '1';
        }
        if (addressData.data.hentPerson.bostedsadresse[0]?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = addressData.data.hentPerson.bostedsadresse[0]?.matrikkeladresse;
            boAddr.bruksenhetsnummer = matAddr?.bruksenhetsnummer;
            boAddr.postnummer = matAddr?.postnummer;
            boAddr.tilleggsnavn = matAddr?.tilleggsnavn;
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
            opAddr.adressenavn = vegAddr?.adressenavn;
            opAddr.bruksenhetsnummer = vegAddr?.bruksenhetsnummer;
            opAddr.postnummer = vegAddr?.postnummer;
            opAddr.tilleggsnavn = vegAddr?.tilleggsnavn;
            opAddr.husbokstav = vegAddr?.husbokstav;
            opAddr.husnummer = vegAddr?.husnummer;
            opAddr.recId = '3';
        } else if (addressData.data.hentPerson.oppholdsadresse[0]?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = addressData.data.hentPerson.oppholdsadresse[0]?.matrikkeladresse;
            opAddr.bruksenhetsnummer = matAddr?.bruksenhetsnummer;
            opAddr.postnummer = matAddr?.postnummer;
            opAddr.tilleggsnavn = matAddr?.tilleggsnavn;
            opAddr.recId = '4';
        } else if (addressData.data.hentPerson.oppholdsadresse[0]?.utenlandskAdresse != null) {
            PDL_UtenlandskAdresse utenlandsAddr = addressData.data.hentPerson.oppholdsadresse[0]?.utenlandskAdresse;
            opAddr.adressenavn = utenlandsAddr?.adressenavnNummer;
            opAddr.bruksenhetsnummer = utenlandsAddr?.bygningEtasjeLeilighet;
            opAddr.postnummer = utenlandsAddr?.postkode;
            opAddr.tilleggsnavn = utenlandsAddr?.bySted;
            opAddr.region = utenlandsAddr?.regionDistriktOmraade;
            opAddr.landkode = utenlandsAddr?.landkode;
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
