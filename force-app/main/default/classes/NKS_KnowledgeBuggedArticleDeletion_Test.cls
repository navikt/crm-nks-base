@isTest
private class NKS_KnowledgeBuggedArticleDeletion_Test {
    @testSetup
    static void setupData() {
        Knowledge__kav knowledgeArticle = new Knowledge__kav(
            Title = 'Bugged Article for deletion test',
            Article__c = 'Some content',
            UrlName = 'bugged-article-test'
        );
        insert knowledgeArticle;

        Knowledge__kav article = [
            SELECT KnowledgeArticleId, VersionNumber
            FROM Knowledge__kav
            WHERE Id = :knowledgeArticle.Id
        ];
        KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
        KbManagement.PublishingService.archiveOnlineArticle(article.KnowledgeArticleId, null);
    }

    @isTest
    static void testDeleteArticleVersionExeption() {
        Test.startTest();
        NKS_KnowledgeBuggedArticleDeletion_Batch batch = new NKS_KnowledgeBuggedArticleDeletion_Batch(
            new List<String>{ 'Bugged Article for deletion test' }
        );
        Database.executeBatch(batch, 1);
        Test.stopTest();

        List<Application_Log__c> logs = [
            SELECT Id
            FROM Application_Log__c
            LIMIT 1
        ];

        Assert.areEqual(1, logs.size());
    }

    @isTest
    static void testDeleteFullArticle() {
        Test.startTest();
        NKS_KnowledgeBuggedArticleDeletion_Batch batch = new NKS_KnowledgeBuggedArticleDeletion_Batch(
            new List<String>{ 'Bugged Article for deletion test' },
            false
        );
        Database.executeBatch(batch, 1);
        Test.stopTest();

        List<Knowledge__kav> remainingArticles = [
            SELECT Id
            FROM Knowledge__kav
            LIMIT 1
        ];

        Assert.areEqual(0, remainingArticles.size());
    }
}
