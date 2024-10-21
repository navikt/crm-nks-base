@isTest
public with sharing class NKS_AuditLogControllerTest {
    @TestSetup
    static void makeData() {
        NKS_Announcement__c news = new NKS_Announcement__c();
        news.NKS_News_Status__c = 'Published';
        insert news;

        Knowledge__kav article = new Knowledge__kav();
        article.Title = 'Test Article';
        article.UrlName = 'Test-Article';
        insert article;

        Knowledge__kav kav = [SELECT id, KnowledgeArticleId FROM Knowledge__kav WHERE id = :article.Id LIMIT 1];
        KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);

        Id rtId = NKS_AuditLogController.getRecordTypeId('Knowledge Audit Log');
        NKS_Audit_Log__c al = new NKS_Audit_Log__c();
        al.User__c = UserInfo.getUserId();
        al.RecordTypeId = rtId;
        al.Knowledge__c = article.Id;
        al.Knowledge_Article_Id__c = article.KnowledgeArticleId;
        al.Operation__c = 'View';
        insert al;
    }

    @isTest
    static void testCreateAuditLog() {
        Id articleId = [SELECT Id FROM Knowledge__kav LIMIT 1]?.Id;
        Id newsId = [SELECT Id FROM NKS_Announcement__c LIMIT 1]?.Id;

        Test.startTest();
        NKS_AuditLogController.createAuditLog(articleId, 'Knowledge__c');
        NKS_AuditLogController.createAuditLog(newsId, 'Announcement__c');
        Test.stopTest();
    }

    @isTest
    static void testCountViews() {
        Id articleId = [SELECT Id FROM Knowledge__kav LIMIT 1]?.Id;
        Id newsId = [SELECT Id FROM NKS_Announcement__c LIMIT 1]?.Id;

        Test.startTest();
        Integer articleViews = NKS_AuditLogController.countViews(articleId, 'Knowledge__c');
        Integer newsViews = NKS_AuditLogController.countViews(newsId, 'Announcement__c');
        Test.stopTest();
        System.assertEquals(1, articleViews);
        System.assertEquals(0, newsViews);
    }

    @isTest
    static void testIsKnowledgeUser() {
        Test.startTest();
        Boolean result = NKS_AuditLogController.isKnowledgeUser();
        Test.stopTest();
    }

    @IsTest
    static void testLogErrorMessage() {
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(
            '{"success":false,"errors":[{"message":"Required fields are missing: [Name]","statusCode":"REQUIRED_FIELD_MISSING"}]}',
            Database.SaveResult.class
        );

        Test.startTest();
        NKS_AuditLogController.logErrorMessage(sr);
        Test.stopTest();
    }
}
