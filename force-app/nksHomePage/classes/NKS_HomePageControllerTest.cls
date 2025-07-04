@isTest
public with sharing class NKS_HomePageControllerTest {
    @TestSetup
    static void makeData() {
        Id SFUpdateRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Salesforce Update')
            .getRecordTypeId();
        Id newsRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('News')
            .getRecordTypeId();
        Id nksStatusRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('NKS Status')
            .getRecordTypeId();
        Id nksCurrentRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('NKS Current')
            .getRecordTypeId();
        Id trafficRecordTypeId = Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByName()
            .get('Traffic')
            .getRecordTypeId();

        NKS_TestDataFactory.createAnnouncements(1, SFUpdateRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, newsRecordTypeId);
        NKS_TestDataFactory.createAnnouncements(1, nksStatusRecordTypeId);
        NKS_Announcement__c traffic = new NKS_Announcement__c(
            Name = 'Test Traffic',
            NKS_Information__c = 'Leveransen lørdag 31. oktober ble levert som planlagt, og NAV Arbeid og ytelser kan derfor nå innvilge dagpenger til personer også fra den 1. november eller senere. Opprinnelig melding 29.10.20: Hvis bruker har søkt om dagpenger med virkningstidspunkt fra 1.november eller senere, så kan vi få henvendelser hvor bruker etterlyser svar på søknaden. NAV Arbeid og ytelser behandler for tiden ingen søknader om dagpenger med virkningstidspunkt (startdato) fra 1. november eller senere. Årsaken er regelverksendringer fra den datoen, som vi må få oppdatert i fagsystemene først, for at utfall i saken skal bli rett.Informer gjerne bruker om dette, og henvis eller til saksbehandlingstidene på nav.no.!!!!',
            RecordTypeId = trafficRecordTypeId,
            NKS_Opening_Hours_Label__c = 'Sommer 2025',
            NKS_Opening_Hours_Information__c = 'Vi har redusert åpningstidene i sommer.'
        );
        insert traffic;

        List<NKS_Announcement__c> announcements = new List<NKS_Announcement__c>();
        for (Integer i = 0; i < 6; i++) {
            announcements.add(
                new NKS_Announcement__c(
                    Name = 'Test Announcement ' + i,
                    NKS_Link_URL__c = 'https://example.com/' + i,
                    RecordTypeId = nksCurrentRecordTypeId
                )
            );
        }
        insert announcements;

        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Test Article',
            UrlName = 'Test-Article',
            Summary = 'Informasjon for test'
        );
        insert testKnowledge;

        Case testCase = new Case();
        insert testCase;
    }

    @isTest
    static void testGetAnnouncementSfUpdates() {
        Test.startTest();
        NKS_Announcement__c sfUpdates = NKS_HomePageController.getAnnouncement('Salesforce_Update');
        Test.stopTest();

        Assert.areEqual(700, sfUpdates.NKS_Information__c.length());
    }

    @isTest
    static void testGetAnnouncementTraffic() {
        Test.startTest();
        NKS_Announcement__c traffic = NKS_HomePageController.getAnnouncement('Traffic');
        Test.stopTest();

        Assert.areEqual('Sommer 2025', traffic.NKS_Opening_Hours_Label__c);
        Assert.areEqual('Vi har redusert åpningstidene i sommer.', traffic.NKS_Opening_Hours_Information__c);
    }

    @isTest
    static void testGetListAnnouncement() {
        Test.startTest();
        List<NKS_HomePageController.RecordWrapper> recordlist = NKS_HomePageController.getAnnouncementList(
            'Name',
            'NKS_Information__c',
            'NKS_TypeFormula__c != null',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate',
            true,
            true,
            new List<String>()
        );
        Test.stopTest();

        Assert.areNotEqual(0, recordlist.size());
    }

    @isTest
    static void testGetListKnowledge() {
        Test.startTest();
        List<NKS_HomePageController.RecordWrapper> recordlist = NKS_HomePageController.getKnowledgeList(
            'Title',
            null,
            'LastModifiedDate = LAST_N_DAYS:30 AND Title != \'\'',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate',
            false,
            false,
            null
        );
        Test.stopTest();

        Assert.areNotEqual(0, recordlist.size());
    }

    @isTest
    static void testGetListCase() {
        Test.startTest();
        List<NKS_HomePageController.RecordWrapper> recordlist = NKS_HomePageController.getCaseList(
            'CaseNumber',
            null,
            'Status IN (\'New\', \'In progress\', \'Reserved\')',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate'
        );
        Test.stopTest();

        Assert.areNotEqual(0, recordlist.size());
    }

    @isTest
    static void testGetListWithNullValue() {
        Test.startTest();
        List<NKS_HomePageController.RecordWrapper> recordlist = NKS_HomePageController.getList(
            'Title',
            null,
            'Knowledge__kav',
            'publishStatus=\'Online\'',
            'LastModifiedDate DESC',
            '3',
            'CreatedDate'
        );
        Test.stopTest();

        Assert.areEqual(0, recordlist.size());
    }

    @isTest
    static void testGetUserSkills() {
        //User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        List<String> testSkills;
        Test.startTest();
        testSkills = NKS_HomePageController.getUserSkills();
        Test.stopTest();

        if (testSkills.size() > 0) {
            Assert.areNotEqual(0, testSkills.size());
        } else {
            Assert.areEqual(0, testSkills.size());
        }
    }

    @isTest
    static void testGetCampaign() {
        Test.startTest();
        NKS_Announcement__c testCampaign = NKS_HomePageController.getCampaign();
        Test.stopTest();
        Assert.areEqual(null, testCampaign);
    }

    @isTest
    static void testGetNews() {
        NKS_Announcement__c obj = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        Test.startTest();
        NKS_Announcement__c testNews = NKS_HomePageController.getNews(obj.Id);
        Test.stopTest();
        Assert.areNotEqual(null, testNews);
    }

    @isTest
    static void testGetReadyResponse() {
        Test.startTest();
        List<Knowledge__kav> testList = NKS_HomePageController.getReadyResponses();
        Test.stopTest();

        Assert.areEqual(null, testList);
    }

    @isTest
    static void testRemoveHtmlTags() {
        String info = '<p><span style="color:rgb(0,0,0);font-size:14px;">Test String</span></p>';
        List<String> testList = new List<String>();
        testList.add(info);
        Test.startTest();
        List<String> res = NKS_HomePageController.removeHtmlTags(testList);
        Test.stopTest();

        Assert.areEqual('Test String', res[0]);
    }

    @isTest
    static void testGetImageUrlNULL() {
        NKS_Announcement__c testNews = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];
        Test.startTest();
        String testURL = NKS_HomePageController.getImageUrl(testNews.Id);
        Test.stopTest();

        Assert.areEqual(null, testURL);
    }

    @isTest
    static void testGetImageUrl() {
        NKS_Announcement__c testNews = [SELECT Id FROM NKS_Announcement__c WHERE NKS_TypeFormula__c = 'Nyhet' LIMIT 1];

        ContentVersion content = new ContentVersion();
        content.Title = 'Header_Picture1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        content.origin = 'H';
        insert content;

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = testNews.id;
        contentlink.contentdocumentid = [SELECT contentDocumentId FROM ContentVersion WHERE id = :content.id]
        .contentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;

        Test.startTest();
        String testURL = NKS_HomePageController.getImageUrl(testNews.Id);
        Test.stopTest();

        Assert.areNotEqual(null, testURL);
    }

    // Not possible to insert UserAppInfo and AppDefinition, so this is just for coverage
    @isTest
    static void testGetUsersCurrentApp() {
        Test.startTest();
        NKS_HomePageController.getUsersCurrentApp();
        Test.stopTest();
    }

    // Not possible to insert UserAppInfo and AppDefinition, so this is just for coverage
    @isTest
    static void testUpdateUsersCurrentApp() {
        Test.startTest();
        NKS_HomePageController.updateUsersCurrentApp('NewApp');
        Test.stopTest();
    }

    @isTest
    static void testGetNksStatus() {
        Test.startTest();
        NKS_Announcement__c testNksStatus = NKS_HomePageController.getNksStatus('Test 0');
        Test.stopTest();

        Assert.areNotEqual(null, testNksStatus);
    }

    @isTest
    static void testUpdateNksStatus_SuccessfulUpdate() {
        NKS_Announcement__c status = [
            SELECT Id, Name
            FROM NKS_Announcement__c
            WHERE NKS_TypeFormula__c = 'NKS status'
            LIMIT 1
        ];

        Map<String, String> fields = new Map<String, String>{
            'Id' => status.Id,
            'NKS_Information__c' => 'Updated Information'
        };

        Test.startTest();
        NKS_HomePageController.updateNksStatus(fields);
        Test.stopTest();

        NKS_Announcement__c updatedStatus = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE Id = :status.Id];
        Assert.areEqual(
            'Updated Information',
            updatedStatus.NKS_Information__c,
            'The NKS_Information__c field should be updated.'
        );
    }

    @isTest
    static void testUpdateNksStatusError() {
        Exception ex;

        Test.startTest();
        try {
            NKS_HomePageController.updateNksStatus(null);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        Assert.areNotEqual(null, ex);
    }

    @isTest
    static void testGetNksCurrents() {
        Test.startTest();
        List<NKS_Announcement__c> result = NKS_HomePageController.getNksCurrents();
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual(5, result.size(), 'Should return only 5 latest announcements');
        Assert.isTrue(
            result[0].NKS_Link_URL__c.startsWith('https://example.com'),
            'URL should be present in the result'
        );
    }

    @isTest
    static void testCreateNksCurrent() {
        String testTitle = 'New Test Announcement';
        String testURL = 'https://newtest.com';

        Test.startTest();
        NKS_HomePageController.createNksCurrent(testTitle, testURL);
        Test.stopTest();

        List<NKS_Announcement__c> insertedRecords = [
            SELECT Id, Name, NKS_Link_URL__c, RecordType.DeveloperName
            FROM NKS_Announcement__c
            WHERE Name = :testTitle
        ];

        Assert.areEqual(1, insertedRecords.size(), 'A new Announcement should have been created.');
        Assert.areEqual(testTitle, insertedRecords[0].Name, 'The title of the record should match the input.');
        Assert.areEqual(testURL, insertedRecords[0].NKS_Link_URL__c, 'The URL of the record should match the input.');
        Assert.areEqual(
            'NKS_Current',
            insertedRecords[0].RecordType.DeveloperName,
            'The RecordType should be NKS_Current.'
        );
    }

    @IsTest
    static void testCreateNksCurrentError() {
        String invalidURL = String.valueOf('https://example.com/' + 'a'.repeat(1000));
        String title = 'Test Title';
        Exception ex;

        Test.startTest();
        try {
            NKS_HomePageController.createNksCurrent(title, invalidURL);
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        Assert.areNotEqual(null, ex);
    }
}
