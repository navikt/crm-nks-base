@isTest
public with sharing class NKS_AddressControllerTest {
    @isTest
    static void testGetPersonIdent() {
        Person__c p = new Person__c(Name = '78912345687', INT_LastName__c = 'Ole', INT_FirstName__c = 'Olsen');
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = '78912345687');
        insert a;

        Test.startTest();
        String personIdent = NKS_AddressController.getPersonIdent(a.Id, 'Account');
        Test.stopTest();
        System.assertEquals('78912345687', personIdent);
    }

    @isTest
    static void getAddressTestAccount() {
        Person__c p = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestLastName',
            INT_FirstName__c = 'TestFirstname'
        );
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        Case c = new Case(AccountId = a.Id);
        insert c;

        Test.startTest();
        List<NKS_AddressController.NKS_Address> addr = NKS_AddressController.getBostedAddress(a.Id, 'Account');
        addr = NKS_AddressController.getBostedAddress(c.Id, 'Case');
        Test.stopTest();

        System.assertEquals(false, addr.isEmpty());
    }

    @isTest
    static void getBostedVegAddressTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_AddressController.NKS_Address> l = NKS_AddressController.getBostedVegMatrikkAddress(
            query.execute().data.hentPerson.bostedsadresse[0],
            new NKS_AddressController.NKS_Address()
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
        l = NKS_AddressController.getBostedVegMatrikkAddress(
            response.data.hentPerson.bostedsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('GRIMSTAD', l[0].additionalName);
        l = NKS_AddressController.getAddressData(response);
        System.assertEquals('GRIMSTAD', l[0].additionalName);

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
        l = NKS_AddressController.getBostedVegMatrikkAddress(
            response.data.hentPerson.bostedsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('1234', l[0].zipCode);

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
        l = NKS_AddressController.getOppholdsAddress(
            response.data.hentPerson.oppholdsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('1200', l[0].zipCode);

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
        l = NKS_AddressController.getOppholdsAddress(
            response.data.hentPerson.oppholdsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('GRIMSTAD OPPVEG', l[0].additionalName);

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
        l = NKS_AddressController.getOppholdsAddress(
            response.data.hentPerson.oppholdsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('1234', l[0].zipCode);
        l = NKS_AddressController.getAddressData(response);
        System.assertEquals('1234', l[0].zipCode);
    }

    @isTest
    static void testSetValues() {
        // Create test data
        Person__c p = new Person__c(Name = '12345678910', INT_FirstName__c = 'NAVN', INT_LastName__c = 'NAVNESEN');
        insert p;

        List<NKS_AddressController.NKS_Address> addresses = new List<NKS_AddressController.NKS_Address>();
        NKS_AddressController.NKS_Address address1 = new NKS_AddressController.NKS_Address();
        address1.zipCode = '1234';
        NKS_AddressController.NKS_Address address2 = new NKS_AddressController.NKS_Address();
        address2.zipCode = '5678';
        addresses.add(address1);
        addresses.add(address2);

        // Create Common_Code__c records for testing
        Common_Code__c commonCode1 = new Common_Code__c();
        commonCode1.CRM_Code_Set__c = 'Postnummer';
        commonCode1.crm_code__c = '1234';
        commonCode1.Name = 'Poststed1';
        Common_Code__c commonCode2 = new Common_Code__c();
        commonCode2.CRM_Code_Set__c = 'Postnummer';
        commonCode2.crm_code__c = '5678';
        commonCode2.Name = 'Poststed2';
        List<Common_Code__c> commonCodes = new List<Common_Code__c>{ commonCode1, commonCode2 };
        insert commonCodes;

        Test.startTest();
        // Call the method to be tested
        NKS_AddressController.setValues(addresses, '12345678910');
        Test.stopTest();

        // Verify the results
        System.assertEquals('Poststed1', addresses[0].city);
        System.assertEquals('Poststed2', addresses[1].city);
        System.assertEquals('NAVN NAVNESEN', addresses[0].fullName);
        System.assertEquals('NAVN NAVNESEN', addresses[1].fullName);
    }

    @isTest
    static void testQueryAddressFromPDL() {
        // Create test data
        Person__c p = new Person__c(Name = '12345678910', INT_FirstName__c = 'Navn', INT_LastName__c = 'Navnesen');
        insert p;

        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        Test.startTest();
        PDL_API_Response testResponse = NKS_AddressController.queryAddressFromPDL(p.Name);
        Test.stopTest();
    }

    @isTest
    static void testGetTemporaryAddress() {
        Person__c p = new Person__c(Name = '98761234567', INT_FirstName__c = 'Kari', INT_LastName__c = 'Larsen');
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = '98761234567');
        insert a;
        Case c = new Case(AccountId = a.Id);
        insert c;

        Test.startTest();
        Boolean throwsException = false;
        try {
            List<NKS_AddressController.NKS_Address> addresses1 = NKS_AddressController.getTemporaryAddresses(
                a.Id,
                'Account'
            );
            List<NKS_AddressController.NKS_Address> addresses2 = NKS_AddressController.getTemporaryAddresses(
                c.Id,
                'Case'
            );
        } catch (Exception e) {
            throwsException = true;
        }
        Test.stopTest();
        System.assertEquals(false, throwsException);
    }

    @isTest
    static void testValidateString() {
        String testString = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
        Test.startTest();
        String str = NKS_AddressController.validateString(testString);
        Test.stopTest();
    }

    @isTest
    static void testCreateAddress() {
        List<String> fieldList = new List<String>{ 'Solbakken 7e', '1111', 'Oslo' };
        Test.startTest();
        String testAddress = NKS_AddressController.createAddress(fieldList);
        Test.stopTest();
    }
}
