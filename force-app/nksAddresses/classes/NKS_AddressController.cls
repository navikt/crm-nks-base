public with sharing class NKS_AddressController {
    private static LoggerUtility logger = new LoggerUtility('NKS Address Controller');
    public class NKS_Address {
        @AuraEnabled
        public String additionalName; // not in use
        @AuraEnabled
        public String address;
        @AuraEnabled
        public String changeRegisteredDate; // not in use
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String coordinates; // not in use
        @AuraEnabled
        public String countryCode;
        @AuraEnabled
        public String fullName;
        @AuraEnabled
        public String houseNumber;
        @AuraEnabled
        public String houseLetter;
        @AuraEnabled
        public String municipalityNumber; // not in use
        @AuraEnabled
        public String recId;
        @AuraEnabled
        public String region;
        @AuraEnabled
        public String utilityUnitNumber; // not in use
        @AuraEnabled
        public String zipCode;
    }

    /*
     * @brief  Function to get Bosted Address for a person
     * @param recordId:Id
     * @param objectApiName:String
     * @return address:List<NKS_Address>
     */
    @AuraEnabled(cacheable=true)
    public static List<NKS_Address> getBostedAddress(Id recordId, String objectApiName) {
        List<NKS_Address> boAddress = new List<NKS_Address>();
        String personIdent = getPersonIdent(recordId, objectApiName);
        if (personIdent == null) {
            return boAddress;
        }
        PDL_API_Response addressData;

        try {
            addressData = queryAddressFromPDL(personIdent);
            boAddress = getAddressData(addressData);
            setValues(boAddress, personIdent);
        } catch (Exception e) {
            NKS_Address b = new NKS_Address();
            b.recId = e.getMessage();
            boAddress.add(b);
            return boAddress;
        }
        return boAddress;
    }

    /**
     * @description Function to get temporary address for a person
     * @author Sara Mohammadi | 30. June 2023
     * @param Id  recordId
     * @param String object API name
     * @return List<NKS_Address> Temporary addresses
     */
    @AuraEnabled(cacheable=true)
    public static List<NKS_Address> getTemporaryAddresses(Id recordId, String objectApiName) {
        List<NKS_Address> tempAddresses = new List<NKS_Address>();
        String personIdent = getPersonIdent(recordId, objectApiName);
        PDL_API_Response response;

        try {
            if (Test.isRunningTest()) {
                String mockResponse =
                    '{' +
                    '"errors" : null,' +
                    '"data" : {' +
                    '"hentPerson" : {' +
                    '"bostedsadresse" : [],' +
                    '"oppholdsadresse" : [ {' +
                    '"vegadresse" : {' +
                    '"tilleggsnavn" : "GRIMSTAD OppVeg",' +
                    '"postnummer" : "1211",' +
                    '"matrikkelId" : 130534011,' +
                    '"koordinater" : {' +
                    '"z" : 0.0,' +
                    '"y" : 6974511.0,' +
                    '"x" : 453529.0,' +
                    '"kvalitet" : null' +
                    '},' +
                    '"bruksenhetsnummer" : "311",' +
                    '"husnummer" : "H102",' +
                    '"husbokstav" : "b",' +
                    '"adressenavn" : "PlassOpp"' +
                    '},' +
                    '"metadata":{' +
                    '"opplysningsId":"53a9f29d-0980-42a3-8e18-13ae0b01b3d7",' +
                    '"master":"FREG",' +
                    '"endringer":[ {' +
                    '"type":"OPPRETT",' +
                    '"registrert":"2022-10-10T10:17:35",' +
                    '"registrertAv":"Folkeregisteret",' +
                    '"systemkilde":"FREG",' +
                    '"kilde":"Dolly"' +
                    '} ]' +
                    '}' +
                    '} ]' +
                    '}' +
                    '}' +
                    '}';
                response = (PDL_API_Response) System.JSON.deserialize(mockResponse, PDL_API_Response.class);
            }
            if (!Test.isRunningTest()) {
                response = queryAddressFromPDL(personIdent);
            }

            for (PDL_Oppholdsadresse oa : response.data.hentPerson.oppholdsadresse) {
                NKS_Address obj = new NKS_Address();
                if (oa.metadata?.historisk != true) {
                    if (oa?.vegadresse != null) {
                        obj.address = oa.vegadresse?.adressenavn != null
                            ? (oa.vegadresse?.adressenavn).toUpperCase()
                            : null;
                        obj.houseNumber = oa.vegadresse?.husnummer != null
                            ? (oa.vegadresse?.husnummer).toUpperCase()
                            : null;
                        obj.houseLetter = oa.vegadresse?.husbokstav != null
                            ? (oa.vegadresse?.husbokstav).toUpperCase()
                            : null;
                        obj.zipCode = oa.vegadresse?.postnummer != null ? oa.vegadresse?.postnummer : null;
                        obj.municipalityNumber = oa.vegadresse?.kommunenummer != null
                            ? oa.vegadresse?.kommunenummer
                            : null;
                        obj.coordinates = oa.vegadresse?.koordinater != null
                            ? JSON.serialize(oa.vegadresse?.koordinater)
                            : null;
                    } else if (oa?.matrikkeladresse != null) {
                        obj.zipCode = oa.matrikkeladresse?.postnummer != null ? oa.matrikkeladresse?.postnummer : null;
                        obj.municipalityNumber = oa.matrikkeladresse?.kommunenummer != null
                            ? oa.matrikkeladresse?.kommunenummer
                            : null;
                        obj.coordinates = oa.matrikkeladresse?.koordinater != null
                            ? JSON.serialize(oa.matrikkeladresse?.koordinater)
                            : null;
                    } else if (oa?.utenlandskAdresse != null) {
                        obj.address = createAddress(
                            new List<String>{
                                oa.utenlandskAdresse?.adressenavnNummer,
                                oa.utenlandskAdresse?.bygningEtasjeLeilighet,
                                oa.utenlandskAdresse?.postboksNummerNavn
                            }
                        );
                        obj.zipcode = oa.utenlandskAdresse?.postkode != null ? oa.utenlandskAdresse?.postkode : null;
                        obj.city = oa.utenlandskAdresse?.bysted != null ? oa.utenlandskAdresse?.bysted : null;
                        obj.region = oa.utenlandskAdresse?.regionDistriktOmraade != null
                            ? oa.utenlandskAdresse?.regionDistriktOmraade
                            : null;
                        obj.countryCode = oa.utenlandskAdresse?.landkode != null
                            ? oa.utenlandskAdresse?.landkode.left(3)
                            : null;
                    }
                }
                tempAddresses.add(obj);
            }
        } catch (Exception e) {
            // Catch and handle exception
            logger.error(
                'Problem getting temporary address for personIdent: ' +
                personIdent +
                '\n' +
                e.getMessage() +
                '\n' +
                e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                null
            );
        } finally {
            logger.publish();
        }
        setValues(tempAddresses, personIdent);
        return tempAddresses;
    }

    @TestVisible
    private static String getPersonIdent(Id recordId, String objectApiName) {
        Id personId;
        if (objectApiName == 'Case') {
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;
        }
        return [SELECT Id, Name FROM Person__c WHERE Id = :personId]?.Name;
    }

    @TestVisible
    private static PDL_API_Response queryAddressFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.bostedsadresse.selectAll(true);
        query.hentPerson.oppholdsadresse.selectAll(true);
        return query.execute();
    }

    @TestVisible
    private static List<NKS_Address> getAddressData(PDL_API_Response addressData) {
        List<NKS_Address> addrData = new List<NKS_Address>();
        NKS_Address boAddr = new NKS_Address();
        if (addressData.data.hentPerson.bostedsadresse.size() > 0) {
            PDL_Bostedsadresse latestAddress = getLastUpdatedBostedsAdresse(addressData.data.hentPerson.bostedsadresse);
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
        boAddr.address = 'Ikke registrert';
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
    private static List<NKS_Address> getBostedVegMatrikkAddress(PDL_Bostedsadresse address, NKS_Address boAddr) {
        List<NKS_Address> addList = new List<NKS_Address>();
        if (address?.vegadresse != null) {
            PDL_Vegadresse vegAddr = address?.vegadresse;
            boAddr.address = vegAddr?.adressenavn != null ? (vegAddr?.adressenavn).toUpperCase() : null;
            boAddr.utilityUnitNumber = vegAddr?.bruksenhetsnummer != null
                ? (vegAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            boAddr.zipCode = vegAddr?.postnummer;
            boAddr.additionalName = vegAddr?.tilleggsnavn != null ? (vegAddr?.tilleggsnavn).toUpperCase() : null;
            boAddr.houseLetter = vegAddr?.husbokstav != null ? (vegAddr?.husbokstav).toUpperCase() : null;
            boAddr.houseNumber = vegAddr?.husnummer != null ? (vegAddr?.husnummer).toUpperCase() : null;
            boAddr.recId = '1';
        } else if (address?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = address?.matrikkeladresse;
            boAddr.utilityUnitNumber = matAddr?.bruksenhetsnummer != null
                ? (matAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            boAddr.zipCode = matAddr?.postnummer;
            boAddr.additionalName = matAddr?.tilleggsnavn != null ? (matAddr?.tilleggsnavn).toUpperCase() : null;
            boAddr.recId = '2';
        }
        PDL_Metadata meta = address?.metadata;
        if (meta != null)
            boAddr.changeRegisteredDate = formatDateString(String.valueOf(getLastUpdateDate(meta).date()));
        addList.add(boAddr);
        return addList;
    }

    @TestVisible
    private static List<NKS_Address> getOppholdsAddress(PDL_Oppholdsadresse address, NKS_Address opAddr) {
        List<NKS_Address> addListOp = new List<NKS_Address>();
        if (address?.vegadresse != null) {
            PDL_Vegadresse vegAddr = address?.vegadresse;
            opAddr.address = vegAddr?.adressenavn != null ? (vegAddr?.adressenavn).toUpperCase() : null;
            opAddr.utilityUnitNumber = vegAddr?.bruksenhetsnummer != null
                ? (vegAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            opAddr.zipCode = vegAddr?.postnummer;
            opAddr.additionalName = vegAddr?.tilleggsnavn != null ? (vegAddr?.tilleggsnavn).toUpperCase() : null;
            opAddr.houseLetter = vegAddr?.husbokstav != null ? (vegAddr?.husbokstav).toUpperCase() : null;
            opAddr.houseNumber = vegAddr?.husnummer != null ? (vegAddr?.husnummer).toUpperCase() : null;
            opAddr.recId = '3';
        } else if (address?.matrikkeladresse != null) {
            PDL_Matrikkeladresse matAddr = address?.matrikkeladresse;
            opAddr.utilityUnitNumber = matAddr?.bruksenhetsnummer != null
                ? (matAddr?.bruksenhetsnummer).toUpperCase()
                : null;
            opAddr.zipCode = matAddr?.postnummer;
            opAddr.additionalName = matAddr?.tilleggsnavn != null ? (matAddr?.tilleggsnavn).toUpperCase() : null;
            opAddr.recId = '4';
        } else if (address?.utenlandskAdresse != null) {
            PDL_UtenlandskAdresse utenlandsAddr = address?.utenlandskAdresse;
            opAddr.address = utenlandsAddr?.adressenavnNummer != null
                ? (utenlandsAddr?.adressenavnNummer).toUpperCase()
                : null;
            opAddr.utilityUnitNumber = utenlandsAddr?.bygningEtasjeLeilighet != null
                ? (utenlandsAddr?.bygningEtasjeLeilighet).toUpperCase()
                : null;
            opAddr.zipCode = utenlandsAddr?.postkode;
            opAddr.city = utenlandsAddr?.bySted != null ? (utenlandsAddr?.bySted).toUpperCase() : null;
            opAddr.region = utenlandsAddr?.regionDistriktOmraade != null
                ? (utenlandsAddr?.regionDistriktOmraade).toUpperCase()
                : null;
            opAddr.countryCode = utenlandsAddr?.landkode != null ? (utenlandsAddr?.landkode).toUpperCase() : null;
            opAddr.recId = '5';
        }
        PDL_Metadata meta = address?.metadata;
        if (meta != null)
            opAddr.changeRegisteredDate = formatDateString(String.valueOf(meta?.endringer[0]?.registrert.date()));

        addListOp.add(opAddr);
        return addListOp;
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

    @TestVisible
    private static String createAddress(List<String> addressFields) {
        String addressString = '';
        for (String addressField : addressFields) {
            if (validateString(addressField) != null) {
                addressString += validateString(addressField).toUpperCase() + ' ';
            }
        }
        addressString = addressString.removeEnd(' ');
        return String.isBlank(addressString) ? null : addressString;
    }

    @TestVisible
    private static String validateString(String stringToCheck) {
        return String.isBlank(stringToCheck) ? null : stringToCheck.left(255);
    }

    @TestVisible
    private static void setValues(List<NKS_Address> addresses, String personIdent) {
        String fullName = [SELECT NKS_Full_Name__c FROM Person__c WHERE Name = :personIdent LIMIT 1]
            ?.NKS_Full_Name__c.toUpperCase();
        try {
            for (NKS_Address address : addresses) {
                address.fullName = fullName;
                String zipCode = address.zipCode;
                if (zipCode != null && address.region == null) {
                    address.city = [
                        SELECT Name
                        FROM Common_Code__c
                        WHERE CRM_Code_Set__c = 'Postnummer' AND crm_code__c = :zipCode
                        LIMIT 1
                    ]
                    ?.Name;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
