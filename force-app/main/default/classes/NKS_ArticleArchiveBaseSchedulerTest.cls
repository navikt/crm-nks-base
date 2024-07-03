@IsTest
public class NKS_ArticleArchiveBaseSchedulerTest {
    @TestSetup
    static void makeData() {
        List<NKS_Announcement__c> announcements = new List<NKS_Announcement__c>();

        announcements.add(
            new NKS_Announcement__c(
                Name = 'Test Current',
                Skills__c = 'Arbeid',
                NKS_News_Publish_Date__c = Date.today().addDays(-10),
                NKS_News_Archive__c = true,
                NKS_News_Delete_Date__c = Date.today().addDays(1),
                NKS_News_Status__c = 'Published',
                RecordTypeId = NKS_TestDataFactory.getRecordTypeId('Current_In_NAV_Contact_Center')
            )
        );
        announcements.add(
            new NKS_Announcement__c(
                Name = 'Test News',
                Skills__c = 'Arbeid',
                NKS_News_Publish_Date__c = Date.today().addDays(-10),
                NKS_News_Archive__c = true,
                NKS_News_Delete_Date__c = Date.today().addDays(1),
                NKS_News_Status__c = 'Published',
                RecordTypeId = NKS_TestDataFactory.getRecordTypeId('News')
            )
        );
        insert announcements;
    }

    @IsTest
    static void testConstructor() {
        NKS_ArticleArchiveCurrentScheduler currentScheduler1 = new NKS_ArticleArchiveCurrentScheduler();
        Assert.areNotEqual(
            '',
            currentScheduler1.query,
            'Default constructor should initialize query with a non-empty string'
        );

        String customQuery = 'SELECT Id FROM NKS_Announcement__c';
        NKS_ArticleArchiveCurrentScheduler currentScheduler2 = new NKS_ArticleArchiveCurrentScheduler(customQuery);
        Assert.areEqual(
            customQuery,
            currentScheduler2.query,
            'Parameterized constructor should initialize query with the provided value'
        );

        NKS_ArticleArchiveNewsScheduler newsScheduler1 = new NKS_ArticleArchiveNewsScheduler();
        Assert.areNotEqual(
            '',
            newsScheduler1.query,
            'Default constructor should initialize query with a non-empty string'
        );

        NKS_ArticleArchiveNewsScheduler newsScheduler2 = new NKS_ArticleArchiveNewsScheduler(customQuery);
        Assert.areEqual(
            customQuery,
            newsScheduler2.query,
            'Parameterized constructor should initialize query with the provided value'
        );
    }

    @IsTest
    static void testExecuteCurrentScheduler() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        NKS_ArticleArchiveCurrentScheduler currentScheduler = new NKS_ArticleArchiveCurrentScheduler();
        List<NKS_Announcement__c> scope = [
            SELECT Id, Name, NKS_News_Publish_Date__c
            FROM NKS_Announcement__c
            WHERE RecordType.DeveloperName = 'Current_In_NAV_Contact_Center'
        ];
        Database.QueryLocator ql = null;

        Test.startTest();
        try {
            ql = currentScheduler.start(null);
            Assert.areNotEqual(null, ql, 'The start method should return a non-null QueryLocator');

            currentScheduler.execute(null, scope);
            currentScheduler.finish(null);
        } catch (Exception e) {
            System.debug('Exception occurred during scheduler execution: ' + e.getMessage());
            Assert.fail('Exception should not occur: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testExecuteNewsScheduler() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        NKS_ArticleArchiveCurrentScheduler currentScheduler = new NKS_ArticleArchiveCurrentScheduler();
        List<NKS_Announcement__c> scope = [
            SELECT Id, Name, NKS_News_Publish_Date__c
            FROM NKS_Announcement__c
            WHERE RecordType.DeveloperName = 'News'
        ];
        Database.QueryLocator ql = null;

        NKS_ArticleArchiveNewsScheduler newsScheduler = new NKS_ArticleArchiveNewsScheduler();
        Test.startTest();
        try {
            ql = newsScheduler.start(null);
            Assert.areNotEqual(null, ql, 'The start method should return a non-null QueryLocator');

            newsScheduler.execute(null, scope);
            newsScheduler.finish(null);
        } catch (Exception e) {
            System.debug('Exception occurred during scheduler execution: ' + e.getMessage());
            Assert.fail('Exception should not occur: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
