public with sharing class NKS_ArticleArchiveHandler {
    private static final String JOURNAL_POST_STATUS = 'J';
    private static final String INCOMING_POST = 'X';
    private static final String BUSINESS_UNIT = 'NAV Styringsenhet Kontaktsenter';
    private static final String MANIFEST_FORMAT = '.xml';
    private static final String DEFAULT_FILE_FORMAT = '.pdf';
    private static final String FTPS_CATALOUGE_PROD = 'ftpmottak_SF_NKS';
    private static final String FTPS_CATALOUGE_TEST = 'ftpmottakP1SF_NKS';

    private string errorMessage = '';
    private Boolean isSandbox;
    private String settingName;
    private String journalPostType;

    public NKS_ArticleArchiveHandler(String settingName, String journalPostType) {
        this.settingName = settingName;
        this.journalPostType = journalPostType;
        isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]?.IsSandbox;
    }

    public void execute(NKS_Announcement__c article) {
        String ftpsCatalouge = getFtpsCatalouge();
        SObject settings = getSettings(settingName);

        if (settings == null) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Metadata not found for ' + article.Name, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return;
        }
        String caseNumber = getCaseNumber(settings);
        String navIdent = getNavIdent(settings);
        String navEnhet = getNavEnhet(settings);

        if (caseNumber == null || navIdent == null || navEnhet == null) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                'Missing case number/NAV Ident/NAV unit for ' + article.Name,
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
            return;
        }
        archiveArticle(article, caseNumber, navIdent, navEnhet, ftpsCatalouge);
    }

    @TestVisible
    private String getCaseNumber(SObject settings) {
        return (settings != null)
            ? (isSandbox ? (String) settings.get('CaseNumberTest__c') : (String) settings.get('CaseNumberProd__c'))
            : null;
    }

    private String getNavIdent(SObject settings) {
        return (settings != null)
            ? (isSandbox ? (String) settings.get('NavIdTest__c') : (String) settings.get('NavIdProd__c'))
            : null;
    }

    private String getNavEnhet(SObject settings) {
        return (settings != null)
            ? (isSandbox ? (String) settings.get('NavEnhetTest__c') : (String) settings.get('NavEnhetProd__c'))
            : null;
    }

    private SObject getSettings(String settingName) {
        String query;
        if (isSandbox) {
            query =
                'SELECT Id, CaseNumberTest__c, NavIdTest__c, NavEnhetTest__c, ActiveFrom__c, Order__c ' +
                'FROM ' +
                settingName +
                ' WHERE ActiveFrom__c <= TODAY ' +
                'ORDER BY ActiveFrom__c DESC, Order__c DESC ' +
                'LIMIT 1';
        } else {
            query =
                'SELECT Id, CaseNumberProd__c, NavIdProd__c, NavEnhetProd__c, ActiveFrom__c, Order__c ' +
                'FROM ' +
                settingName +
                ' WHERE ActiveFrom__c <= TODAY ' +
                'ORDER BY ActiveFrom__c DESC, Order__c DESC ' +
                'LIMIT 1';
        }
        return Database.query(query);
    }

    @TestVisible
    private Boolean archiveArticle(
        NKS_Announcement__c article,
        String caseNumber,
        String navIdent,
        String navEnhet,
        String ftpsCatalouge
    ) {
        String articleFileName = formatFileName(article.Name + DEFAULT_FILE_FORMAT);
        Blob articlePdf;

        if (Test.isRunningTest()) {
            articlePdf = Blob.valueOf('Unit.Test');
        } else {
            articlePdf = NKS_ArticlePDFGenerator.getPdf(article.Id);
        }

        Map<String, Blob> filesToSend = new Map<String, Blob>();
        Map<String, String> fileNameFormatMap = new Map<String, String>();
        String manifestName = getManifestName(article.NKS_News_Publish_Date__c.date());
        filesToSend.put(articleFileName, articlePdf);
        fileNameFormatMap.put(articleFileName, DEFAULT_FILE_FORMAT);

        Blob manifestBlob;
        if (Test.isRunningTest()) {
            manifestBlob = Blob.valueOf('Unit.Test');
        } else {
            manifestBlob = getManifest(
                fileNameFormatMap,
                INCOMING_POST,
                getJournalPostName(article.Name),
                article.Skills__c != null ? article.Skills__c.replaceAll(';', ' - ') : '',
                Date.today(),
                caseNumber,
                navIdent,
                navEnhet
            );
        }

        filesToSend.put(manifestName, manifestBlob);
        Boolean isSuccess = sendFiles(filesToSend, manifestName, ftpsCatalouge);

        if (isSuccess) {
            LoggerUtility logger = new LoggerUtility();
            logger.info(manifestName, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
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
        NKS_ArticleXMLGenerator generator = new NKS_ArticleXMLGenerator();
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
        return getAutoNumber() +
            '_' +
            journalPostType.remove(' ') +
            '_' +
            formatDateString(archiveDate) +
            MANIFEST_FORMAT;
    }

    private String getJournalPostName(String caseNumber) {
        return journalPostType + ' - ' + caseNumber.remove('-');
    }

    private String formatFileName(String fileName) {
        return fileName.replaceAll('Å', 'A')
            .replaceAll('å', 'a')
            .replaceAll('Ø', 'O')
            .replaceAll('ø', 'o')
            .replaceAll('Æ', 'Ae')
            .replaceAll('æ', 'ae')
            .replaceAll(' |\\\\|\\/|\\(|\\)', '_')
            .replaceAll('(?!\\.pdf$)\\W', '');
    }

    private String formatDateString(Date input) {
        Datetime dateToFormat = input;
        return dateToFormat.formatGmt('YYYYMMdd');
    }

    @TestVisible
    private String getAutoNumber() {
        List<Application_Log__c> lastTransaction = [
            SELECT Log_Message__c
            FROM Application_Log__c
            WHERE Log_Level__c = 'Info' AND Source_Class__c = 'NKS_ArticleArchiveHandler'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (lastTransaction.isEmpty()) {
            return '000001';
        }

        String lastFileName = lastTransaction[0].Log_Message__c.substring(0, 6);
        Integer lastUsedNumber = Integer.valueOf(lastFileName);
        Integer newAutoNumber = 1000001 + lastUsedNumber;
        return String.valueOf(newAutoNumber).substring(1, 7);
    }

    private String getFtpsCatalouge() {
        return isSandbox ? FTPS_CATALOUGE_TEST : FTPS_CATALOUGE_PROD;
    }
}
