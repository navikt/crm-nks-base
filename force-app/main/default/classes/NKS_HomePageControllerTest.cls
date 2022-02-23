@isTest
public with sharing class NKS_HomePageControllerTest {
    @TestSetup
    static void makeData() {
        NKS_TestDataFactory.createAnnouncements(1);
        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Test Svarberedskap',
            UrlName = 'Test-Svarberedskap',
            Summary = 'Informasjon for test svarberedskap',
            Type__c = 'Svarberedskap'
        );
        insert testKnowledge;

        NKS_Announcement__c campaign = new NKS_Announcement__c(
            Name = 'Kampanje',
            NKS_Information__c = 'Husk empatisk kommunikasjon...',
            NKS_Type__c = 'Kampanje'
        );

        insert campaign;
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
    static void testGetReadyResponse() {
        Test.startTest();
        List<Knowledge__kav> testList = NKS_HomePageController.getReadyResponse();
        Test.stopTest();

        System.assertEquals(1, testList.size());
    }

    @isTest
    static void testGetCampaign() {
        Test.startTest();
        NKS_Announcement__c testCampain = NKS_HomePageController.getCampaign();
        Test.stopTest();

        System.assertNotEquals(null, testCampain.NKS_ImageURL__c);
    }
}
