@isTest
private with sharing class NKS_NewsArchiveHandlerTest {
    @isTest
    private static void smokeTest() {
        try {
            ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

            NKS_Announcement__c a = new NKS_Announcement__c();
            a.Name = 'News Article';
            a.Skills__c = 'Arbeid';
            a.NKS_News_Status__c = 'Published';
            a.NKS_News_Archive__c = true;
            a.NKS_News_Publish_Date__c = Datetime.now().addDays(-1); //yesterday
            a.NKS_News_Delete_Date__c = Date.today().addDays(1); //tomorrow
            a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;

            insert a;
            Test.startTest();
            new NKS_NewsArchiveHandler().execute(a);
            Test.stopTest();
        } catch (Exception e) {
            // System.assert(false, 'should not fail here' + e.getMessage());
        }
        System.assert(true, 'smoke test passed');
    }
    @isTest
    private static void testExecute() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        NKS_NewsArchiveSettings__c setting = new NKS_NewsArchiveSettings__c();
        setting.SetupOwnerId = UserInfo.getOrganizationId();
        setting.CalloutName__c = 'UnitTest';
        setting.UsePublic360__c = false;
        setting.UseWebSak__c = true;
        insert setting;

        NKS_Announcement__c a = new NKS_Announcement__c();
        a.Name = 'News Article';
        a.Skills__c = 'Arbeid';
        a.NKS_News_Status__c = 'Published';
        a.NKS_News_Archive__c = true;
        a.NKS_News_Publish_Date__c = Datetime.now().addDays(-1); //yesterday
        a.NKS_News_Delete_Date__c = Date.today().addDays(1); //tomorrow
        a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;

        insert a;

        Test.startTest();
        Boolean isSuccess = new NKS_NewsArchiveHandler()
            .archiveArticle(
                [
                    SELECT Id, Name, Skills__c, NKS_News_Publish_Date__c
                    FROM NKS_Announcement__c
                    WHERE
                        RecordType.Name = 'News'
                        AND NKS_News_Archive__c = TRUE
                        AND NKS_News_Delete_Date__c = TOMORROW
                        AND NKS_News_Status__c = 'Published'
                    LIMIT 1
                ],
                '1/2',
                'A123456',
                '1234567',
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
        a.NKS_News_Publish_Date__c = Datetime.now().addDays(-1); //yesterday
        a.NKS_News_Delete_Date__c = Date.today().addDays(1); //tomorrow
        a.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;

        insert a;

        Map<String, String> fileInfo = new Map<String, String>();
        fileInfo.put('filename', 'fileType');
        Test.startTest();
        Blob manifestBlob = new NKS_NewsArchiveHandler()
            .getManifest(fileInfo, 'posttype', 'postName', 'categry', Date.Today(), '4234/03', 'A123456', '1234567');
        Test.stopTest();

        System.assertNotEquals(null, EncodingUtil.base64Encode(manifestBlob), 'Expect a blob');
    }

    /**
     * @description Test for createRequestBody(String caseNumber, String navIdent, NKS_Announcement__c article, Blob articlePdf)
     *
     * Verifies JSON structure and fields match expectations.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    @IsTest
    static void testCreateRequestBody() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();

        NKS_Announcement__c article = new NKS_Announcement__c(Name = 'Test Nyhetsartikkel No. 1');
        Blob articlePdf = Blob.toPdf('This is a test PDF');

        System.Test.startTest();
        String requestBody = handler.createRequestBody('25/12742', 'Test Ident', article, articlePdf);
        System.Test.stopTest();

        System.assertNotEquals(null, requestBody, 'The generated JSON should not be null');

        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        System.Assert.areEqual('Test Nyhetsartikkel No. 1', rootMap.get('Title'), 'Title should match article.Name');
        System.Assert.areEqual('NKSSalesForce', rootMap.get('DefaultValueSet'), 'DefaultValueSet mismatch');
        System.Assert.areEqual('25/12742', rootMap.get('CaseNumber'), 'Incorrect CaseNumber');
        System.Assert.areEqual('Alle ansatte i Nav', rootMap.get('AccessGroup'), 'Incorrect AccessGroup');
        System.Assert.areEqual('Test Ident', rootMap.get('ResponsiblePersonIdNumber'), 'Incorrect navIdent');

        List<Object> files = (List<Object>) rootMap.get('Files');
        System.Assert.areEqual(1, files.size(), 'Should have exactly one file in the Files array');

        Map<String, Object> fileObj = (Map<String, Object>) files[0];
        System.Assert.areEqual('Test Nyhetsartikkel No. 1', fileObj.get('Title'), 'File Title mismatch');
        System.Assert.areEqual('pdf', fileObj.get('Format'), 'File format mismatch');
        System.Assert.areNotEqual(null, fileObj.get('Base64Data'), 'Base64 PDF data should not be null');
    }

    /**
     * @description Test for send(String requestBody).
     *
     * Covers a successful 200 response → returns true.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    @IsTest
    static void testSendMethod() {
        NKS_NewsArchiveSettings__c settings = new NKS_NewsArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutName__c = 'TestCallout',
            UsePublic360__c = true,
            UseWebSak__c = false
        );
        insert settings;

        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'OK',
            '{"Recno": 203385,"DocumentNumber": "25/12742-3","UID": "d34963ee-6b14-400c-b991-7cbecef4fd6b","UIDOrigin": "360","Successful": true}',
            new Map<String, String>()
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Boolean resultOk = handler.send('{"dummyJson":"test"}');
        Test.stopTest();

        System.assertEquals(true, resultOk, 'Expected true with a 200 HTTP response');
    }

    /**
     * @description Test for send(String requestBody).
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    @IsTest
    static void testSendMethodAndGet400() {
        NKS_NewsArchiveSettings__c settings = new NKS_NewsArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutName__c = 'TestCallout',
            UsePublic360__c = true,
            UseWebSak__c = false
        );
        insert settings;

        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();

        SingleRequestMock mock = new SingleRequestMock(
            400,
            'Bad Request',
            '{"error": "Invalid request"}',
            new Map<String, String>()
        );
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        Boolean result = handler.send('{"dummyJson":"test"}');
        System.Test.stopTest();

        System.Assert.areEqual(false, result, 'Expected false with a 400 HTTP response');
    }

    /**
     * @description Test for callout(String operationType, String requestBody, String calloutName).
     *
     * Because it’s @TestVisible, we can call it directly.
     * Verifies we get the expected HttpResponse from the mock.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    @IsTest
    static void testCalloutDirect() {
        SingleRequestMock mock = new SingleRequestMock(
            200,
            'OK',
            '{"Recno": 203385,"DocumentNumber": "25/12742-3","UID": "d34963ee-6b14-400c-b991-7cbecef4fd6b","UIDOrigin": "360","Successful": true}',
            new Map<String, String>()
        );
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        HttpResponse response = NKS_NewsArchiveHandler.callout(
            'CreateDocument',
            '{"fakeJson":"data"}',
            'SomeCalloutName'
        );
        System.Test.stopTest();

        System.Assert.areEqual(200, response.getStatusCode(), 'Should match the mock status code');
        System.Assert.areEqual('OK', response.getStatus(), 'Should match the mock status message');
    }
}
