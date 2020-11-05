/**
 * Controller or the Visualforce Page NKS_SafViewDocument
 * 
 * The VF page accepts the following url parameters
 * journalId *required
 * documentInfoId *required
 * variantFormat
 * fileName
 * width
 * height
*/
public with sharing class NKS_SafViewDocumentController {
    @TestVisible private string journalId;
    @TestVisible private string documentInfoId;
    
    public Boolean initialised{get; set;}
    public Boolean isError{get; set;}
    
    public string documentData { public get; public set; }
    public string title {get; set;}
    public string contentType {get; set;}
    public string errorMessage {get; set;}
    
    //With default values
    public string fileName {
        public get {
            if(String.isBlank(fileName)) { return 'dokument'; }
            return fileName;
        }
        private set;
    }
    public string variantFormat {
        public get {
            if(String.isBlank(variantFormat)) { return 'ARKIV'; }
            return variantFormat;
        }
        private set;
    }
    public string width {
        public get {
            if(String.isBlank(width)) { return '100%'; }
            return width;
        }
        private set;
    }
    public string height {
        public get {
            if(String.isBlank(height)) { return '900px'; }
            return height;
        }
        private set;
    }


    /**
     * Constructor.
     * Get the parameters from the URL and add those properties to the iFrame
     */
    public NKS_SafViewDocumentController() {
        initialised = false;
        isError = false;

        journalId = System.currentPagereference().getParameters().get('journalId');
        documentInfoId = System.currentPagereference().getParameters().get('documentInfoId');
        variantFormat = System.currentPagereference().getParameters().get('variantFormat');
        fileName = System.currentPagereference().getParameters().get('fileName');

        width = System.currentPagereference().getParameters().get('width');
        height = System.currentPagereference().getParameters().get('height');
        title = fileName;

        Apexpages.currentPage().getHeaders().put('filename',fileName);

        validateParameters();
    }

    /**
     * Validate that we have the required parameters to actually get the document.
     */
    private void validateParameters() {
        if(String.isBlank(journalId) || String.isBlank(documentInfoId)) {
            isError = true;
            errorMessage = 'Kan ikke hente dokument. Mangler journalpost id og dokument id.';
        }
    }

    /**
     * Get the document from SAF and create the document data string
     */
    public void getDocument() {
        getDocument(new NKS_SafService());
    }

    /**
     * Get the document from SAF and create the document data string
     */
    public void getDocument(NKS_SafService service) {
        try {
            NKS_SafApexTypes.SafGetDocumentResponse response = service.getSafDocument(journalId,documentInfoId,variantFormat);
        
            Apexpages.currentPage().getHeaders().put('content-disposition', response.contentDisposition);
            documentData='data:'+response.contentType+';base64,'+response.documentString+'#statusbar=0&messages=0&view=Fit&toolbar=0';
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
            isError = true;
        }
        
        initialised = true;
    }
}
