@IsTest
private with sharing class NKS_SafViewDocumentController_Test {
    @IsTest static void safViewDocumentController_TestConstructor() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId','12345');
        ApexPages.currentPage().getParameters().put('documentInfoId','54321');
        ApexPages.currentPage().getParameters().put('variantFormat','ARKIV');
        ApexPages.currentPage().getParameters().put('fileName','myTestFile.pdf');
        ApexPages.currentPage().getParameters().put('width','10%');
        ApexPages.currentPage().getParameters().put('height','10px');

        NKS_SafViewDocumentController ctrl;
        Test.startTest();
        ctrl = new NKS_SafViewDocumentController();
        Test.stopTest();

        System.assertEquals('12345', ctrl.journalId, 'Expected journalId to be set with the correct value in constructor');
        System.assertEquals('54321', ctrl.documentInfoId, 'Expected documentInfoId to be set with the correct value in constructor');
        System.assertEquals('ARKIV', ctrl.variantFormat, 'Expected variantFormat to be set with the correct value in constructor');
        System.assertEquals('myTestFile.pdf', ctrl.fileName, 'Expected fileName to be set with the correct value in constructor');
        System.assertEquals('10%', ctrl.width, 'Expected width to be set with the correct value in constructor');
        System.assertEquals('10px', ctrl.height, 'Expected height to be set with the correct value in constructor');
        System.assertEquals('myTestFile.pdf', ctrl.title, 'Expected title to be set with the correct value in constructor');
        System.assertEquals('myTestFile.pdf', ApexPages.currentPage().getHeaders().get('filename'), 'Expected the header filename to be set correct');
        System.assertEquals(true, String.isBlank(ctrl.errorTitle), 'Expected to not have an error title');
        System.assertEquals(true, String.isBlank(ctrl.errorMessage), 'Expected to not have an error message');
        System.assertEquals(false, ctrl.initialised, 'Expected initialised to be set to false in constructor');
        System.assertEquals(false, ctrl.isError, 'Expected isError to be set to false in constructor');
    }

    @IsTest static void safViewDocumentController_TestConstructorOnlyRequired() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId','12345');
        ApexPages.currentPage().getParameters().put('documentInfoId','54321');

        NKS_SafViewDocumentController ctrl;
        Test.startTest();
        ctrl = new NKS_SafViewDocumentController();
        Test.stopTest();

        System.assertEquals('12345', ctrl.journalId, 'Expected journalId to be set with the correct value in constructor');
        System.assertEquals('54321', ctrl.documentInfoId, 'Expected documentInfoId to be set with the correct value in constructor');
        System.assertEquals('ARKIV', ctrl.variantFormat, 'Expected variantFormat to be set with the correct value in constructor');
        System.assertEquals('dokument', ctrl.fileName, 'Expected fileName to be set with the correct value in constructor');
        System.assertEquals('100%', ctrl.width, 'Expected width to be set with the correct value in constructor');
        System.assertEquals('900px', ctrl.height, 'Expected height to be set with the correct value in constructor');
        System.assertEquals('dokument', ctrl.title, 'Expected title to be set with the correct in constructor');
        System.assertEquals('dokument', ApexPages.currentPage().getHeaders().get('filename'), 'Expected the header filename to be set correct');
        System.assertEquals(true, String.isBlank(ctrl.errorTitle), 'Expected to not have an error title');
        System.assertEquals(true, String.isBlank(ctrl.errorMessage), 'Expected to not have an error message');
        System.assertEquals(false, ctrl.initialised, 'Expected initialised to be set to false in constructor');
        System.assertEquals(false, ctrl.isError, 'Expected isError to be set to false in constructor');
    }

    @IsTest static void safViewDocumentController_NoParameters() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);

        NKS_SafViewDocumentController ctrl;
        Test.startTest();
        ctrl = new NKS_SafViewDocumentController();
        Test.stopTest();

        System.assertEquals(true, String.isNotBlank(ctrl.errorTitle), 'Expected to have an error title');
        System.assertEquals(true, String.isNotBlank(ctrl.errorMessage), 'Expected to have an error message');
        System.assertEquals(false, ctrl.initialised, 'Expected initialised to be set to false in constructor');
        System.assertEquals(true, ctrl.isError, 'Expected isError to be set to false in constructor');
    }

    @IsTest static void getDocumentMethod_WithSuccess() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId','12345');
        ApexPages.currentPage().getParameters().put('documentInfoId','54321');
        ApexPages.currentPage().getParameters().put('variantFormat','ARKIV');
        ApexPages.currentPage().getParameters().put('fileName','myTestFile.pdf');
        ApexPages.currentPage().getParameters().put('width','10%');
        ApexPages.currentPage().getParameters().put('height','10px');
        
        NKS_SafViewDocumentController ctrl = new NKS_SafViewDocumentController();

        NKS_SafServiceMock mock = new NKS_SafServiceMock();
        NKS_SafApexTypes.SafGetDocumentResponse documentResponse = new NKS_SafApexTypes.SafGetDocumentResponse();
        documentResponse.isSuccess = true;
        documentResponse.documentString = 'TEST_STRING';
        documentResponse.contentType = 'application/pdf';
        documentResponse.contentDisposition = 'inline';

        mock.addSafGetDocumentResponse(documentResponse);
        NKS_SafService service = (NKS_SafService) Test.createStub(NKS_SafService.class, mock);

        Test.startTest();
        ctrl.getDocument(service);
        Test.stopTest();

        System.assertEquals(true, ctrl.documentData.startsWith('data:application/pdf;base64,TEST_STRING'), 'Did not manage to set the correct start string');
        System.assertEquals('inline', ApexPages.currentPage().getHeaders().get('content-disposition'), 'Expected the header content-disposition to be set correct');
        System.assertEquals(true, String.isBlank(ctrl.errorTitle), 'Expected to not have an error title');
        System.assertEquals(true, String.isBlank(ctrl.errorMessage), 'Expected to not have an error message');
        System.assertEquals(true, ctrl.initialised, 'Expected initialised to be set to true after getting document');
        System.assertEquals(false, ctrl.isError, 'Expected isError to be set to false');
    }

    @IsTest static void getDocument_WithException() {
        Pagereference viewDocument = Page.NKS_SafViewDocument;
        Test.setCurrentPage(viewDocument);
        ApexPages.currentPage().getParameters().put('journalId','12345');
        ApexPages.currentPage().getParameters().put('documentInfoId','54321');
        ApexPages.currentPage().getParameters().put('variantFormat','ARKIV');
        ApexPages.currentPage().getParameters().put('fileName','myTestFile.pdf');
        ApexPages.currentPage().getParameters().put('width','10%');
        ApexPages.currentPage().getParameters().put('height','10px');
        
        NKS_SafViewDocumentController ctrl = new NKS_SafViewDocumentController();

        Test.startTest();
        ctrl.getDocument();
        Test.stopTest();

        System.assertEquals(true, String.isBlank(ctrl.documentData), 'Did not expect this to be set');
        System.assertEquals(true, String.isNotBlank(ctrl.errorTitle), 'Expected to have an error title');
        System.assertEquals(true, String.isNotBlank(ctrl.errorMessage), 'Expected to have an error message');
        System.assertEquals(true, ctrl.initialised, 'Expected initialised to be set to true after getting document');
        System.assertEquals(true, ctrl.isError, 'Expected isError to be set to true');
    }
}
