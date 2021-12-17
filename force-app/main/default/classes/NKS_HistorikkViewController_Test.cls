@isTest
public class NKS_HistorikkViewController_Test {
    @isTest
    static void testFullmaktData() {
        Person__c p = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestName',
            INT_FirstName__c = 'TestLastname'
        );
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');

        Test.startTest();
        List<NKS_HistorikkViewController.Historikk> hData = NKS_HistorikkViewController.getHistorikk(a.Id, 'Account');
        Test.stopTest();

        System.debug(hData);
        System.assertEquals(false, hData.isEmpty());

        //System.assert(!histTestData.isEmpty());
    }

    @isTest
    static void testFullmaktDataCase() {
        Person__c p = new Person__c(
            Name = '12106519356',
            INT_LastName__c = 'TestName',
            INT_FirstName__c = 'TestLastname'
        );
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        Case c = new Case(Origin = 'Phone', Subject = 'TEST PHONE', AccountId = a.Id);
        insert c;
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');

        Test.startTest();
        List<NKS_HistorikkViewController.Historikk> hData = NKS_HistorikkViewController.getHistorikk(c.Id, 'Case');
        Test.stopTest();

        System.debug(hData);
        //System.assertEquals(false, hData.isEmpty());
    }

    /*   @isTest
    static void userAccessTest() {
        List<NKS_HistorikkViewController.Historikk> hData = new List<NKS_HistorikkViewController.Historikk>();
        String uniqueUserName = 'testuser' + '@testorg.com';
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        system.debug(prof);
        User testUser = new User(Alias = 'TestUser', Email = 'testuser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = prof.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = uniqueUserName);
        insert testUser;

        Person__c p = new Person__c(Name='12106519356',INT_LastName__c='TestName',INT_FirstName__c='TestLastname');
        insert p;
        Account a = new Account(CRM_Person__c = p.Id, Name = 'testName');
        insert a;
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');

        test.startTest();
        System.runAs(testUser){           
            hData = NKS_HistorikkViewController.getHistorikk(a.Id, 'Account');
			}
        test.stopTest();
        System.debug(hData);

    } */
}
