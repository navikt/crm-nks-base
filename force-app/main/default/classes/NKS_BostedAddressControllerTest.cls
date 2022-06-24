@isTest
public with sharing class NKS_BostedAddressControllerTest {
    @isTest
    private static void getAddressTestAccount() {
        Person__c p = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestLastName',
            INT_FirstName__c = 'TestFirstname'
        );
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        List<NKS_BostedAddressController.BostedAddress> addr = NKS_BostedAddressController.getBostedAddress(
            a.Id,
            'Account'
        );
        System.debug(addr);
        Case c = new Case(AccountId = a.Id);
        insert c;
        addr = NKS_BostedAddressController.getBostedAddress(c.Id, 'Case');
        System.debug(addr);
        System.assertEquals(false, addr.isEmpty());
    }

    @isTest
    private static void getBostedVegAddressTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_BostedAddressController.BostedAddress> l = NKS_BostedAddressController.getBostedVegMatrikkAddress(
            query.execute(),
            new NKS_BostedAddressController.BostedAddress()
        );
        String boVegAdd =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"bostedsadresse" : [ {' +
            '"vegadresse" : {' +
            '"tilleggsnavn" : "GRIMSTAD",' +
            '"postnummer" : "6636",' +
            '"matrikkelId" : 130534152,' +
            '"koordinater" : {' +
            '"z" : 0.0,' +
            '"y" : 6974511.0,' +
            '"x" : 453529.0,' +
            '"kvalitet" : null' +
            '},' +
            '"kommunenummer" : "1557",' +
            '"husnummer" : "H101",' +
            '"husbokstav" : "A",' +
            '"bydelsnummer" : "2435",' +
            '"bruksenhetsnummer" : "555",' +
            '"adressenavn" : "Plassavegen"' +
            '},' +
            '"metadata":{' +
            '"opplysningsId":"53a9f29d-0980-42a3-8e18-13ae0b01b3d7",' +
            '"master":"FREG",' +
            '"endringer":[ {' +
            '"type":"OPPRETT",' +
            '"registrert":"2021-09-02T10:17:35",' +
            '"registrertAv":"Folkeregisteret",' +
            '"systemkilde":"FREG",' +
            '"kilde":"Dolly"' +
            '} ]' +
            '}' +
            '} ]' +
            '}' +
            '}' +
            '}';

        PDL_API_Response response = (PDL_API_Response) System.JSON.deserialize(boVegAdd, PDL_API_Response.class);
        system.debug('response from PDL_API_Response data method from correct:::::>>' + response);
        l = NKS_BostedAddressController.getBostedVegMatrikkAddress(
            response,
            new NKS_BostedAddressController.BostedAddress()
        );
        System.assertEquals('GRIMSTAD', l[0].tilleggsnavn);
        l = NKS_BostedAddressController.getAddressData(response);
        System.assertEquals('GRIMSTAD', l[0].tilleggsnavn);

        /*boVegAdd = '{' + '"data" : {' + '"hentPerson" : {' + '"bostedsadresse" : []' + '}' + '}' + '}';
        response = (PDL_API_Response) System.JSON.deserialize(boVegAdd, PDL_API_Response.class);
        l = NKS_BostedAddressController.getBostedVegMatrikkAddress(
            response,
            new NKS_BostedAddressController.BostedAddress()
        );
        System.assertEquals(null, l[0].adressenavn);*/
        boVegAdd =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"bostedsadresse" : [ {' +
            '"matrikkeladresse" : {' +
            '"tilleggsnavn" : "GRIMSTADGata",' +
            '"postnummer" : "1234",' +
            '"matrikkelId" : 130534123,' +
            '"koordinater" : {' +
            '"z" : 0.0,' +
            '"y" : 6974511.0,' +
            '"x" : 453529.0,' +
            '"kvalitet" : null' +
            '},' +
            '"bruksenhetsnummer" : "333"' +
            '}' +
            '} ]' +
            '}' +
            '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(boVegAdd, PDL_API_Response.class);
        l = NKS_BostedAddressController.getBostedVegMatrikkAddress(
            response,
            new NKS_BostedAddressController.BostedAddress()
        );
        System.assertEquals('1234', l[0].postnummer);

        boVegAdd =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"bostedsadresse" : [],' +
            '"oppholdsadresse" : [ {' +
            '"matrikkeladresse" : {' +
            '"tilleggsnavn" : "GRIMSTADGata OppMatrikkel",' +
            '"postnummer" : "1200",' +
            '"matrikkelId" : 130534000,' +
            '"koordinater" : {' +
            '"z" : 0.0,' +
            '"y" : 6974511.0,' +
            '"x" : 453529.0,' +
            '"kvalitet" : null' +
            '},' +
            '"bruksenhetsnummer" : "303"' +
            '},' +
            '"metadata":{' +
            '"opplysningsId":"53a9f29d-0980-42a3-8e18-13ae0b01b3d7",' +
            '"master":"FREG",' +
            '"endringer":[ {' +
            '"type":"OPPRETT",' +
            '"registrert":"2021-09-02T10:17:35",' +
            '"registrertAv":"Folkeregisteret",' +
            '"systemkilde":"FREG",' +
            '"kilde":"Dolly"' +
            '} ]' +
            '}' +
            '} ]' +
            '}' +
            '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(boVegAdd, PDL_API_Response.class);
        l = NKS_BostedAddressController.getOppholdsAddress(response, new NKS_BostedAddressController.BostedAddress());
        System.assertEquals('1200', l[0].postnummer);

        boVegAdd =
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
        response = (PDL_API_Response) System.JSON.deserialize(boVegAdd, PDL_API_Response.class);
        l = NKS_BostedAddressController.getOppholdsAddress(response, new NKS_BostedAddressController.BostedAddress());
        System.assertEquals('GRIMSTAD OPPVEG', l[0].tilleggsnavn);

        boVegAdd =
            '{' +
            '"errors" : null,' +
            '"data" : {' +
            '"hentPerson" : {' +
            '"bostedsadresse" : [],' +
            '"oppholdsadresse" : [ {' +
            '"utenlandskAdresse" : {' +
            '"adressenavnNummer" : "GRIMSTAD 12",' +
            '"bygningEtasjeLeilighet" : "h 201",' +
            '"postkode" : "1234",' +
            '"bySted" : "oslo",' +
            '"regionDistriktOmraade" : "regionOpp",' +
            '"landkode" : "NO"' +
            '}' +
            '} ]' +
            '}' +
            '}' +
            '}';
        response = (PDL_API_Response) System.JSON.deserialize(boVegAdd, PDL_API_Response.class);
        l = NKS_BostedAddressController.getOppholdsAddress(response, new NKS_BostedAddressController.BostedAddress());
        System.assertEquals('1234', l[0].postnummer);
        l = NKS_BostedAddressController.getAddressData(response);
        System.assertEquals('1234', l[0].postnummer);
    }
}