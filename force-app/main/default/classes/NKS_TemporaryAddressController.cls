public with sharing class NKS_TemporaryAddressController {
    private static LoggerUtility logger = new LoggerUtility('NKS TemporaryAddress Controller');

    public class TemporaryAddress {
        @AuraEnabled
        public String address;
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
        public String region;
        @AuraEnabled
        public String zipCode;
    }

    /* Query */
    @testVisible
    private static PDL_API_Response queryAddressFromPDL(String ident) {
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.oppholdsadresse.selectAll(true);
        return query.execute();
    }

    /**
     * @description Function to get temporary address for a person
     * @author Sara Mohammadi | 30. June 2023
     * @param Id  recordId
     * @param String object API name
     * @return List<TemporaryAddress> Temporary addresses
     */
    @AuraEnabled(cacheable=true)
    public static List<TemporaryAddress> getTemporaryAddresses(Id recordId, String objectApiName) {
        List<TemporaryAddress> tempAddresses = new List<TemporaryAddress>();
        Id personId;

        // get personId based on objectApiName
        if (objectApiName == 'Case') {
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId].Account.CRM_Person__c;
        } else if (objectApiName == 'Account') {
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;
        }

        String personIdent = [SELECT Id, Name FROM Person__c WHERE Id = :personId]?.Name;
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
                TemporaryAddress obj = new TemporaryAddress();
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

    @testVisible
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

    @testVisible
    private static String validateString(String stringToCheck) {
        return String.isBlank(stringToCheck) ? null : stringToCheck.left(255);
    }

    @TestVisible
    private static void setValues(List<TemporaryAddress> addresses, String personIdent) {
        String fullName = [SELECT NKS_Full_Name__c FROM Person__c WHERE Name = :personIdent LIMIT 1]
            ?.NKS_Full_Name__c.toUpperCase();
        try {
            for (TemporaryAddress tempAddress : addresses) {
                tempAddress.fullName = fullName;
                String zipCode = tempAddress.zipCode;
                if (zipCode != null && tempAddress.region == null) {
                    tempAddress.city = [
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
