public with sharing class NKS_NewsArchiveHandler {
    private static final String JOURNAL_POST_STATUS = 'J';
    private static final String INCOMING_POST = 'X';
    private static final String BUSINESS_UNIT = 'NAV Styringsenhet Kontaktsenter';
    private static final String BUSINESS_UNIT_ID = '2530003'; //'410000';
    private static final String MANIFEST_FORMAT = '.xml';
    private static final String DEFAULT_FILE_FORMAT = '.pdf';
    private static final String NAV_IDENT = 'A133191'; //'A117995';
    private static final String JOURNAL_POST_TYPE = 'NyheterNKS';
    private static final String FTPS_CATALOUGE_PROD = 'ftpmottak_NKS';
    private static final String FTPS_CATALOUGE_TEST = 'ftpmottakP1SF_NKS';
    private static final String NEWS_CASE_NUMBER = '22/389';

    private string errorMessage='';
    private Boolean isSandbox;

    public void execute(NKS_Announcement__c article) {
        String ftpsCatalouge = getFtpsCatalouge();
        String caseNumber = NEWS_CASE_NUMBER;
        archiveArticle(article,caseNumber,ftpsCatalouge);
    }

    @TestVisible
    private Boolean archiveArticle(NKS_Announcement__c article, String caseNumber, String ftpsCatalouge){
        String articleFileName=formatFileName(article.Name + DEFAULT_FILE_FORMAT);
        Blob articlePdf;
        if(Test.isRunningTest()) { 
            articlePdf = blob.valueOf('Unit.Test');
        } else {
            articlePdf = NKS_NewsArticlePdfGenerator.getPdf(article.Id);
        }
        Map<String, Blob> filesToSend = new Map<String, Blob>();
        Map<String, String> fileNameFormatMap = new Map<String, String>();
        
        String manifestName = getManifestName(article.Name, article.NKS_News_Publish_Date__c.date());
        filesToSend.put(articleFileName, articlePdf);
        fileNameFormatMap.put(articleFileName, DEFAULT_FILE_FORMAT);
        
        Blob manifestBlob;
        if(Test.isRunningTest()) { 
            manifestBlob = blob.valueOf('Unit.Test');
        } else {
            manifestBlob=getManifest(
                fileNameFormatMap,
                article,
                INCOMING_POST,
                getJournalPostName(JOURNAL_POST_TYPE, article.Name),
                article.Skills__c.replaceAll(';', ' '),
                Date.today(),
                caseNumber
              );
          }
    
        filesToSend.put(
            manifestName,
            manifestBlob
          );
       
           Boolean isSuccess=sendFiles(filesToSend, manifestName, ftpsCatalouge); 
           if(isSuccess){
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
          WebSakFileService.WebSakFileResponse response = new WebSakFileService().postFile(file, fileData, ftpsCatalouge);
          
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
        WebSakFileService.WebSakFileResponse xmlResponse = new WebSakFileService().postFile(xmlFileName, xmlFileContent, ftpsCatalouge);
    
        if (!xmlResponse.success) {
          return false;
        }
        return true;
      }
    
      @TestVisible
      private Blob getManifest(
        Map<String, String> fileInfo,
        NKS_Announcement__c article,
        String postType,
        String journalPostName,
        String category,
        Date referenceDate,
        String caseNumber
      ) {
        NKS_NewsXMLGenerator generator = new NKS_NewsXMLGenerator();
          generator.businessUnitId=BUSINESS_UNIT_ID;
          generator.businessUnitName=BUSINESS_UNIT;
          generator.journalPostStatus=JOURNAL_POST_STATUS;
          generator.journalPostType=postType;
          generator.journalPostName=journalPostName;
          generator.journalPostCategory=category;
          generator.journalCaseNumber=caseNumber;
          generator.userNavIdent=NAV_IDENT;
          generator.submissionDate=referenceDate;
          generator.documentNameFormat=fileInfo;
    
        return Blob.valueOf(generator.generateXML());
      }
    
      private String getManifestName(String name, Date archiveDate) {
        return getAutoNumber() + '_NyheterNKS_' + formatDateString(archiveDate) + MANIFEST_FORMAT;
      }
    
      private String getJournalPostName(String type, String caseNumber) {
        return type + ' - ' + caseNumber.replaceAll('-', '');
      }
    
      private String formatFileName(String fileName) {
        return fileName.replaceAll('-', '').replaceAll(' ', '_');
      }
    
      private String formatDateString(Date input) {
        Datetime dateToFormat = input;
        return dateToFormat.formatGmt('YYYYMMdd');
      }
    
      @TestVisible
      private String getAutoNumber(){
          List<Application_Log__c> lastTransaction=[SELECT Log_Message__c FROM Application_Log__c WHERE Log_Level__c='Info' AND Source_Class__c='NKS_NewsArchiveHandler' ORDER BY CreatedDate DESC LIMIT 1];
          if(lastTransaction.size()==0){
              return '000001';
          }
    
          String lastFileName=lastTransaction[0].Log_Message__c.substring(0,6);
          Integer latUsedNumber= Integer.valueOf(lastFileName);
          Integer newAutoNumber=1000001 + latUsedNumber;
          return String.valueOf(newAutoNumber).substring(1,7);
      }

    private String getFtpsCatalouge(){
        isSandbox=[SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if(isSandbox){
            return FTPS_CATALOUGE_TEST;
        }
        return FTPS_CATALOUGE_PROD;
    }
}