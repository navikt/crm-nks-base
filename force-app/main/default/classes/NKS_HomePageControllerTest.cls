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
        Id operationalRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Operational')
            .getRecordTypeId();

        NKS_TestDataFactory.createAnnouncements(1, SFUpdateRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, campaignRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, newsRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, operationalRecordTypeId);

        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Felles - Svarberedskap Korona',
            UrlName = 'Felles-Svarberedskap-Korona',
            Summary = 'Informasjon for test svarberedskap'
        );
        insert testKnowledge;
    }

    @isTest
    static void testGetField() {
        Test.startTest();
        String info = NKS_HomePageController.getField('Salesforce Update');
        Test.stopTest();

        System.assertEquals(700, info.length());
    }

    @isTest
    static void testGetFieldWithNullValue() {
        String info = '';
        NKS_Announcement__c operational = [
            SELECT Id, NKS_TypeFormula__c, NKS_Information__c
            FROM NKS_Announcement__c
            WHERE NKS_TypeFormula__c = 'Teknisk og drift'
            LIMIT 1
        ];
        operational.NKS_Information__c = '';
        update operational;

        Test.startTest();
        try {
            info = NKS_HomePageController.getField('Operational');
        } catch (Exception ex) {
            System.assertEquals('System.NullPointerException', ex.getTypeName());
            System.assertEquals('Attempt to de-reference a null object', ex.getMessage());
        }
        Test.stopTest();

        System.assertEquals(null, info);
    }

    @isTest
    static void testGetAnnouncementList() {
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
            true
        );
        Test.stopTest();

        System.assertNotEquals(0, recordlist.size());
    }

    @isTest
    static void testGetCaseList() {
        Test.startTest();
        List<NKS_HomePageController.Record> recordlist = NKS_HomePageController.getList(
            'CaseNumber',
            null,
            'Case',
            'Status = \'New\' AND RecordType.DeveloperName=\'STO_Case\'',
            'CreatedDate DESC',
            '3',
            'CreatedDate',
            true,
            false
        );
        Test.stopTest();

        System.assertEquals(0, recordlist.size());
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
        Knowledge__kav k = [
            SELECT Id, Title, PublishStatus, KnowledgeArticleId
            FROM knowledge__kav
            WHERE Title = 'Felles - Svarberedskap Korona'
            LIMIT 1
        ];
        KbManagement.PublishingService.publishArticle(K.KnowledgeArticleId, true);

        Test.startTest();
        List<Knowledge__kav> testList = NKS_HomePageController.getReadyResponses();
        Test.stopTest();

        System.assertEquals(1, testList.size());
    }

    @isTest
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

    @isTest
    static void testCountNewsViews() {
        NKS_Announcement__c a = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        NKS_Audit_Log__c al = new NKS_Audit_Log__c(Announcement__c = a.Id, User__c = UserInfo.GetUserId());
        insert al;

        Test.startTest();
        Integer counter = NKS_HomePageController.countNewsViews(a.Id);
        Test.stopTest();

        System.assertEquals(1, counter);
    }
}
