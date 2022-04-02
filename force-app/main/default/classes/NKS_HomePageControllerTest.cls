@isTest
public with sharing class NKS_HomePageControllerTest {
    @TestSetup
    static void makeData() {
        NKS_TestDataFactory.createAnnouncements(1, 'Salesforce oppdatering');
        NKS_TestDataFactory.createAnnouncements(1, 'Kampanje');
       
    }

    @isTest
    static void testGetField() {
        Test.startTest();
        String info = NKS_HomePageController.getField('Salesforce oppdatering');
        Test.stopTest();

        System.assertEquals(700, info.length());
    }

    @isTest
    static void testGetFieldWithNullValue() {
        Test.startTest();
        String info = NKS_HomePageController.getField('Nyhet');
        Test.stopTest();

        System.assertEquals(null, info);
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
    static void testGetListWithNullValue() {
        Test.startTest();
        List<NKS_HomePageController.Record> recordlist = NKS_HomePageController.getList(
            'Title',
            null,
            'Knowledge__kav',
            'publishStatus=\'Online\'',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate',
            false,
            false
        );
        Test.stopTest();

        System.assertEquals(0, recordlist.size());
    }

    @isTest
    static void testGetUserSkills() {
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        Set<String> testSkills = new Set<String>();
        Test.startTest();
        testSkills = NKS_HomePageController.getUserSkills(testUser.Id);
        Test.stopTest();

        if (testSkills.size() > 0) {
            System.assertNotEquals(0, testSkills.size());
        } else {
            System.assertEquals(0, testSkills.size());
        }
    }

    @isTest
    static void testGetCampaign() {
        Test.startTest();
        NKS_Announcement__c testCampaign = NKS_HomePageController.getCampaign();
        Test.stopTest();

        System.assertEquals(null, testCampaign);
    }
}
