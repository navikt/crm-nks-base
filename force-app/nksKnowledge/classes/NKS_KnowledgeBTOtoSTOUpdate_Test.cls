@isTest
private class NKS_KnowledgeBTOtoSTOUpdate_Test {
    @testSetup
    static void setupTestData() {
        Knowledge__kav knowledgeArticle = new Knowledge__kav(
            Title = 'BTO article with Beskjed til Oss testesen',
            Article__c = 'Beskjed til oss test BTO test bto beskjed til oss test',
            NKS_English__c = 'Beskjed til oss test BTO test',
            NKS_Nynorsk__c = 'Beskjed til oss test BTO test',
            NKS_Resources__c = 'Beskjed til oss test BTO test',
            NKS_Legislation__c = 'NKS legislation text',
            NKS_Summary__c = 'Beskjed til oss test BTO test',
            NKS_UserInformation__c = 'Beskjed til oss test BTO test',
            WhoDoesWhat__c = 'Beskjed til oss test BTO test',
            UrlName = 'Beskjed-til-oss'
        );
        insert knowledgeArticle;

        knowledge__kav article = [SELECT KnowledgeArticleId FROM knowledge__kav WHERE Id = :knowledgeArticle.Id];
        KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
    }

    @isTest
    static void testBatch() {
        Test.startTest();
        NKS_KnowledgeBTOtoSTOUpdate batch = new NKS_KnowledgeBTOtoSTOUpdate();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Knowledge__kav knowledgeArticle = [
            SELECT Id, Title, Article__c, NKS_Legislation__c, NKS_Summary__c
            FROM Knowledge__kav
            WHERE PublishStatus = 'Online'
            LIMIT 1
        ];

        Assert.areEqual('STO article with Skriv til oss testesen', knowledgeArticle.Title);
        Assert.areEqual('Skriv til oss test STO test STO Skriv til oss test', knowledgeArticle.Article__c);
        Assert.areEqual('NKS legislation text', knowledgeArticle.NKS_Legislation__c);
        Assert.areEqual('Skriv til oss test STO test', knowledgeArticle.NKS_Summary__c);
    }
}
