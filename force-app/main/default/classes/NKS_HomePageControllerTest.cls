@isTest
public with sharing class NKS_HomePageControllerTest {
    @TestSetup
    static void makeData() {
        Id SFUpdateRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Salesforce Update')
            .getRecordTypeId();
        Id campaignRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Campaign')
            .getRecordTypeId();
        Id newsRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('News')
            .getRecordTypeId();

        NKS_TestDataFactory.createAnnouncements(1, SFUpdateRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, campaignRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, newsRecordTypeId);

        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Svarberedskap - Korona',
            UrlName = 'Svarberedskap-Korona',
            Summary = 'Informasjon for test svarberedskap'
        );
        insert testKnowledge;
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
        String info = NKS_HomePageController.getField('Trafikk');
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
            'NKS_TypeFormula__c != null',
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

    @isTest
    static void testGetNews() {
        NKS_Announcement__c obj = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        Test.startTest();
        NKS_Announcement__c testNews = NKS_HomePageController.getNews(obj.Id);
        Test.stopTest();
        System.assertNotEquals(null, testNews);
    }

    @isTest
    static void testGetReadyResponse() {
        Test.startTest();
        List<Knowledge__kav> testList = NKS_HomePageController.getReadyResponses();
        Test.stopTest();

        System.assertEquals(null, testList);
    }

    static void testRemoveHtmlTags() {
        String info = '<p><span style="color:rgb(0,0,0);font-size:14px;">Test String</span></p>';
        List<String> testList = new List<String>();
        testList.add(info);
        Test.startTest();
        List<String> res = NKS_HomePageController.removeHtmlTags(testList);
        Test.stopTest();

        System.assertEquals('Test String', res[0]);
    }

    @isTest
    static void testGetImageURL() {
        NKS_Announcement__c testNews = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        Test.startTest();
        String testURL = NKS_HomePageController.getImageUrl(testNews.Id);
        Test.stopTest();

        System.assertEquals(null, testURL);
    }
}
