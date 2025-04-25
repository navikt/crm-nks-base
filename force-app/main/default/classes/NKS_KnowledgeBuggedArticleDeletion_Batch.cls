// Knowledge Articles do not support DML inserts - so no test class for this batch.
// Run with batch size 1 to avoid issues
global class NKS_KnowledgeBuggedArticleDeletion_Batch implements Database.Batchable<sObject> {
    private static LoggerUtility logger = new LoggerUtility('Knowledge Bugged Article Deletion');
    private List<String> titles;
    private Boolean deleteArticleVersion; // True to delete Article Version - False to delete Article

    global NKS_KnowledgeBuggedArticleDeletion_Batch(List<String> titles, Boolean deleteArticleVersion) {
        this.titles = titles;
        this.deleteArticleVersion = deleteArticleVersion;
    }

    global NKS_KnowledgeBuggedArticleDeletion_Batch(List<String> titles) {
        this.titles = titles;
        this.deleteArticleVersion = true;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query;
        if (deleteArticleVersion) {
            query = 'SELECT Id, KnowledgeArticleId, VersionNumber FROM Knowledge__kav WHERE PublishStatus = \'Archived\' AND Title IN :titles';
        } else {
            query = 'SELECT KnowledgeArticleId FROM Knowledge__kav WHERE PublishStatus = \'Archived\' AND Title IN :titles';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Knowledge__kav> scope) {
        for (Knowledge__kav kav : scope) {
            try {
                if (deleteArticleVersion) {
                    if (kav.KnowledgeArticleId != null && kav.VersionNumber != null) {
                        KbManagement.PublishingService.deleteArchivedArticleVersion(
                            kav.KnowledgeArticleId,
                            kav.VersionNumber
                        );
                        logger.info(
                            'Successfully deleted Article Version. ArticleId: ' +
                                kav.KnowledgeArticleId +
                                ', VersionNumber: ' +
                                kav.VersionNumber,
                            null,
                            CRM_ApplicationDomain.Domain.NKS
                        );
                    } else {
                        logger.error(
                            'Missing KnowledgeArticleId or VersionNumber for KAV Id: ' + kav.Id,
                            null,
                            CRM_ApplicationDomain.Domain.NKS
                        );
                    }
                } else {
                    if (kav.KnowledgeArticleId != null) {
                        KbManagement.PublishingService.deleteArchivedArticle(kav.KnowledgeArticleId);
                        logger.info(
                            'Successfully deleted full Article. ArticleId: ' + kav.KnowledgeArticleId,
                            null,
                            CRM_ApplicationDomain.Domain.NKS
                        );
                    } else {
                        logger.error(
                            'Missing KnowledgeArticleId for KAV Id: ' + kav.Id,
                            null,
                            CRM_ApplicationDomain.Domain.NKS
                        );
                    }
                }
            } catch (Exception e) {
                logger.error(
                    'Failed to delete ' +
                        (deleteArticleVersion ? 'Article Version' : 'Article') +
                        ' for KAV Id: ' +
                        kav.Id +
                        (deleteArticleVersion ? ' and KAV VersionNumber: ' + kav.VersionNumber : '') +
                        '. Error: ' +
                        e.getMessage() +
                        '. ' +
                        e.getStackTraceString(),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
            }
        }
        logger.publish();
    }

    global void finish(Database.BatchableContext bc) {
    }
}
