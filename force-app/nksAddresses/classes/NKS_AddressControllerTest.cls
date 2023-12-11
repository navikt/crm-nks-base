@isTest
public with sharing class NKS_AddressControllerTest {
    @isTest
    static void testGetPersonIdentAndFullName() {
        Person__c p = new Person__c(Name = '78912345687', INT_LastName__c = 'Ole', INT_FirstName__c = 'Olsen');
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = '78912345687');
        insert a;

        Test.startTest();
        String personIdent = NKS_AddressController.getPersonIdentAndFullName(a.Id, 'Account')?.Name;
        Test.stopTest();
        System.assertEquals('78912345687', personIdent);
    }

    @isTest
    static void getBostedAddressTest() {
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

        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        List<List<NKS_AddressController.NKS_Address>> addr = new List<List<NKS_AddressController.NKS_Address>>();

        Test.startTest();
        addr.add(NKS_AddressController.getBostedAddress(a.Id, 'Account'));
        addr.add(NKS_AddressController.getBostedAddress(c.Id, 'Case'));
        Test.stopTest();
        
        System.assert(addr.size() == 2);
        System.assertEquals(true, addr[0][0].address != null);
        System.assertEquals(true, addr[1][0].address != null);
    }

    @isTest
    static void getOppholdsAddressTest() {
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

        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        List<List<NKS_AddressController.NKS_Address>> addr = new List<List<NKS_AddressController.NKS_Address>>();

        Test.startTest();
        addr.add(NKS_AddressController.getOppholdsAddress(a.Id, 'Account'));
        addr.add(NKS_AddressController.getOppholdsAddress(c.Id, 'Case'));
        Test.stopTest();
        
        System.assert(addr.size() == 2);
        System.assertEquals(true, addr[0][0].zipCode != null);
        System.assertEquals(true, addr[1][0].zipCode != null);
    }

    @isTest
    static void setBostedVegMatrikkAddressTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_AddressController.NKS_Address> adressList = NKS_AddressController.setBostedVegMatrikkAddress(
            query.execute().data.hentPerson.bostedsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('6636', adressList[0].zipCode);
    }

    @isTest
    static void setOppholdsAddressTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_AddressController.NKS_Address> adressList = NKS_AddressController.setOppholdsAddress(
            query.execute().data.hentPerson.oppholdsadresse[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('9511', adressList[0].zipCode);
    }

    @isTest
    static void setDeltBostedsAddressTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_QueryHelper query = new PDL_API_QueryHelper('12106519356');
        List<NKS_AddressController.NKS_Address> adressList = NKS_AddressController.setDeltBostedsAddress(
            query.execute().data.hentPerson.deltBosted[0],
            new NKS_AddressController.NKS_Address()
        );
        System.assertEquals('4636', adressList[0].zipCode);
    }


    @isTest
    static void testSetAddressFullNameAndCity() {
        // Create test data
        Person__c p = new Person__c(Name = '12345678910', INT_FirstName__c = 'NAVN', INT_LastName__c = 'NAVNESEN');
        insert p;
        p = [SELECT NKS_Full_Name__c FROM Person__c WHERE Name = '12345678910' LIMIT 1];

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
        commonCode1.CRM_Code__c = '1234';
        commonCode1.Name = 'Poststed1';
        Common_Code__c commonCode2 = new Common_Code__c();
        commonCode2.CRM_Code_Set__c = 'Postnummer';
        commonCode2.CRM_Code__c = '5678';
        commonCode2.Name = 'Poststed2';
        List<Common_Code__c> commonCodes = new List<Common_Code__c>{ commonCode1, commonCode2 };
        insert commonCodes;
       
        Test.startTest();
        // Call the method to be tested
        NKS_AddressController.setAddressFullNameAndCity(addresses, p);
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
    static void testCreateOppholdsAddressFromUtenlandskAdresse() {
        List<String> fieldList = new List<String>{ 'Solbakken 7e', '1111', 'Oslo' };
        Test.startTest();
        String testAddress = NKS_AddressController.createOppholdsAddressFromUtenlandskAdresse(fieldList);
        Test.stopTest();

        System.assertNotEquals(null, testAddress);
    }
}
