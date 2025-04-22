// Knowledge Articles do not support DML inserts - so no test class for this batch.
global class NKS_KnowledgeBuggedArticleDeletion_Batch implements Database.Batchable<sObject> {
    private static LoggerUtility logger = new LoggerUtility('Knowledge Bugged Article Deletion');
    private List<String> titles;

    global NKS_KnowledgeBuggedArticleDeletion_Batch(List<String> titles) {
        this.titles = titles;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String titleQuery = escapeTitles(titles);
        String query =
            'SELECT KnowledgeArticleId From Knowledge__kav WHERE PublishStatus = \'Archived\' AND Title IN (:titleQuery)';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        Set<Id> articleIds = new Set<Id>();
        for (Knowledge__kav kav : scope) {
            articleIds.add(kav.KnowledgeArticleId);
        }

        if (!articleIds.isEmpty()) {
            List<Id> idsToDelete = new List<Id>(articleIds); // Convert to list from Set

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
                    'NKS_KnowledgeBuggedArticleDeletion_Batch failed: ' +
                        e.getMessage() +
                        '. ' +
                        e.getStackTraceString(),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
            }
            logger.publish();
        }
    }

    global void finish(Database.BatchableContext bc) {
    }

    public static String escapeTitles(List<String> titles) {
        List<String> escapedTitles = new List<String>();
        for (String title : titles) {
            escapedTitles.add('\'' + String.escapeSingleQuotes(title) + '\'');
        }
        return String.join(escapedTitles, ', ');
    }
}
