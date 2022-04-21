public with sharing class NKS_NewsArchiveHandler {
    private static final String JOURNAL_POST_STATUS = 'J';
    private static final String INCOMING_POST = 'X';
    private static final String BUSINESS_UNIT = 'NAV Styringsenhet Kontaktsenter';
    private static final String BUSINESS_UNIT_ID = '2530003';
    private static final String MANIFEST_FORMAT = '.xml';
    private static final String DEFAULT_FILE_FORMAT = '.pdf';
    private static final String NAV_IDENT = 'A117995';
    private static final String JOURNAL_POST_TYPE = 'Rutine for NKS';
    private static final String FTPS_CATALOUGE_PROD = 'ftpmottak_SF_NKS';
    private static final String FTPS_CATALOUGE_TEST = 'ftpmottakP1SF_NKS';

    private string errorMessage = '';
    private Boolean isSandbox;
    private String articleNumber;

    public void execute(NKS_Announcement__c news) {
        String ftpsCatalouge = getFtpsCatalouge();
        String caseNumber = new WebsakCaseNumberMapping().mapByTitle(news.Name, isSandbox, 'NKS News');
        Boolean isSuccess = false;
        if (caseNumber != null) {
            isSuccess = archiveArticle(news, caseNumber, ftpsCatalouge);
        } else {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Fant ikke saksnummer for ' + news.Name, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    @TestVisible
    private Boolean archiveArticle(NKS_Announcement__c news, String caseNumber, String ftpsCatalouge) {
        String articleFileName = formatFileName(news.Name + DEFAULT_FILE_FORMAT);
        Blob articlePdf;
        if (Test.isRunningTest()) {
            articlePdf = blob.valueOf('Unit.Test');
        } else {
            articlePdf = NKS_NewsPDFGenerator.getPdf(news.Id);
        }
        Map<String, Blob> filesToSend = new Map<String, Blob>();
        Map<String, String> fileNameFormatMap = new Map<String, String>();

        String manifestName = getManifestName(news.Name, Date.Today());
        filesToSend.put(articleFileName, articlePdf);
        fileNameFormatMap.put(articleFileName, DEFAULT_FILE_FORMAT);

        Blob manifestBlob;
        if (Test.isRunningTest()) {
            manifestBlob = blob.valueOf('Unit.Test');
        } else {
            manifestBlob = getManifest(
                fileNameFormatMap,
                news,
                INCOMING_POST,
                getJournalPostName(JOURNAL_POST_TYPE, news.Name),
                Date.today(),
                caseNumber
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

        if (success && xmlFileName != null && xmlFileContent != null) {
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
        NKS_Announcement__c news,
        String postType,
        String journalPostName,
        Date referenceDate,
        String caseNumber
    ) {
        NKS_NewsXMLGenerator generator = new NKS_NewsXMLGenerator();
        generator.businessUnitId = BUSINESS_UNIT_ID;
        generator.businessUnitName = BUSINESS_UNIT;
        generator.journalPostStatus = JOURNAL_POST_STATUS;
        generator.journalPostType = postType;
        generator.journalPostName = journalPostName;
        generator.journalCaseNumber = caseNumber;
        generator.userNavIdent = NAV_IDENT;
        generator.submissionDate = referenceDate;
        generator.documentNameFormat = fileInfo;

        return Blob.valueOf(generator.generateXML());
    }

    private Map<String, String> getFileNameFormatMap(List<ContentVersion> contentVersions, String refrenceNumber) {
        Map<String, String> fileNameFormat = new Map<String, String>();

        for (ContentVersion cv : contentVersions) {
            String fileName = formatFileName(refrenceNumber + formatFileName(cv.title));
            fileNameFormat.put(fileName, cv.fileType);
        }
        return fileNameFormat;
    }

    private String getManifestName(String name, Date archiveDate) {
        return articleNumber + '_RutineforNKS_' + formatDateString(archiveDate) + MANIFEST_FORMAT;
    }

    private String getJournalPostName(String type, String caseNumber) {
        return type + ' - ' + caseNumber.replaceAll('-', '');
    }

    @TestVisible
    private String formatFileName(String fileName) {
        return fileName.replaceAll('-', '_')
            .replaceAll(' ', '_')
            .replaceAll('/', '_')
            .replaceAll('\\?', '')
            .replaceAll('–', '_')
            .replaceAll(':', '');
    }

    private String formatDateString(Date input) {
        Datetime dateToFormat = input;
        return dateToFormat.formatGmt('YYYYMMdd');
    }

    private String getFtpsCatalouge() {
        isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (isSandbox) {
            return FTPS_CATALOUGE_TEST;
        }
        return FTPS_CATALOUGE_PROD;
    }
}
