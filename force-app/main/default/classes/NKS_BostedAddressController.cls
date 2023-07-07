public with sharing class NKS_BostedAddressController {
    public class BostedAddress {
        @AuraEnabled
        public String fulltNavn;
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
        public String poststed;
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
            setValues(boAddress, personIdent);
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
            PDL_Bostedsadresse latestAddress = getLastUpdatedBostedsAdresse(addressData.data.hentPerson.bostedsadresse);
            System.debug(latestAddress);
            if (latestAddress?.vegadresse != null || latestAddress?.matrikkeladresse != null) {
                addrData.addAll(getBostedVegMatrikkAddress(latestAddress, boAddr));
                return addrData;
            }
        }
        if (addressData.data.hentPerson.oppholdsadresse.size() > 0) {
            addrData.addAll(
                getOppholdsAddress(getLastUpdatedOppholdsAdresse(addressData.data.hentPerson.oppholdsadresse), boAddr)
            );
            return addrData;
        }
        boAddr.adressenavn = 'Ikke registrert';
        addrData.add(boAddr);
        return addrData;
    }
    @TestVisible
    private static PDL_Bostedsadresse getLastUpdatedBostedsAdresse(List<PDL_Bostedsadresse> addresses) {
        PDL_Bostedsadresse latestAddress;
        for (PDL_Bostedsadresse addr : addresses) {
            if (addr.gyldigFraOgMed == null)
                continue;
            if (latestAddress == null) {
                latestAddress = addr;
            } else {
                if (latestAddress.gyldigFraOgMed >= addr.gyldigFraOgMed)
                    continue;
                latestAddress = addr;
            }
        }
        if (latestAddress != null)
            return latestAddress;

        for (PDL_Bostedsadresse addr : addresses) {
            if (latestAddress == null) {
                latestAddress = addr;
            } else {
                if (getCreatedDate(latestAddress.metadata) >= getCreatedDate(addr.metadata))
                    continue;
                latestAddress = addr;
            }
        }
        return latestAddress;
    }
    @TestVisible
    private static PDL_Oppholdsadresse getLastUpdatedOppholdsAdresse(List<PDL_Oppholdsadresse> addresses) {
        PDL_Oppholdsadresse latestAddress;
        for (PDL_Oppholdsadresse addr : addresses) {
            if (addr.gyldigFraOgMed == null)
                continue;
            if (latestAddress == null) {
                latestAddress = addr;
            } else {
                if (latestAddress.gyldigFraOgMed >= addr.gyldigFraOgMed)
                    continue;
                latestAddress = addr;
            }
        }
        if (latestAddress != null)
            return latestAddress;
        for (PDL_Oppholdsadresse addr : addresses) {
            if (latestAddress == null) {
                latestAddress = addr;
            } else {
                if (getCreatedDate(latestAddress.metadata) >= getCreatedDate(addr.metadata))
                    continue;
                latestAddress = addr;
            }
        }
        return latestAddress;
    }
    @TestVisible
    private static Datetime getCreatedDate(PDL_Metadata metadata) {
        for (PDL_Endring endring : metadata.endringer) {
            if (endring.type == PDL_Endringstype.OPPRETT)
                return endring.registrert;
        }
        return Datetime.newInstance(0, 0, 0, 0, 0, 0);
    }
    @TestVisible
    private static Datetime getLastUpdateDate(PDL_Metadata metadata) {
        Datetime latestUpdate;
        for (PDL_Endring endring : metadata.endringer) {
            if (endring.type == PDL_Endringstype.OPPRETT) {
                if (latestUpdate == null) {
                    latestUpdate = endring.registrert;
                } else {
                    if (latestUpdate < endring.registrert)
                        latestUpdate = endring.registrert;
                }
            }
        }
        return latestUpdate;
    }
    /* Help functions to get Bosted Veg or Matrikkel address */
    @TestVisible
    private static List<BostedAddress> getBostedVegMatrikkAddress(PDL_Bostedsadresse address, BostedAddress boAddr) {
        List<BostedAddress> addList = new List<BostedAddress>();
        if (address?.vegadresse != null) {
            PDL_Vegadresse vegAddr = address?.vegadresse;
            boAddr.adressenavn = vegAddr?.adressenavn != null ? (vegAddr?.adressenavn).toUpperCase() : null;
            boAddr.bruksenhetsnummer = vegAddr?.bruksenhetsnummer != null
                ? (vegAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            boAddr.postnummer = vegAddr?.postnummer;
            boAddr.tilleggsnavn = vegAddr?.tilleggsnavn != null ? (vegAddr?.tilleggsnavn).toUpperCase() : null;
            boAddr.husbokstav = vegAddr?.husbokstav != null ? (vegAddr?.husbokstav).toUpperCase() : null;
            boAddr.husnummer = vegAddr?.husnummer != null ? (vegAddr?.husnummer).toUpperCase() : null;
            boAddr.recId = '1';
        } else if (address?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = address?.matrikkeladresse;
            boAddr.bruksenhetsnummer = matAddr?.bruksenhetsnummer != null
                ? (matAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            boAddr.postnummer = matAddr?.postnummer;
            boAddr.tilleggsnavn = matAddr?.tilleggsnavn != null ? (matAddr?.tilleggsnavn).toUpperCase() : null;
            boAddr.recId = '2';
        }
        PDL_Metadata meta = address?.metadata;
        if (meta != null)
            boAddr.endringRegistrertDato = formatDateString(String.valueOf(getLastUpdateDate(meta).date()));
        addList.add(boAddr);
        return addList;
    }

    /* Help functions to get oppholds Address */
    @TestVisible
    private static List<BostedAddress> getOppholdsAddress(PDL_Oppholdsadresse address, BostedAddress opAddr) {
        List<BostedAddress> addListOp = new List<BostedAddress>();
        if (address?.vegadresse != null) {
            PDL_Vegadresse vegAddr = address?.vegadresse;
            opAddr.adressenavn = vegAddr?.adressenavn != null ? (vegAddr?.adressenavn).toUpperCase() : null;
            opAddr.bruksenhetsnummer = vegAddr?.bruksenhetsnummer != null
                ? (vegAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            opAddr.postnummer = vegAddr?.postnummer;
            opAddr.tilleggsnavn = vegAddr?.tilleggsnavn != null ? (vegAddr?.tilleggsnavn).toUpperCase() : null;
            opAddr.husbokstav = vegAddr?.husbokstav != null ? (vegAddr?.husbokstav).toUpperCase() : null;
            opAddr.husnummer = vegAddr?.husnummer != null ? (vegAddr?.husnummer).toUpperCase() : null;
            opAddr.recId = '3';
        } else if (address?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = address?.matrikkeladresse;
            opAddr.bruksenhetsnummer = matAddr?.bruksenhetsnummer != null
                ? (matAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            opAddr.postnummer = matAddr?.postnummer;
            opAddr.tilleggsnavn = matAddr?.tilleggsnavn != null ? (matAddr?.tilleggsnavn).toUpperCase() : null;
            opAddr.recId = '4';
        } else if (address?.utenlandskAdresse != null) {
            PDL_UtenlandskAdresse utenlandsAddr = address?.utenlandskAdresse;
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
        PDL_Metadata meta = address?.metadata;
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

    @Testvisible
    private static void setValues(List<BostedAddress> addresses, String personIdent) {
        String fulltNavn = [SELECT NKS_Full_Name__c FROM Person__c WHERE Name = :personIdent]
            ?.NKS_Full_Name__c.toUpperCase();
        try {
            for (BostedAddress resAddress : addresses) {
                resAddress.fulltNavn = fulltNavn;
                String postCode = resAddress.postnummer;
                if (postCode != null && postCode != '') {
                    resAddress.poststed = [
                        SELECT Name
                        FROM Common_Code__c
                        WHERE CRM_Code_Set__c = 'Postnummer' AND crm_code__c = :postCode
                    ]
                    ?.Name;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
