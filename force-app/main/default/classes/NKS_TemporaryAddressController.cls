public with sharing class NKS_TemporaryAddressController {
    private static LoggerUtility logger = new LoggerUtility('NKS TemporaryAddress Controller');

    public class TemporaryAddress {
        @AuraEnabled
        public String address;
        @AuraEnabled
        public String coordinates;
        @AuraEnabled
        public String countryCode;
        @AuraEnabled
        public String municipalityNumber;
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
                    if (
                        oa.vegadresse != null &&
                        (oa.vegadresse.adressenavn != null ||
                        oa.vegadresse.postnummer != null ||
                        oa.vegadresse.kommunenummer != null ||
                        oa.vegadresse.koordinater != null)
                    ) {
                        obj.address = createAddress(
                            new List<String>{
                                oa.vegadresse.adressenavn,
                                oa.vegadresse.husnummer,
                                oa.vegadresse.husbokstav
                            }
                        );
                        obj.zipCode = oa.vegadresse.postnummer;
                        obj.municipalityNumber = oa.vegadresse.kommunenummer;
                        obj.coordinates = JSON.serialize(oa.vegadresse.koordinater);
                    } else if (
                        oa.matrikkeladresse != null &&
                        (oa.matrikkeladresse.postnummer != null ||
                        oa.matrikkeladresse.kommunenummer != null ||
                        oa.matrikkeladresse.koordinater != null)
                    ) {
                        obj.zipCode = oa.matrikkeladresse.postnummer;
                        obj.municipalityNumber = oa.matrikkeladresse.kommunenummer;
                        obj.coordinates = JSON.serialize(oa.matrikkeladresse.koordinater);
                    } else if (oa.utenlandskAdresse?.landkode != null) {
                        obj.address = createAddress(
                            new List<String>{
                                oa.utenlandskAdresse.adressenavnNummer,
                                oa.utenlandskAdresse.bygningEtasjeLeilighet,
                                oa.utenlandskAdresse.postboksNummerNavn,
                                oa.utenlandskAdresse.postkode,
                                oa.utenlandskAdresse.bysted,
                                oa.utenlandskAdresse.regionDistriktOmraade
                            }
                        );
                        obj.countryCode = oa.utenlandskAdresse.landkode.left(3);
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
        return tempAddresses;
    }

    @testVisible
    private static String createAddress(List<String> addressFields) {
        String addressString = '';
        for (String addressField : addressFields) {
            if (validateString(addressField) != null) {
                addressString += validateString(addressField) + ' ';
            }
        }
        addressString = addressString.removeEnd(' ');
        return String.isBlank(addressString) ? null : addressString;
    }

    @testVisible
    private static String validateString(String stringToCheck) {
        return String.isBlank(stringToCheck) ? null : stringToCheck.left(255);
    }
}
