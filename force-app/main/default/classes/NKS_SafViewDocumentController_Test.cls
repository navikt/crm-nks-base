@IsTest
private with sharing class NKS_SafViewDocumentController_Test {
    @IsTest
    static void safViewDocumentControllerTestConstructor() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId', '12345');
        ApexPages.currentPage().getParameters().put('documentInfoId', '54321');
        ApexPages.currentPage().getParameters().put('variantFormat', 'ARKIV');
        ApexPages.currentPage().getParameters().put('fileName', 'myTestFile.pdf');

        NKS_SafViewDocumentController ctrl;
        Test.startTest();
        ctrl = new NKS_SafViewDocumentController();
        Test.stopTest();

        System.assertEquals(
            '12345',
            ctrl.journalId,
            'Expected journalId to be set with the correct value in constructor'
        );
        System.assertEquals(
            '54321',
            ctrl.documentInfoId,
            'Expected documentInfoId to be set with the correct value in constructor'
        );
        System.assertEquals(
            'ARKIV',
            ctrl.variantFormat,
            'Expected variantFormat to be set with the correct value in constructor'
        );
        System.assertEquals(
            'myTestFile.pdf',
            ctrl.fileName,
            'Expected fileName to be set with the correct value in constructor'
        );
        System.assertEquals(
            'myTestFile.pdf',
            ctrl.title,
            'Expected title to be set with the correct value in constructor'
        );
        System.assertEquals(
            'myTestFile.pdf',
            ApexPages.currentPage().getHeaders().get('filename'),
            'Expected the header filename to be set correct'
        );
        System.assertEquals(
            true,
            String.isBlank(ctrl.errorTitle),
            'Expected to not have an error title'
        );
        System.assertEquals(
            true,
            String.isBlank(ctrl.errorMessage),
            'Expected to not have an error message'
        );
        System.assertEquals(
            false,
            ctrl.initialised,
            'Expected initialised to be set to false in constructor'
        );
        System.assertEquals(
            false,
            ctrl.isError,
            'Expected isError to be set to false in constructor'
        );
    }

    @IsTest
    static void safViewDocumentControllerTestConstructorOnlyRequired() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId', '12345');
        ApexPages.currentPage().getParameters().put('documentInfoId', '54321');

        NKS_SafViewDocumentController ctrl;
        Test.startTest();
        ctrl = new NKS_SafViewDocumentController();
        Test.stopTest();

        System.assertEquals(
            '12345',
            ctrl.journalId,
            'Expected journalId to be set with the correct value in constructor'
        );
        System.assertEquals(
            '54321',
            ctrl.documentInfoId,
            'Expected documentInfoId to be set with the correct value in constructor'
        );
        System.assertEquals(
            'ARKIV',
            ctrl.variantFormat,
            'Expected variantFormat to be set with the correct value in constructor'
        );
        System.assertEquals(
            'dokument',
            ctrl.fileName,
            'Expected fileName to be set with the correct value in constructor'
        );
        System.assertEquals(
            'dokument',
            ctrl.title,
            'Expected title to be set with the correct in constructor'
        );
        System.assertEquals(
            'dokument',
            ApexPages.currentPage().getHeaders().get('filename'),
            'Expected the header filename to be set correct'
        );
        System.assertEquals(
            true,
            String.isBlank(ctrl.errorTitle),
            'Expected to not have an error title'
        );
        System.assertEquals(
            true,
            String.isBlank(ctrl.errorMessage),
            'Expected to not have an error message'
        );
        System.assertEquals(
            false,
            ctrl.initialised,
            'Expected initialised to be set to false in constructor'
        );
        System.assertEquals(
            false,
            ctrl.isError,
            'Expected isError to be set to false in constructor'
        );
    }

    @IsTest
    static void safViewDocumentControllerNoParameters() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);

        NKS_SafViewDocumentController ctrl;
        Test.startTest();
        ctrl = new NKS_SafViewDocumentController();
        Test.stopTest();

        System.assertEquals(
            true,
            String.isNotBlank(ctrl.errorTitle),
            'Expected to have an error title'
        );
        System.assertEquals(
            true,
            String.isNotBlank(ctrl.errorMessage),
            'Expected to have an error message'
        );
        System.assertEquals(
            false,
            ctrl.initialised,
            'Expected initialised to be set to false in constructor'
        );
        System.assertEquals(
            true,
            ctrl.isError,
            'Expected isError to be set to false in constructor'
        );
    }

    @IsTest
    static void getDocumentMethodWithSuccess() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId', '12345');
        ApexPages.currentPage().getParameters().put('documentInfoId', '54321');
        ApexPages.currentPage().getParameters().put('variantFormat', 'ARKIV');
        ApexPages.currentPage().getParameters().put('fileName', 'myTestFile.pdf');

        NKS_SafViewDocumentController ctrl = new NKS_SafViewDocumentController();

        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'inline; filename="myTestFile.pdf"'
        };

        SingleRequestMock mock = new SingleRequestMock(200, 'Success', 'TEST_STRING', headers);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ctrl.getDocument();
        Test.stopTest();

        System.assertEquals(
            true,
            ctrl.documentData.startsWith('data:application/pdf;base64,VEVTVF9TVFJJTkc='),
            'Did not manage to set the correct start string, got ' + ctrl.documentData
        );
        System.assertEquals(
            'inline; filename="myTestFile.pdf"',
            ApexPages.currentPage().getHeaders().get('content-disposition'),
            'Expected the header content-disposition to be set correct'
        );
        System.assertEquals(
            true,
            String.isBlank(ctrl.errorTitle),
            'Expected to not have an error title'
        );
        System.assertEquals(
            true,
            String.isBlank(ctrl.errorMessage),
            'Expected to not have an error message'
        );
        System.assertEquals(
            true,
            ctrl.initialised,
            'Expected initialised to be set to true after getting document'
        );
        System.assertEquals(false, ctrl.isError, 'Expected isError to be set to false');
    }

    @IsTest
    static void getDocumentMethodWithError() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId', '12345');
        ApexPages.currentPage().getParameters().put('documentInfoId', '54321');
        ApexPages.currentPage().getParameters().put('variantFormat', 'ARKIV');
        ApexPages.currentPage().getParameters().put('fileName', 'myTestFile.pdf');

        NKS_SafViewDocumentController ctrl = new NKS_SafViewDocumentController();
        NKS_SafError error = new NKS_SafError();
        error.error = 'Unauthorized';
        error.status = 401;
        error.message = 'Vi kan ikke autorisere bruker gjennom token eller system som har gitt token er ukjent for saf.';
        error.path = '/rest/hentdokument';
        error.timestamp = Datetime.now();

        SingleRequestMock mock = new SingleRequestMock(
            401,
            'Unauthorized',
            JSON.serialize(error),
            new Map<String, String>()
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ctrl.getDocument();
        Test.stopTest();

        System.assertEquals(
            true,
            String.isBlank(ctrl.documentData),
            'Did not expect this to be set'
        );
        System.assertEquals(
            true,
            ctrl.errorTitle.containsIgnoreCase(error.error),
            'Expected to have an error title containing the error type from the response'
        );
        System.assertEquals(
            error.message,
            ctrl.errorMessage,
            'Expected to have the error message from the response.'
        );
        System.assertEquals(
            true,
            ctrl.initialised,
            'Expected initialised to be set to true after getting document'
        );
        System.assertEquals(true, ctrl.isError, 'Expected isError to be set to true');
    }

    @IsTest
    static void getDocumentWithException() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId', '12345');
        ApexPages.currentPage().getParameters().put('documentInfoId', '54321');
        ApexPages.currentPage().getParameters().put('variantFormat', 'ARKIV');
        ApexPages.currentPage().getParameters().put('fileName', 'myTestFile.pdf');

        NKS_SafViewDocumentController ctrl = new NKS_SafViewDocumentController();

        Test.startTest();
        ctrl.getDocument();
        Test.stopTest();

        System.assertEquals(
            true,
            String.isBlank(ctrl.documentData),
            'Did not expect this to be set'
        );
        System.assertEquals(
            true,
            String.isNotBlank(ctrl.errorTitle),
            'Expected to have an error title'
        );
        System.assertEquals(
            true,
            String.isNotBlank(ctrl.errorMessage),
            'Expected to have an error message'
        );
        System.assertEquals(
            true,
            ctrl.initialised,
            'Expected initialised to be set to true after getting document'
        );
        System.assertEquals(true, ctrl.isError, 'Expected isError to be set to true');
    }
}
