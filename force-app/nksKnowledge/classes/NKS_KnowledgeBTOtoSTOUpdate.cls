global class NKS_KnowledgeBTOtoSTOUpdate implements Database.Batchable<SObject>, Database.Stateful {
    private static LoggerUtility logger = new LoggerUtility('NKS_KnowledgeBTOtoSTOUpdate');

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query =
            'SELECT Id, KnowledgeArticleId, Title, Article__c, NKS_English__c, ' +
            'NKS_Nynorsk__c, NKS_Resources__c, NKS_Legislation__c, NKS_Summary__c, ' +
            'NKS_UserInformation__c, WhoDoesWhat__c ' +
            'FROM Knowledge__kav ' +
            'WHERE IsLatestVersion = TRUE AND PublishStatus = \'Online\' ' +
            'AND RecordType.DeveloperName != \'HOT_Kunnskapsartikkel\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Knowledge__kav> latestVersions) {
        List<Knowledge__kav> modifiedDrafts = new List<Knowledge__kav>();

        for (Knowledge__kav article : latestVersions) {
            if (!hasTextToReplace(article)) {
                // Skip unpublishing and creating new draft if no replacement needed
                continue;
            }

            String newDraftArticleId = '';
            try {
                newDraftArticleId = KbManagement.PublishingService.editOnlineArticle(article.KnowledgeArticleId, true);
            } catch (Exception e) {
                logger.error(
                    'KbManagement.PublishingService.editOnlineArticle failed on Article Id: ' +
                        article.Id +
                        '\n' +
                        e.getMessage(),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
            }

            Knowledge__kav draft = getDraftArticle(newDraftArticleId);
            if (draft == null) {
                logger.error('Draft from getDraftArticle was null.', null, CRM_ApplicationDomain.Domain.NKS);
                continue;
            }

            Boolean changed = false;

            String newTitle = replaceIfChanged(draft.Title);
            if (newTitle != draft.Title) {
                draft.Title = newTitle;
                changed = true;
            }

            String newSummary = replaceIfChanged(draft.NKS_Summary__c);
            if (newSummary != draft.NKS_Summary__c) {
                draft.NKS_Summary__c = newSummary;
                changed = true;
            }

            String newArticle = replaceIfChanged(draft.Article__c);
            if (newArticle != draft.Article__c) {
                draft.Article__c = newArticle;
                changed = true;
            }

            String newEng = replaceIfChanged(draft.NKS_English__c);
            if (newEng != draft.NKS_English__c) {
                draft.NKS_English__c = newEng;
                changed = true;
            }

            String newNyn = replaceIfChanged(draft.NKS_Nynorsk__c);
            if (newNyn != draft.NKS_Nynorsk__c) {
                draft.NKS_Nynorsk__c = newNyn;
                changed = true;
            }

            String newRes = replaceIfChanged(draft.NKS_Resources__c);
            if (newRes != draft.NKS_Resources__c) {
                draft.NKS_Resources__c = newRes;
                changed = true;
            }

            String newLegal = replaceIfChanged(draft.NKS_Legislation__c);
            if (newLegal != draft.NKS_Legislation__c) {
                draft.NKS_Legislation__c = newLegal;
                changed = true;
            }

            String newInfo = replaceIfChanged(draft.NKS_UserInformation__c);
            if (newInfo != draft.NKS_UserInformation__c) {
                draft.NKS_UserInformation__c = newInfo;
                changed = true;
            }

            String newWho = replaceIfChanged(draft.WhoDoesWhat__c);
            if (newWho != draft.WhoDoesWhat__c) {
                draft.WhoDoesWhat__c = newWho;
                changed = true;
            }

            if (changed) {
                modifiedDrafts.add(draft);
            }
        }

        if (!modifiedDrafts.isEmpty()) {
            try {
                update modifiedDrafts;
            } catch (Exception e) {
                logger.error(
                    'Updating modified draft articles failed: ' + e.getMessage(),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
            }

            for (Knowledge__kav draft : modifiedDrafts) {
                try {
                    KbManagement.PublishingService.publishArticle(draft.KnowledgeArticleId, true);
                } catch (Exception e) {
                    logger.error(
                        'KbManagement.PublishingService.publishArticle failed on Article Id: ' +
                            draft.Id +
                            '\n' +
                            e.getMessage(),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                }
            }
        }
        logger.publish();
    }

    global void finish(Database.BatchableContext BC) {
    }

    private Knowledge__kav getDraftArticle(String articleId) {
        List<Knowledge__kav> draft = [
            SELECT
                Id,
                KnowledgeArticleId,
                Title,
                NKS_Summary__c,
                Article__c,
                NKS_English__c,
                NKS_Nynorsk__c,
                NKS_Resources__c,
                NKS_Legislation__c,
                NKS_UserInformation__c,
                WhoDoesWhat__c
            FROM Knowledge__kav
            WHERE Id = :articleId
        ];

        if (draft.isEmpty()) {
            return null;
        }
        return draft[0];
    }

    private String replaceIfChanged(String original) {
        if (String.isBlank(original))
            return original;
        return original.replaceAll('(?i)\\bBTO\\b', 'STO').replaceAll('(?i)Beskjed til oss', 'Skriv til oss');
    }

    private Boolean hasTextToReplace(Knowledge__kav article) {
        return containsTarget(article.Title) ||
            containsTarget(article.NKS_Summary__c) ||
            containsTarget(article.Article__c) ||
            containsTarget(article.NKS_English__c) ||
            containsTarget(article.NKS_Nynorsk__c) ||
            containsTarget(article.NKS_Resources__c) ||
            containsTarget(article.NKS_Legislation__c) ||
            containsTarget(article.NKS_UserInformation__c) ||
            containsTarget(article.WhoDoesWhat__c);
    }

    private Boolean containsTarget(String input) {
        if (String.isBlank(input))
            return false;
        return Pattern.compile('(?i)\\bBTO\\b|Beskjed til oss').matcher(input).find();
    }
}
