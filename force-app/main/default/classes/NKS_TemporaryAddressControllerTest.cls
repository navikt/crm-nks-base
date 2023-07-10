@isTest
public with sharing class NKS_TemporaryAddressControllerTest {
    @TestSetup
    static void makeData() {
        Person__c p = new Person__c(Name = '12345678910', INT_FirstName__c = 'Navn', INT_LastName__c = 'Navnesen');
        insert p;

        Account a = new Account(CRM_Person__c = p.Id, Name = '12345678910');
        insert a;

        Case c = new Case(AccountId = a.Id);
        insert c;
    }

    @isTest
    static void testQueryAddressFromPDL() {
        string name = [SELECT Name FROM Person__c LIMIT 1]?.Name;
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        Test.startTest();
        PDL_API_Response testResponse = NKS_TemporaryAddressController.queryAddressFromPDL(name);
        Test.stopTest();
    }

    @isTest
    static void testGetTemporaryAddress() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        Boolean throwsException = false;
        try {
            List<NKS_TemporaryAddressController.TemporaryAddress> addresses1 = NKS_TemporaryAddressController.getTemporaryAddresses(
                a.Id,
                'Account'
            );
            List<NKS_TemporaryAddressController.TemporaryAddress> addresses2 = NKS_TemporaryAddressController.getTemporaryAddresses(
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
        String testString = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
        Test.startTest();
        String str = NKS_TemporaryAddressController.validateString(testString);
        Test.stopTest();
    }

    @isTest
    static void testCreateAddress() {
        List<String> fieldList = new List<String>{ 'Solbakken 7e', '1111', 'Oslo' };
        Test.startTest();
        String testAddress = NKS_TemporaryAddressController.createAddress(fieldList);
        Test.stopTest();
    }

    @isTest
    static void testSetValues() {
        // Create test data
        Person__c p = new Person__c(
            Name = '12345678910',
            INT_LastName__c = 'TestLastName',
            INT_FirstName__c = 'TestFirstname'
        );
        insert p;

        List<NKS_TemporaryAddressController.TemporaryAddress> addresses = new List<NKS_TemporaryAddressController.TemporaryAddress>();
        NKS_TemporaryAddressController.TemporaryAddress address1 = new NKS_TemporaryAddressController.TemporaryAddress();
        address1.zipCode = '1234';
        NKS_TemporaryAddressController.TemporaryAddress address2 = new NKS_TemporaryAddressController.TemporaryAddress();
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
        NKS_TemporaryAddressController.setValues(addresses, '12345678910');
        Test.stopTest();

        // Verify the results
        System.assertEquals('Poststed1', addresses[0].city);
        System.assertEquals('Poststed2', addresses[1].city);
        System.assertEquals('NAVN NAVNESEN', addresses[0].fullName);
        System.assertEquals('NAVN NAVNESEN', addresses[1].fullName);
    }
}
