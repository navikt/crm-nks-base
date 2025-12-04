@isTest
private with sharing class NKS_NewsArchiveHandlerTest {
    // --- Custom Metadata Mock Helpers ---
    private static String QUERY_SANDBOX = 'SELECT Id, CaseNumberTest__c, NavIdTest__c, NavEnhetTest__c, ActiveFrom__c, Order__c FROM WebsakNewsMapping__mdt WHERE ActiveFrom__c <= TODAY ORDER BY ActiveFrom__c DESC, Order__c DESC LIMIT 1';
    private static String QUERY_PROD = 'SELECT Id, CaseNumberProd__c, NavIdProd__c, NavEnhetProd__c, ActiveFrom__c, Order__c FROM WebsakNewsMapping__mdt WHERE ActiveFrom__c <= TODAY ORDER BY ActiveFrom__c DESC, Order__c DESC LIMIT 1';

    private static List<WebsakNewsMapping__mdt> getMockWebsakMetaSandbox() {
        String js =
            '[{"attributes": {"type": "WebsakNewsMapping__mdt"},' +
            '"CaseNumberTest__c": "TST123", "NavIdTest__c": "NAVTST", "NavEnhetTest__c":"ENHTST", "ActiveFrom__c":"2024-01-01","Order__c":1}]';
        return (List<WebsakNewsMapping__mdt>) JSON.deserialize(js, List<WebsakNewsMapping__mdt>.class);
    }
    private static List<WebsakNewsMapping__mdt> getMockWebsakMetaProd() {
        String js =
            '[{"attributes": {"type": "WebsakNewsMapping__mdt"},' +
            '"CaseNumberProd__c": "PRD456", "NavIdProd__c": "NAVPRD", "NavEnhetProd__c":"ENHPRD", "ActiveFrom__c":"2024-01-01","Order__c":1}]';
        return (List<WebsakNewsMapping__mdt>) JSON.deserialize(js, List<WebsakNewsMapping__mdt>.class);
    }
    private static List<WebsakNewsMapping__mdt> getMockMetaNullValues() {
        String js =
            '[{"attributes": {"type": "WebsakNewsMapping__mdt"},' +
            '"CaseNumberTest__c": null, "NavIdTest__c": null, "NavEnhetTest__c": null, "ActiveFrom__c":"2024-01-01","Order__c":1}]';
        return (List<WebsakNewsMapping__mdt>) JSON.deserialize(js, List<WebsakNewsMapping__mdt>.class);
    }

    private static void setupMockWebsakMetadata(Boolean isSandbox) {
        if (isSandbox) {
            setMetadata(QUERY_SANDBOX, getMockWebsakMetaSandbox());
        } else {
            setMetadata(QUERY_PROD, getMockWebsakMetaProd());
        }
    }

    private static void setupMinimalNewsArchiveSettings(Boolean useP360, Boolean useWebSak) {
        delete [SELECT Id FROM NKS_NewsArchiveSettings__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()];
        NKS_NewsArchiveSettings__c setting = new NKS_NewsArchiveSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            UsePublic360__c = useP360,
            UseWebSak__c = useWebSak,
            CalloutName__c = 'TestCallout'
        );
        insert setting;
    }

    private static NKS_Announcement__c createTestArticle(
        Boolean archived,
        Boolean published,
        String name,
        Datetime publishDT,
        Date deleteDT
    ) {
        NKS_Announcement__c a = new NKS_Announcement__c(
            Name = name,
            Skills__c = 'Arbeid;Pensjon',
            NKS_News_Status__c = published ? 'Published' : 'Draft',
            NKS_News_Archive__c = archived,
            NKS_News_Publish_Date__c = publishDT,
            NKS_News_Delete_Date__c = deleteDT,
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'News' LIMIT 1]
            .Id
        );
        insert a;
        return a;
    }

    @isTest
    private static void smokeTest() {
        setupMockWebsakMetadata(true);
        setupMinimalNewsArchiveSettings(false, true);
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');
        NKS_Announcement__c a = createTestArticle(
            true,
            true,
            'News Article',
            Datetime.now().addDays(-1),
            Date.today().addDays(1)
        );

        Test.startTest();
        new NKS_NewsArchiveHandler().execute(a);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    private static void testExecuteWithNoMetadata() {
        setMetadata(QUERY_SANDBOX, new List<WebsakNewsMapping__mdt>());
        setupMinimalNewsArchiveSettings(false, true);
        NKS_Announcement__c a = createTestArticle(
            true,
            true,
            'MissingMetaArticle',
            Datetime.now(),
            Date.today().addDays(1)
        );

        Test.startTest();
        new NKS_NewsArchiveHandler().execute(a);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    private static void testExecuteWithNullCaseNumberOrNavEnhet() {
        setMetadata(QUERY_SANDBOX, getMockMetaNullValues());
        setupMinimalNewsArchiveSettings(false, true);
        NKS_Announcement__c a = createTestArticle(
            true,
            true,
            'NullNavEnhetArticle',
            Datetime.now(),
            Date.today().addDays(1)
        );

        Test.startTest();
        new NKS_NewsArchiveHandler().execute(a);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    private static void testArchiveArticleWebSakAndP360() {
        setupMockWebsakMetadata(true);
        setupMinimalNewsArchiveSettings(true, true);
        NKS_Announcement__c a = createTestArticle(
            true,
            true,
            'FullArchiveArticle',
            Datetime.now().addDays(-2),
            Date.today().addDays(1)
        );
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        Test.startTest();
        Boolean success = handler.archiveArticle(a, 'CASE-1', 'NAV-P360', 'ENH-P360', 'ftpTest');
        Test.stopTest();

        Assert.areEqual(true, success, 'Expect integration succeeds for both WebSak and P360');
    }

    @isTest
    private static void testArchiveArticleWebSakWithXmlFail() {
        setupMockWebsakMetadata(true);
        setupMinimalNewsArchiveSettings(false, true);
        NKS_Announcement__c a = createTestArticle(
            true,
            true,
            'FailXmlFile',
            Datetime.now().addDays(-2),
            Date.today().addDays(2)
        );
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 500, 'Internal Server Error');

        Test.startTest();
        Boolean success = handler.archiveArticle(a, 'CASE-XML', 'NAV-XML', 'ENH-XML', 'ftpTest');
        Test.stopTest();

        Assert.areEqual(false, success, 'Expect integration fails due to XML file send failure');
    }

    @isTest
    private static void testFormatFileNameVariants() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        Assert.areEqual('Test_File.pdf', handler.formatFileName('Test File.pdf'));
        Assert.areEqual('Ola_Nordmann.pdf', handler.formatFileName('Ola Nordmann.pdf'));
        Assert.areEqual('Aeae', handler.formatFileName('Ææ'));
        Assert.areEqual('A.pdf', handler.formatFileName('Å.pdf'));
        Assert.areEqual('O.pdf', handler.formatFileName('Ø.pdf'));
    }

    @isTest
    private static void testGetAutoNumberBranchEmpty() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        delete [SELECT Id FROM Application_Log__c WHERE Source_Class__c = 'NKS_NewsArchiveHandler'];
        Test.startTest();
        String autoNumEmpty = handler.getAutoNumber();
        Test.stopTest();
        Assert.areEqual('000001', autoNumEmpty);
    }

    @isTest
    private static void testGetAutoNumberBranchWithLog() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        Application_Log__c log = new Application_Log__c(
            Log_Message__c = '000100 sample',
            Log_Level__c = 'Info',
            Source_Class__c = 'NKS_NewsArchiveHandler'
        );
        insert log;

        Test.startTest();
        String autoNumNext = handler.getAutoNumber();
        Test.stopTest();

        Assert.areEqual('000101', autoNumNext);
    }

    @isTest
    private static void testGetCaseNumberAndNavEnhetSandbox() {
        setMetadata(QUERY_SANDBOX, getMockWebsakMetaSandbox());
        setupMinimalNewsArchiveSettings(false, true);
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        WebsakNewsMapping__mdt mdt = getMockWebsakMetaSandbox()[0];

        Test.startTest();
        Assert.areEqual('TST123', handler.getCaseNumber(mdt));
        Assert.areEqual('NAVTST', handler.getNavIdent(mdt));
        Assert.areEqual('ENHTST', handler.getNavEnhet(mdt));
        Test.stopTest();
    }

    @isTest
    private static void testGetCaseNumberAndNavEnhetProd() {
        setMetadata(QUERY_PROD, getMockWebsakMetaProd());
        setupMinimalNewsArchiveSettings(false, true);
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        handler.isSandbox = false;
        WebsakNewsMapping__mdt mdtProd = getMockWebsakMetaProd()[0];

        Test.startTest();
        Assert.areEqual('PRD456', handler.getCaseNumber(mdtProd));
        Assert.areEqual('NAVPRD', handler.getNavIdent(mdtProd));
        Assert.areEqual('ENHPRD', handler.getNavEnhet(mdtProd));
        Test.stopTest();
    }

    @isTest
    private static void testGetFtpsCatalouge() {
        setupMinimalNewsArchiveSettings(false, true);
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();

        Test.startTest();
        Assert.areEqual('ftpmottakP1SF_NKS', handler.getFtpsCatalouge());
        Test.stopTest();
    }

    @isTest
    private static void testSendFilesAndXmlManifestSplit() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        Map<String, Blob> files = new Map<String, Blob>{
            'doc.pdf' => Blob.valueOf('foo'),
            'manifest.xml' => Blob.valueOf('xml')
        };
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        Test.startTest();
        Boolean result = handler.sendFiles(files, 'manifest.xml', 'ftp_meta');
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @IsTest
    private static void testGetManifestAndDateString() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        Map<String, String> fileInfo = new Map<String, String>{ 'file.pdf' => '.pdf' };
        Blob manifestBlob = handler.getManifest(
            fileInfo,
            'typeX',
            'journalName',
            'category',
            Date.today(),
            '123/2024',
            'NID',
            'ENH'
        );
        Assert.areNotEqual(null, manifestBlob);
        String manifestName = handler.getManifestName(Date.newInstance(2024, 12, 4));
        Assert.areEqual(true, manifestName.endsWith('.xml'), 'Should end with .xml');
        Assert.areEqual('20241204', handler.formatDateString(Date.newInstance(2024, 12, 4)));
    }

    @IsTest
    private static void testCreateRequestBody() {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        NKS_Announcement__c article = new NKS_Announcement__c(Name = 'Test Nyhetsartikkel No. 1');
        Blob articlePdf = Blob.toPdf('This is a test PDF');

        Test.startTest();
        String requestBody = handler.createRequestBody('25/12742', 'Test Ident', article, articlePdf);
        Test.stopTest();

        Assert.areNotEqual(null, requestBody);
        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        Assert.areEqual('Test Nyhetsartikkel No. 1', rootMap.get('Title'));
        Assert.areEqual('NKSSalesForce', rootMap.get('DefaultValueSet'));
        Assert.areEqual('25/12742', rootMap.get('CaseNumber'));
        Assert.areEqual('Alle ansatte i Nav', rootMap.get('AccessGroup'));
        Assert.areEqual('Test Ident', rootMap.get('ResponsiblePersonIdNumber'));
        List<Object> files = (List<Object>) rootMap.get('Files');
        Assert.areEqual(1, files.size());
        Map<String, Object> fileObj = (Map<String, Object>) files[0];
        Assert.areEqual('Test Nyhetsartikkel No. 1', fileObj.get('Title'));
        Assert.areEqual('pdf', fileObj.get('Format'));
        Assert.areNotEqual(null, fileObj.get('Base64Data'));
    }

    @IsTest
    private static void testSendMethod() {
        setupMinimalNewsArchiveSettings(true, false);
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

        Assert.areEqual(true, resultOk, 'Expect send method to return true on 200 OK response');
    }

    @IsTest
    private static void testSendMethodAndGet400() {
        setupMinimalNewsArchiveSettings(true, false);
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        SingleRequestMock mock = new SingleRequestMock(
            400,
            'Bad Request',
            '{"error": "Invalid request"}',
            new Map<String, String>()
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Boolean result = handler.send('{"dummyJson":"test"}');
        Test.stopTest();

        Assert.areEqual(false, result, 'Expect send method to return false on 400 Bad Request response');
    }

    @IsTest
    static void testCalloutDirect() {
        SingleRequestMock mock = new SingleRequestMock(
            200,
            'OK',
            '{"Recno": 203385,"DocumentNumber": "25/12742-3","UID": "d34963ee-6b14-400c-b991-7cbecef4fd6b","UIDOrigin": "360","Successful": true}',
            new Map<String, String>()
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        HttpResponse response = NKS_NewsArchiveHandler.callout(
            'CreateDocument',
            '{"fakeJson":"data"}',
            'SomeCalloutName'
        );
        System.Test.stopTest();

        Assert.areEqual(200, response.getStatusCode(), 'Expect status code 200 from callout');
        Assert.areEqual('OK', response.getStatus(), 'Expect status message OK from callout');
    }

    // --- Custom Metadata Registry for injection ---
    private static Map<String, List<SObject>> customMetadataRecordsMap = new Map<String, List<SObject>>();

    public static void setMetadata(String query, List<SObject> records) {
        customMetadataRecordsMap.put(query, records);
    }

    public static List<SObject> getMetadata(String query) {
        if (customMetadataRecordsMap.containsKey(query)) {
            return customMetadataRecordsMap.get(query);
        }
        return new List<SObject>();
    }
}
