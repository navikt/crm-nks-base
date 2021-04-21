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
    @TestVisible
    private string journalId;
    @TestVisible
    private string documentInfoId;

    public Boolean initialised { get; set; }
    public Boolean isError { get; set; }

    public transient String documentData { public get; private set; }
    public string title { get; set; }
    public string errorTitle { get; set; }
    public string errorMessage { get; set; }

    //With default values
    public string fileName {
        public get {
            if (String.isBlank(fileName)) {
                return 'dokument';
            }
            return fileName;
        }
        private set;
    }
    public string variantFormat {
        public get {
            if (String.isBlank(variantFormat)) {
                return 'ARKIV';
            }
            return variantFormat;
        }
        private set;
    }
    public string contentDisposition {
        public get {
            if (String.isBlank(contentDisposition)) {
                return 'inline';
            }
            return contentDisposition;
        }
        private set;
    }
    public string contentType {
        public get {
            if (String.isBlank(contentType)) {
                return 'application/pdf';
            }
            return contentType;
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

        journalId = getPageParameter('journalId');
        documentInfoId = getPageParameter('documentInfoId');
        variantFormat = getPageParameter('variantFormat');
        fileName = getPageParameter('fileName');

        title = fileName;

        setPageHeader('filename', fileName);
        setPageHeader('content-disposition', contentDisposition);

        validateParameters();
    }

    /**
     * Validate that we have the required parameters to actually get the document.
     */
    private void validateParameters() {
        if (String.isBlank(journalId) || String.isBlank(documentInfoId)) {
            setError('Kan ikke hente dokument.', 'Mangler journalpost id og dokument id.');
        }
    }

    /**
     * Get the document from SAF and create the document data string
     */
    public void getDocument() {
        contentDisposition = '';
        contentType = 'application/pdf';

        NKS_SafService service = new NKS_SafService();

        try {
            NKS_SafGetDocumentResponse response = service.getSafDocument(journalId, documentInfoId, variantFormat);

            if (true == response.isSuccess) {
                contentType = response.contentType;
                contentDisposition = response.contentDisposition;

                setPageHeader('content-disposition', contentDisposition);

                documentData = 'data:' + contentType + ';base64,' + response.documentString + '#toolbar=0&zoom=100';
            } else {
                setError('Kunne ikke laste dokumentet [' + response.error.error + '].', response.error.message);
            }
        } catch (Exception ex) {
            setError('Kunne ikke laste dokumentet.', ex.getMessage());
        }

        initialised = true;
    }

    private void setPageHeader(String key, String value) {
        Apexpages.currentPage().getHeaders().put(key, value);
    }

    private String getPageParameter(String key) {
        return System.currentPagereference().getParameters().get(key);
    }

    private void setError(String title, String message) {
        errorTitle = title;
        errorMessage = message;
        isError = true;
    }
}
