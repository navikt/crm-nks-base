@isTest
private class NKS_NewsArchiveHandlerTest {
    @isTest
    private static void testArchiveArticle_withInjectedMapping() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');
        NKS_NewsArchiveSettings__c setting = new NKS_NewsArchiveSettings__c();
        setting.SetupOwnerId = UserInfo.getOrganizationId();
        setting.CalloutName__c = 'UnitTest';
        setting.UsePublic360__c = false;
        setting.UseWebSak__c = true;
        insert setting;

        Id newsRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;
        NKS_Announcement__c a = new NKS_Announcement__c();
        a.Name = 'News Article';
        a.Skills__c = 'Arbeid';
        a.NKS_News_Status__c = 'Published';
        a.NKS_News_Archive__c = true;
        a.NKS_News_Publish_Date__c = Datetime.now().addDays(-1);
        a.NKS_News_Delete_Date__c = Date.today().addDays(1);
        a.RecordTypeId = newsRecordTypeId;
        insert a;

        NKS_Announcement__c article = [
            SELECT Id, Name, Skills__c, NKS_News_Publish_Date__c
            FROM NKS_Announcement__c
            WHERE Name = 'News Article'
            LIMIT 1
        ];

        WebsakNewsMapping__mdt stubSettings = new WebsakNewsMapping__mdt();
        stubSettings.CaseNumberTest__c = '1/2';
        stubSettings.NavIdTest__c = 'A123456';
        stubSettings.NavEnhetTest__c = '1234567';
        stubSettings.CaseNumberProd__c = '1/2';
        stubSettings.NavIdProd__c = 'A123456';
        stubSettings.NavEnhetProd__c = '1234567';

        Test.startTest();
        Boolean isSuccess = new NKS_NewsArchiveHandler(stubSettings)
            .archiveArticle(
                article,
                stubSettings.CaseNumberTest__c,
                stubSettings.NavIdTest__c,
                stubSettings.NavEnhetTest__c,
                'ftp_cat'
            );
        Test.stopTest();

        Assert.areEqual(true, isSuccess, 'Expect integration to succeed');
    }

    @isTest
    private static void testGetManifest_withInjectedMapping() {
        Id newsRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1].Id;
        NKS_Announcement__c a = new NKS_Announcement__c();
        a.Name = 'News Article';
        a.Skills__c = 'Arbeid';
        a.NKS_News_Status__c = 'Published';
        a.NKS_News_Archive__c = true;
        a.NKS_News_Publish_Date__c = Datetime.now().addDays(-1);
        a.NKS_News_Delete_Date__c = Date.today().addDays(1);
        a.RecordTypeId = newsRecordTypeId;
        insert a;

        Map<String, String> fileInfo = new Map<String, String>();
        fileInfo.put('filename', 'fileType');

        WebsakNewsMapping__mdt stubSettings = new WebsakNewsMapping__mdt();
        stubSettings.CaseNumberTest__c = '1/2';
        stubSettings.NavIdTest__c = 'A123456';
        stubSettings.NavEnhetTest__c = '1234567';

        Test.startTest();
        Blob manifestBlob = new NKS_NewsArchiveHandler(stubSettings)
            .getManifest(
                fileInfo,
                'posttype',
                'postName',
                'categry',
                Date.Today(),
                stubSettings.CaseNumberTest__c,
                stubSettings.NavIdTest__c,
                stubSettings.NavEnhetTest__c
            );
        Test.stopTest();

        Assert.areNotEqual(null, EncodingUtil.base64Encode(manifestBlob), 'Expect a blob');
    }

    @isTest
    static void testCreateRequestBody_withInjectedMapping() {
        NKS_Announcement__c article = new NKS_Announcement__c(Name = 'Test Nyhetsartikkel No. 1');
        Blob articlePdf = Blob.toPdf('This is a test PDF');
        WebsakNewsMapping__mdt stubSettings = new WebsakNewsMapping__mdt();
        stubSettings.CaseNumberTest__c = '25/12742';
        stubSettings.NavIdTest__c = 'Test Ident';
        stubSettings.NavEnhetTest__c = 'Test Enhet';

        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler(stubSettings);

        System.Test.startTest();
        String requestBody = handler.createRequestBody('25/12742', 'Test Ident', article, articlePdf);
        System.Test.stopTest();

        Assert.areNotEqual(null, requestBody, 'The generated JSON should not be null');

        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        Assert.areEqual('Test Nyhetsartikkel No. 1', rootMap.get('Title'), 'Title should match article.Name');
        Assert.areEqual('NKSSalesForce', rootMap.get('DefaultValueSet'), 'DefaultValueSet mismatch');
        Assert.areEqual('25/12742', rootMap.get('CaseNumber'), 'Incorrect CaseNumber');
        Assert.areEqual('Alle ansatte i Nav', rootMap.get('AccessGroup'), 'Incorrect AccessGroup');
        Assert.areEqual('Test Ident', rootMap.get('ResponsiblePersonIdNumber'), 'Incorrect navIdent');
        List<Object> files = (List<Object>) rootMap.get('Files');
        Assert.areEqual(1, files.size(), 'Should have exactly one file in the Files array');

        Map<String, Object> fileObj = (Map<String, Object>) files[0];
        Assert.areEqual('Test Nyhetsartikkel No. 1', fileObj.get('Title'), 'File Title mismatch');
        Assert.areEqual('pdf', fileObj.get('Format'), 'File format mismatch');
        Assert.areNotEqual(null, fileObj.get('Base64Data'), 'Base64 PDF data should not be null');
    }

    @isTest
    static void testSendMethod_withInjectedMapping() {
        NKS_NewsArchiveSettings__c settings = new NKS_NewsArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutName__c = 'TestCallout',
            UsePublic360__c = true,
            UseWebSak__c = false
        );
        insert settings;

        WebsakNewsMapping__mdt stubSettings = new WebsakNewsMapping__mdt();
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler(stubSettings);
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

        Assert.areEqual(true, resultOk, 'Expected true with a 200 HTTP response');
    }

    @isTest
    static void testSendMethodAndGet400_withInjectedMapping() {
        NKS_NewsArchiveSettings__c settings = new NKS_NewsArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CalloutName__c = 'TestCallout',
            UsePublic360__c = true,
            UseWebSak__c = false
        );
        insert settings;

        WebsakNewsMapping__mdt stubSettings = new WebsakNewsMapping__mdt();
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler(stubSettings);
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

        Assert.areEqual(false, result, 'Expected false with a 400 HTTP response');
    }

    @IsTest
    static void testCalloutDirect_withInjectedMapping() {
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

        Assert.areEqual(200, response.getStatusCode(), 'Should match the mock status code');
        Assert.areEqual('OK', response.getStatus(), 'Should match the mock status message');
    }
}
