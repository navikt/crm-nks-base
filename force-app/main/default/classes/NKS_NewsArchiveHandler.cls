@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity')
public with sharing class NKS_NewsArchiveHandler {
    private static final String JOURNAL_POST_STATUS = 'J';
    private static final String INCOMING_POST = 'X';
    private static final String BUSINESS_UNIT = 'Nav styringsenhet kontaktsenter';
    private static final String MANIFEST_FORMAT = '.xml';
    private static final String DEFAULT_FILE_FORMAT = '.pdf';
    private static final String JOURNAL_POST_TYPE = 'Nyheter NKS';
    private static final String FTPS_CATALOUGE_PROD = 'ftpmottak_SF_NKS';
    private static final String FTPS_CATALOUGE_TEST = 'ftpmottakP1SF_NKS';

    /**
     * @description This constant is used to define the document service in the Public 360 API.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    public static final String DOCUMENT_SERVICE = 'DocumentService';

    /**
     * @description The operation type for creating a document in Public 360.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    public static final String CREATE_DOCUMENT = 'CreateDocument';

    private string errorMessage = '';
    private Boolean isSandbox;

    /**
     * @description The news archive settings for the organization.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    private NKS_NewsArchiveSettings__c newsArchiveSettings;
    /**
     * @description Boolean to indicate if the Public 360 integration should be used.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    private Boolean useP360 = false;
    /**
     * @description Boolean to indicate if the WebSak integration should be used.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    private Boolean useWebSak = false;

    /**
     * @description The Http Response object that is returned from the operation.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     */
    @TestVisible
    public HttpResponse operationResponse { get; private set; }

    public NKS_NewsArchiveHandler() {
        this.newsArchiveSettings = NKS_NewsArchiveSettings__c.getOrgDefaults();
        this.useP360 = this.newsArchiveSettings.UsePublic360__c;
        this.useWebSak = this.newsArchiveSettings.UseWebSak__c;
        this.isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    public void execute(NKS_Announcement__c article) {
        String ftpsCatalouge = getFtpsCatalouge();
        WebsakNewsMapping__mdt settings = getSettings();
        if (settings == null) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Fant ikke metadata for ' + article.Name, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return;
        }
        String caseNumber = getCaseNumber(settings);
        String navIdent = getNavIdent(settings);
        String navEnhet = getNavEnhet(settings);
        if (caseNumber == null || navIdent == null || navEnhet == null) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                'Fant ikke saksnummer/NAV-Ident/NAV-enhet for ' + article.Name,
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
            return;
        }
        archiveArticle(article, caseNumber, navIdent, navEnhet, ftpsCatalouge);
        return;
    }
    @TestVisible
    private String getCaseNumber(WebsakNewsMapping__mdt settings) {
        if (settings == null)
            return null;
        return isSandbox ? settings.CaseNumberTest__c : settings.CaseNumberProd__c;
    }
    private String getNavIdent(WebsakNewsMapping__mdt settings) {
        if (settings == null)
            return null;
        return isSandbox ? settings.NavIdTest__c : settings.NavIdProd__c;
    }
    private String getNavEnhet(WebsakNewsMapping__mdt settings) {
        if (settings == null)
            return null;
        return isSandbox ? settings.NavEnhetTest__c : settings.NavEnhetProd__c;
    }
    private WebsakNewsMapping__mdt getSettings() {
        if (isSandbox) {
            return [
                SELECT Id, CaseNumberTest__c, NavIdTest__c, NavEnhetTest__c, ActiveFrom__c, Order__c
                FROM WebsakNewsMapping__mdt
                WHERE ActiveFrom__c <= TODAY
                ORDER BY ActiveFrom__c DESC, Order__c DESC
                LIMIT 1
            ];
        } else {
            return [
                SELECT Id, CaseNumberProd__c, NavIdProd__c, NavEnhetProd__c, ActiveFrom__c, Order__c
                FROM WebsakNewsMapping__mdt
                WHERE ActiveFrom__c <= TODAY
                ORDER BY ActiveFrom__c DESC, Order__c DESC
                LIMIT 1
            ];
        }
    }

    /**
     * @description This method is used to archive the article to the FTPS catalouge.
     *
     * @param article Article to archive
     * @param caseNumber Case number
     * @param navIdent Nav ident
     * @param navEnhet Nav enhet
     * @param ftpsCatalouge fps catalouge
     * @return  `Boolean` Indicate the status if the article was successfully archived.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    @TestVisible
    private Boolean archiveArticle(
        NKS_Announcement__c article,
        String caseNumber,
        String navIdent,
        String navEnhet,
        String ftpsCatalouge
    ) {
        Blob articlePdf;
        if (Test.isRunningTest()) {
            articlePdf = blob.valueOf('Unit.Test');
        } else {
            articlePdf = NKS_NewsArticlePdfGenerator.getPdf(article.Id);
            //articlePdf = Blob.toPdf('This is a test PDF');
        }

        Map<String, Blob> filesToSend = new Map<String, Blob>();
        Map<String, String> fileNameFormatMap = new Map<String, String>();
        String manifestName;
        if (this.useWebSak) {
            String articleFileName = formatFileName(article.Name + DEFAULT_FILE_FORMAT);

            manifestName = getManifestName(article.NKS_News_Publish_Date__c.date());
            filesToSend.put(articleFileName, articlePdf);
            fileNameFormatMap.put(articleFileName, DEFAULT_FILE_FORMAT);

            Blob manifestBlob;
            if (Test.isRunningTest()) {
                manifestBlob = blob.valueOf('Unit.Test');
            } else {
                manifestBlob = getManifest(
                    fileNameFormatMap,
                    INCOMING_POST,
                    getJournalPostName(JOURNAL_POST_TYPE, article.Name),
                    article.Skills__c != null ? article.Skills__c.replaceAll(';', ' - ') : '',
                    Date.today(),
                    caseNumber,
                    navIdent,
                    navEnhet
                );
            }

            filesToSend.put(manifestName, manifestBlob);
        }

        Boolean isSuccess = false;
        if (this.useWebSak) {
            isSuccess = sendFiles(filesToSend, manifestName, ftpsCatalouge);
        }

        if (isSuccess) {
            LoggerUtility logger = new LoggerUtility();
            logger.info(manifestName, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }

        if (this.useP360) {
            String requestBody = createRequestBody(caseNumber, navIdent, article, articlePdf);
            isSuccess = send(requestBody);
        }

        return isSuccess;
    }

    private Boolean sendFiles(Map<String, Blob> files, String xmlManifestName, String ftpsCatalouge) {
        Boolean success = true;
        String xmlFileName;
        Blob xmlFileContent;

        if (files.containsKey(xmlManifestName)) {
            xmlFileName = xmlManifestName;
            xmlFileContent = files.get(xmlManifestName);
            files.remove(xmlManifestName);
        }

        for (String file : files.keySet()) {
            Blob fileData = files.get(file);
            WebSakFileService.WebSakFileResponse response = new WebSakFileService()
                .postFile(file, fileData, ftpsCatalouge);

            if (!response.success) {
                success = false;
            }
        }

        if (xmlFileName != null && xmlFileContent != null) {
            success = sendXmlManifest(xmlFileName, xmlFileContent, ftpsCatalouge);
        }
        return success;
    }

    private Boolean sendXmlManifest(String xmlFileName, Blob xmlFileContent, String ftpsCatalouge) {
        WebSakFileService.WebSakFileResponse xmlResponse = new WebSakFileService()
            .postFile(xmlFileName, xmlFileContent, ftpsCatalouge);

        if (!xmlResponse.success) {
            return false;
        }
        return true;
    }

    @TestVisible
    private Blob getManifest(
        Map<String, String> fileInfo,
        String postType,
        String journalPostName,
        String category,
        Date referenceDate,
        String caseNumber,
        String navIdent,
        String navEnhet
    ) {
        NKS_NewsXMLGenerator generator = new NKS_NewsXMLGenerator();
        generator.businessUnitId = navEnhet;
        generator.businessUnitName = BUSINESS_UNIT;
        generator.journalPostStatus = JOURNAL_POST_STATUS;
        generator.journalPostType = postType;
        generator.journalPostName = journalPostName;
        generator.journalPostCategory = category;
        generator.journalCaseNumber = caseNumber;
        generator.userNavIdent = navIdent;
        generator.submissionDate = referenceDate;
        generator.documentNameFormat = fileInfo;

        return Blob.valueOf(generator.generateXML());
    }

    private String getManifestName(Date archiveDate) {
        return getAutoNumber() + '_NyheterNKS_' + formatDateString(archiveDate) + MANIFEST_FORMAT;
    }

    private String getJournalPostName(String type, String caseNumber) {
        return type + ' - ' + caseNumber.replaceAll('-', '');
    }

    private String formatFileName(String fileName) {
        // replace ' ', '\', '/', '(', and ')' with '_'
        // replace 'ÅåØøÆæ' with AaOoAeae'
        // skip '.pdf' at the end of string and delete all non-word characters [^a-zA-Z_0-9]

        String s = fileName.replaceAll('Å', 'A');
        s = s.replaceAll('å', 'a');
        s = s.replaceAll('Ø', 'O');
        s = s.replaceAll('ø', 'o');
        s = s.replaceAll('Æ', 'Ae');
        s = s.replaceAll('æ', 'ae');
        s = s.replaceAll(' |\\\\|\\/|\\(|\\)', '_');
        s = s.replaceAll('(?!\\.pdf$)\\W', '');
        return s;
    }

    private String formatDateString(Date input) {
        Datetime dateToFormat = input;
        return dateToFormat.formatGmt('yyyyMMdd');
    }

    @TestVisible
    private String getAutoNumber() {
        List<Application_Log__c> lastTransaction = [
            SELECT Log_Message__c
            FROM Application_Log__c
            WHERE Log_Level__c = 'Info' AND Source_Class__c = 'NKS_NewsArchiveHandler'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (lastTransaction.size() == 0) {
            return '000001';
        }

        String lastFileName = lastTransaction[0].Log_Message__c.substring(0, 6);
        Integer latUsedNumber = Integer.valueOf(lastFileName);
        Integer newAutoNumber = 1000001 + latUsedNumber;
        return String.valueOf(newAutoNumber).substring(1, 7);
    }

    private String getFtpsCatalouge() {
        if (isSandbox) {
            return FTPS_CATALOUGE_TEST;
        }
        return FTPS_CATALOUGE_PROD;
    }

    /**
     * @description This method is used to create the request body for the Public 360 API with the given article and article PDF.
     *
     * Body:
     * {
     *     "Title":"Test Nyhetsartikkel No. 1",
     *     "DefaultValueSet":"NKSSalesForce",
     *     "CaseNumber":"25/12742",
     *     "AccessGroup":"Alle ansatte i Nav",
     *     "ResponsiblePersonIdNumber":"Nav Ident til ansvarlig person",
     *     "Files":[
     *         {
     *             "Title": "Test Nyhetsartikkel No. 1",
     *             "Format": "txt",
     *             "Base64Data": "RGV0dGUgZXIgYmVycmUgZWluIGVua2VsIHRlc3Q="
     *         }
     *     ]
     *  }
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     * @param caseNumber The case number for the article.
     * @param navIdent The NAV Ident for the article.
     * @param article The article to create the request body for.
     * @param articlePdf The article PDF to include in the request body.
     * @return  `String`The request body for the Public 360 API Create Document.
     */
    @TestVisible
    private String createRequestBody(String caseNumber, String navIdent, NKS_Announcement__c article, Blob articlePdf) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
        generator.writeStringField('Title', article.Name);
        generator.writeStringField('DefaultValueSet', 'NKSSalesForce');
        generator.writeStringField('CaseNumber', caseNumber);
        generator.writeStringField('AccessGroup', 'Alle ansatte i Nav');
        generator.writeStringField('ResponsiblePersonIdNumber', navIdent);
        generator.writeFieldName('Files');
        generator.writeStartArray();
        generator.writeStartObject();
        generator.writeStringField('Title', article.Name);
        generator.writeStringField('Format', 'pdf');
        generator.writeStringField('Base64Data', EncodingUtil.base64Encode(articlePdf));
        generator.writeEndObject();
        generator.writeEndArray();
        generator.writeEndObject();

        return generator.getAsString();
    }

    /**
     * @description This method is used to send the request to the Public 360 API.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     * @return `Boolean` Indicate the status if the request was successfully sent.
     */
    public Boolean send(String requestBody) {
        this.operationResponse = callout(CREATE_DOCUMENT, requestBody, this.newsArchiveSettings.CalloutName__c);

        if (this.operationResponse.getStatusCode() != 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                'Error: ' + this.operationResponse.getStatusCode() + ' - ' + this.operationResponse.getStatus(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
            return false;
        }

        return true;
    }

    /**
     * @description This method is used to perform the callout to the Public 360 API.
     *
     * @author Kenneth Soerensen <kenneth.sorensen@nav.no>, Nav
     * @since 0.1.0, March 2025
     * @param operationType The operation type to perform.
     * @param requestBody The request body to send.
     * @param calloutName The name of the callout to use.
     */
    @TestVisible
    private static HttpResponse callout(String operationType, String requestBody, String calloutName) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + calloutName + '/' + DOCUMENT_SERVICE + '/' + operationType);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(requestBody);

        Http http = new Http();
        HttpResponse response = http.send(request);

        return response;
    }
}
