@isTest
public with sharing class NKS_HomePageControllerTest {
    @TestSetup
    static void makeData() {
        NKS_TestDataFactory.createAnnouncements(1, 'Salesforce oppdatering');
        NKS_TestDataFactory.createAnnouncements(1, 'Kampanje');
        ReadyResponse__c svarberedskap = new ReadyResponse__c(Name = 'Test Svarberedskap', URL__c = 'Test-URL');
        insert svarberedskap;
    }

    @isTest
    static void testGetField() {
        Test.startTest();
        String info = NKS_HomePageController.getField('Salesforce oppdatering');
        Test.stopTest();

        System.assertEquals(700, info.length());
    }

    @isTest
    static void testGetList() {
        Test.startTest();
        List<NKS_HomePageController.Record> recordlist = NKS_HomePageController.getList(
            'Name',
            'NKS_Information__c',
            'NKS_Announcement__c',
            'NKS_Type__c != null',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate',
            true,
            false
        );
        Test.stopTest();

        System.assertNotEquals(0, recordlist.size());
    }

    @isTest
    static void testGetUserSkills() {
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        Test.startTest();
        NKS_HomePageController.getUserSkills(testUser.Id);
        Test.stopTest();

        System.assertNotEquals(null, testUser.Id);
    }

    @isTest
    static void testGetCampaign() {
        Test.startTest();
        NKS_Announcement__c testCampain = NKS_HomePageController.getCampaign();
        Test.stopTest();

        System.assertNotEquals(null, testCampain.NKS_ImageURL__c);
    }

    @isTest
    static void testGetReadyResponse() {
        Test.startTest();
        List<ReadyResponse__c> testList = NKS_HomePageController.getReadyResponse();
        Test.stopTest();

        System.assertEquals(1, testList.size());
    }
}
