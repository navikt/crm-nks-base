@isTest
private with sharing class NKS_ArticleArchiveHandlerTest {
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
    @isTest
    private static void smokeTest() {
        NKS_Announcement__c a = [SELECT Id FROM NKS_Announcement__c WHERE RecordType.DeveloperName = 'News' LIMIT 1];
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        Test.startTest();
        new NKS_ArticleArchiveHandler('Websak_NKS_News_Setting__mdt', 'Nyheter NKS').execute(a);
        Test.stopTest();

        System.assert(true, 'smoke test passed');
    }
    @isTest
    private static void testExecute() {
        NKS_Announcement__c article = [
            SELECT Id
            FROM NKS_Announcement__c
            WHERE RecordType.DeveloperName = 'Current_In_NAV_Contact_Center'
            LIMIT 1
        ];
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        Test.startTest();
        Boolean isSuccess = new NKS_ArticleArchiveHandler('Websak_NKS_Current_Setting__mdt', 'Aktuelt NKS')
            .archiveArticle(article, '1/2', 'A123456', '1234567', 'ftp_cat');
        Test.stopTest();

        System.assertEquals(true, isSuccess, 'Expect integration to success');
    }
    @IsTest
    private static void testGetManifest() {
        Map<String, String> fileInfo = new Map<String, String>();
        fileInfo.put('filename', 'fileType');

        Test.startTest();
        Blob manifestBlob1 = new NKS_ArticleArchiveHandler('Websak_NKS_News_Setting__mdt', 'Nyheter NKS')
            .getManifest(fileInfo, 'posttype', 'postName', 'categry', Date.Today(), '4234/03', 'A123456', '1234567');
        Blob manifestBlob2 = new NKS_ArticleArchiveHandler('Websak_NKS_Current_Setting__mdt', 'Aktuelt NKS')
            .getManifest(fileInfo, 'posttype', 'postName', 'categry', Date.Today(), '4234/03', 'A123456', '1234567');
        Test.stopTest();

        Assert.areNotEqual(null, EncodingUtil.base64Encode(manifestBlob1), 'Expect a blob');
        Assert.areNotEqual(null, EncodingUtil.base64Encode(manifestBlob2), 'Expect a blob');
    }
}
