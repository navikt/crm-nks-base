@isTest
private with sharing class NKS_NewsArchiveHandlerTest {
    @isTest
    private static void smokeTest(){
        try{
            ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

            NKS_Announcement__c a = new NKS_Announcement__c();
            a.Name = 'News Article';
            a.Skills__c = 'Arbeid';
            a.NKS_News_Status__c = 'Published';
            a.NKS_News_Archive__c = true;
            a.NKS_News_Publish_Date__c  = Datetime.now().addDays(-1);    //yesterday
            a.NKS_News_Delete_Date__c   = Date.today().addDays(1);        //tomorrow
            a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;

            insert a;
            Test.startTest();
            new NKS_NewsArchiveHandler().execute(a);
            Test.stopTest();
            
        } catch (Exception e) {
            System.assert(false, 'should not feil here' + e.getMessage());
        }
        System.assert(true, 'smoke test passed');
        
    }
    @isTest
    private static void testExecute() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        NKS_Announcement__c a = new NKS_Announcement__c();
        a.Name = 'News Article';
        a.Skills__c = 'Arbeid';
        a.NKS_News_Status__c = 'Published';
        a.NKS_News_Archive__c = true;
        a.NKS_News_Publish_Date__c  = Datetime.now().addDays(-1);    //yesterday
        a.NKS_News_Delete_Date__c   = Date.today().addDays(1);        //tomorrow
        a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;

        insert a;

        Test.startTest();
        Boolean isSuccess = new NKS_NewsArchiveHandler().archiveArticle(
            [
                SELECT Id, Name ,Skills__c, NKS_News_Publish_Date__c
                FROM NKS_Announcement__c
                WHERE RecordType.Name='News'
                    AND NKS_News_Archive__c=TRUE
                    AND NKS_News_Delete_Date__c=TOMORROW
                    AND NKS_News_Status__c='Published'
                LIMIT 1
            ],
            '1/2',
            'ftp_cat'
        );
        Test.stopTest();
        System.assertEquals(true, isSuccess, 'Expect integration to success');
    }
    @IsTest
    private static void testGetManifest() {
        NKS_Announcement__c a = new NKS_Announcement__c();
        a.Name = 'News Article';
        a.Skills__c = 'Arbeid';
        a.NKS_News_Status__c = 'Published';
        a.NKS_News_Archive__c = true;
        a.NKS_News_Publish_Date__c  = Datetime.now().addDays(-1);    //yesterday
        a.NKS_News_Delete_Date__c   = Date.today().addDays(1);        //tomorrow
        a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;

        insert a;

        Map<String, String> fileInfo=new Map<String,String>();
        fileInfo.put('filename','fileType');
        Test.startTest();
        Blob manifestBlob=new NKS_NewsArchiveHandler().getManifest(fileInfo, 'posttype', 'postName', 'categry', Date.Today(),'4234/03');
        Test.stopTest();

        System.assertNotEquals(null,EncodingUtil.base64Encode(manifestBlob), 'Expect a blob');
    }
}
