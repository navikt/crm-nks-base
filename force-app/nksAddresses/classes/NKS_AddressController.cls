public with sharing class NKS_AddressController {
    private static LoggerUtility logger = new LoggerUtility('NKS Address Controller');

    @AuraEnabled(cacheable=true)
    public static List<NKS_Address> getBostedAddress(Id recordId, String objectApiName) {
        Person__c person = getPersonIdentAndFullName(recordId, objectApiName);
        if (person.Name == null) {
            return new List<NKS_Address>();
        }

        List<NKS_Address> bostedAddress = new List<NKS_Address>();
        try {
            PDL_API_Response addressData = queryAddressFromPDL(person.Name);
            bostedAddress = setAddressData(addressData);
            setAddressFullNameAndCity(bostedAddress, person);
        } catch (Exception e) {
            handleException('bosted', e, person.Name);
        } finally {
            logger.publish();
        }
        return bostedAddress;
    }

    @AuraEnabled(cacheable=true)
    public static List<NKS_Address> getTemporaryAddresses(Id recordId, String objectApiName) {
        Person__c person = getPersonIdentAndFullName(recordId, objectApiName);
        List<NKS_Address> tempAddresses = new List<NKS_Address>();
        try {
            PDL_API_Response response = queryAddressFromPDL(person.Name);
            for (PDL_Oppholdsadresse oa : response.data.hentPerson.oppholdsadresse) {
                if (oa.metadata?.historisk == true) {
                    continue;
                }

                NKS_Address tempAddr = new NKS_Address();
                if (oa?.vegadresse != null) {
                    setTempAddressFieldsFromVegAdresse(oa.vegadresse, tempAddr);
                } else if (oa?.matrikkeladresse != null) {
                    setTempAddressFieldsFromMatrikkelAdresse(oa.matrikkeladresse, tempAddr);
                } else if (oa?.utenlandskAdresse != null) {
                    setTempAddressFieldsFromUtenlandskAdresse(oa.utenlandskAdresse, tempAddr);
                }
                tempAddresses.add(tempAddr);
            }
            setAddressFullNameAndCity(tempAddresses, person);
        } catch (Exception e) {
            handleException('temporary', e, person.Name);
        } finally {
            logger.publish();
        }
        return tempAddresses;
    }

    private static void setTempAddressFieldsFromVegAdresse(PDL_Vegadresse vegAddr, NKS_Address tempAddr) {
        tempAddr.address = safeUpperCase(vegAddr.adressenavn);
        tempAddr.houseNumber = safeUpperCase(vegAddr.husnummer);
        tempAddr.houseLetter = safeUpperCase(vegAddr.husbokstav);
        tempAddr.zipCode = vegAddr.postnummer;
        tempAddr.municipalityNumber = vegAddr.kommunenummer;
        tempAddr.coordinates = JSON.serialize(vegAddr.koordinater);
    }

    private static void setTempAddressFieldsFromMatrikkelAdresse(PDL_Matrikkeladresse matAddr, NKS_Address tempAddr) {
        tempAddr.zipCode = matAddr.postnummer;
        tempAddr.municipalityNumber = matAddr.kommunenummer;
        tempAddr.coordinates = JSON.serialize(matAddr.koordinater);
    }

    private static void setTempAddressFieldsFromUtenlandskAdresse(PDL_UtenlandskAdresse utenlandsAddr, NKS_Address tempAddr) {
        tempAddr.address = createAddress(new List<String>{
            utenlandsAddr.adressenavnNummer,
            utenlandsAddr.bygningEtasjeLeilighet,
            utenlandsAddr.postboksNummerNavn
        });
        tempAddr.zipCode = utenlandsAddr.postkode;
        tempAddr.city = utenlandsAddr.bysted;
        tempAddr.region = utenlandsAddr.regionDistriktOmraade;
        tempAddr.countryCode = utenlandsAddr.landkode?.left(3);
    }

    private static void handleException(String addressType, Exception e, String personIdent) {
        logger.error(
            'Problem getting ' + addressType + ' address for personIdent: ' + personIdent +
            '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
            null,
            CRM_ApplicationDomain.Domain.NKS,
            null
        );
    }

    @TestVisible
    private static Person__c getPersonIdentAndFullName(Id recordId, String objectApiName) {
        Id personId;
        if (objectApiName == 'Case') {
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;
        }
        return [SELECT Name, NKS_Full_Name__c FROM Person__c WHERE Id = :personId];
    }

    @TestVisible
    private static PDL_API_Response queryAddressFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.bostedsadresse.selectAll(true);
        query.hentPerson.oppholdsadresse.selectAll(true);
        return query.execute();
    }

    @TestVisible
    private static List<NKS_Address> setAddressData(PDL_API_Response addressData) {
        List<NKS_Address> addrData = new List<NKS_Address>();
        if (addressData.data.hentPerson.bostedsadresse.size() > 0) {
            PDL_Bostedsadresse latestAddress = setLastUpdatedBostedsAdresse(addressData.data.hentPerson.bostedsadresse);
            if (latestAddress?.vegadresse != null || latestAddress?.matrikkeladresse != null) {
                addrData.addAll(setBostedVegMatrikkAddress(latestAddress, new NKS_Address()));
                return addrData;
            }
        }
        if (addressData.data.hentPerson.oppholdsadresse.size() > 0) {
            addrData.addAll(setOppholdsAddress(setLastUpdatedOppholdsAdresse(addressData.data.hentPerson.oppholdsadresse), new NKS_Address()));
            return addrData;
        }
        NKS_Address boAddr = new NKS_Address();
        boAddr.address = 'Ikke registrert';
        addrData.add(boAddr);
        return addrData;
    }

    @TestVisible
    private static PDL_Bostedsadresse setLastUpdatedBostedsAdresse(List<PDL_Bostedsadresse> addresses) {
        PDL_Bostedsadresse latestAddress;
        for (PDL_Bostedsadresse addr : addresses) {
            if (addr.gyldigFraOgMed != null && (latestAddress == null || addr.gyldigFraOgMed > latestAddress.gyldigFraOgMed)) {
                latestAddress = addr;
            }
        }
        if (latestAddress == null) {
            for (PDL_Bostedsadresse addr : addresses) {
                if (latestAddress == null || getCreatedDate(latestAddress.metadata) < getCreatedDate(addr.metadata)) {
                    latestAddress = addr;
                }
            }
        }
        return latestAddress;
    }

    @TestVisible
    private static List<NKS_Address> setBostedVegMatrikkAddress(PDL_Bostedsadresse address, NKS_Address boAddr) {
        List<NKS_Address> addrList = new List<NKS_Address>();
        if (address?.vegadresse != null) {
            setFieldsFromVegAdresse(address.vegadresse, boAddr);
            boAddr.recId = '1';
        } else if (address?.matrikkeladresse != null) {
            setFieldsFromMatrikkelAdresse(address.matrikkeladresse, boAddr);
            boAddr.recId = '2';
        }

        PDL_Metadata meta = address?.metadata;
        if (meta != null) {
            boAddr.changeRegisteredDate = formatDateString(String.valueOf(getLastUpdateDate(meta).date()));
        }

        addrList.add(boAddr);
        return addrList;
    }

    @TestVisible
    private static List<NKS_Address> setOppholdsAddress(PDL_Oppholdsadresse address, NKS_Address opAddr) {
        List<NKS_Address> addListOp = new List<NKS_Address>();
        if (address?.vegadresse != null) {
            setFieldsFromVegAdresse(address.vegadresse, opAddr);
            opAddr.recId = '3';
        } else if (address?.matrikkeladresse != null) {
            setFieldsFromMatrikkelAdresse(address.matrikkeladresse, opAddr);
            opAddr.recId = '4';
        } else if (address?.utenlandskAdresse != null) {
            setFieldsFromUtenlandskAdresse(address.utenlandskAdresse, opAddr);
            opAddr.recId = '5';
        }
        PDL_Metadata meta = address?.metadata;
        if (meta != null) {
            opAddr.changeRegisteredDate = formatDateString(String.valueOf(meta.endringer[0]?.registrert.date()));
        }

        addListOp.add(opAddr);
        return addListOp;
    }

    private static void setFieldsFromVegAdresse(PDL_Vegadresse vegAddr, NKS_Address addr) {
        addr.address = safeUpperCase(vegAddr.adressenavn);
        addr.utilityUnitNumber = safeUpperCase(vegAddr.bruksenhetsnummer);
        addr.zipCode = vegAddr.postnummer;
        addr.additionalName = safeUpperCase(vegAddr.tilleggsnavn);
        addr.houseLetter = safeUpperCase(vegAddr.husbokstav);
        addr.houseNumber = safeUpperCase(vegAddr.husnummer);
    }

    private static void setFieldsFromMatrikkelAdresse(PDL_Matrikkeladresse matAddr, NKS_Address addr) {
        addr.utilityUnitNumber = safeUpperCase(matAddr.bruksenhetsnummer);
        addr.zipCode = matAddr.postnummer;
        addr.additionalName = safeUpperCase(matAddr.tilleggsnavn);
    }

    private static void setFieldsFromUtenlandskAdresse(PDL_UtenlandskAdresse utenlandsAddr, NKS_Address addr) {
        addr.address = safeUpperCase(utenlandsAddr.adressenavnNummer);
        addr.utilityUnitNumber = safeUpperCase(utenlandsAddr.bygningEtasjeLeilighet);
        addr.zipCode = utenlandsAddr.postkode;
        addr.city = safeUpperCase(utenlandsAddr.bySted);
        addr.region = safeUpperCase(utenlandsAddr.regionDistriktOmraade);
        addr.countryCode = safeUpperCase(utenlandsAddr.landkode);
    }

    @TestVisible
    private static PDL_Oppholdsadresse setLastUpdatedOppholdsAdresse(List<PDL_Oppholdsadresse> addresses) {
        PDL_Oppholdsadresse latestAddress;
        for (PDL_Oppholdsadresse addr : addresses) {
            if (addr.gyldigFraOgMed != null && (latestAddress == null || latestAddress.gyldigFraOgMed < addr.gyldigFraOgMed)) {
                latestAddress = addr;
            }
        }
        if (latestAddress == null) {
            for (PDL_Oppholdsadresse addr : addresses) {
                if (latestAddress == null || getCreatedDate(latestAddress.metadata) < getCreatedDate(addr.metadata)) {
                    latestAddress = addr;
                }
            }
        }
        return latestAddress;
    }

    @TestVisible
    private static void setAddressFullNameAndCity(List<NKS_Address> addresses, Person__c person) {
        if (addresses == null || person == null) {
            return;
        }
        Set<String> zipCodes = new Set<String>();
        for (NKS_Address address : addresses) {
            address.fullName = person.NKS_Full_Name__c?.toUpperCase();
            if (address.zipCode != null && address.region == null) {
                zipCodes.add(address.zipCode);
            }
        }
        if (!zipCodes.isEmpty()) {
            Map<String, Common_Code__c> zipCodeToCityMap = new Map<String, Common_Code__c>();
            for (Common_Code__c cc : [SELECT CRM_Code__c, Name FROM Common_Code__c WHERE CRM_Code_Set__c = 'Postnummer' AND CRM_Code__c IN :zipCodes]) {
                zipCodeToCityMap.put(cc.CRM_Code__c, cc);
            }
            for (NKS_Address address : addresses) {
                if (zipCodeToCityMap.containsKey(address.zipCode)) {
                    address.city = zipCodeToCityMap.get(address.zipCode).Name;
                }
            }
        }
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
            if (endring.type == PDL_Endringstype.OPPRETT && (latestUpdate == null || latestUpdate < endring.registrert)) {
                latestUpdate = endring.registrert;
            }
        }
        return latestUpdate;
    }

    @TestVisible
    private static String createAddress(List<String> addressFields) {
        List<String> validFields = new List<String>();

        for (String addressField : addressFields) {
            String validatedField = validateString(addressField);
            if (validatedField != null) {
                validFields.add(validatedField.toUpperCase());
            }
        }
        String addressString = String.join(validFields, ' ').trim();
        return String.isBlank(addressString) ? null : addressString;
    }

    /*
        UTILITY FUNCTIONS
    */

    private static String safeUpperCase(String value) {
        return value != null ? value.toUpperCase() : null;
    }

    @TestVisible
    private static String validateString(String stringToCheck) {
        return String.isBlank(stringToCheck) ? null : stringToCheck.left(255);
    }

    @TestVisible
    private static String formatDateString(String inputDate) {
        if (String.isBlank(inputDate)) {
            return null;
        }

        List<String> splitDate = inputDate.split('-');
        return String.join(new List<String>{splitDate[2], splitDate[1], splitDate[0]}, '.');
    }

    /*
        WRAPPER CLASS
    */

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
        public String recId; // not in use
        @AuraEnabled
        public String region;
        @AuraEnabled
        public String utilityUnitNumber; // not in use
        @AuraEnabled
        public String zipCode;
    }
}
