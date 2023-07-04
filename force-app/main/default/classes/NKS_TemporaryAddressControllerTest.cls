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
}
