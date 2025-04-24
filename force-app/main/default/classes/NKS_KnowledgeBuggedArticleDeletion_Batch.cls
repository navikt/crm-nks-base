// Knowledge Articles do not support DML inserts - so no test class for this batch.
// Run with batch size 1 to avoid issues
global class NKS_KnowledgeBuggedArticleDeletion_Batch implements Database.Batchable<sObject> {
    private static LoggerUtility logger = new LoggerUtility('Knowledge Bugged Article Deletion');
    private List<String> titles;
    private Boolean deleteArticleVersion = true;

    global NKS_KnowledgeBuggedArticleDeletion_Batch(List<String> titles, Boolean deleteArticleVersion) {
        this.titles = titles;
        this.deleteArticleVersion = deleteArticleVersion;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query;
        if (deleteArticleVersion) {
            query = 'SELECT Id From Knowledge__kav WHERE PublishStatus = \'Archived\' AND Title IN :titles';
        } else {
            query = 'SELECT KnowledgeArticleId From Knowledge__kav WHERE PublishStatus = \'Archived\' AND Title IN :titles';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        List<Id> idsToDelete = new List<Id>();

        if (deleteArticleVersion) {
            for (Knowledge__kav kav : scope) {
                idsToDelete.add(kav.Id);
            }
        } else {
            Set<Id> articleIds = new Set<Id>(); // Set to prevent duplicates
            for (Knowledge__kav kav : scope) {
                if (kav.KnowledgeArticleId != null) {
                    articleIds.add(kav.KnowledgeArticleId);
                }
            }
            idsToDelete.addAll(articleIds);
        }

        if (idsToDelete.isEmpty())
            return;

        try {
            Database.DeleteResult[] results = Database.delete(idsToDelete, false);
            for (Database.DeleteResult result : results) {
                if (!result.isSuccess()) {
                    logger.error(
                        'Article deletion failed for ArticleId: ' +
                            result.getId() +
                            '\n' +
                            'Error: ' +
                            result.getErrors()[0]?.getMessage(),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                } else {
                    logger.info(
                        'Successfully deleted ArticleId: ' + result.getId(),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                }
            }
        } catch (Exception e) {
            logger.error(
                'NKS_KnowledgeBuggedArticleDeletion_Batch failed: ' + e.getMessage() + '. ' + e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        }
        logger.publish();
    }

    global void finish(Database.BatchableContext bc) {
    }
}
