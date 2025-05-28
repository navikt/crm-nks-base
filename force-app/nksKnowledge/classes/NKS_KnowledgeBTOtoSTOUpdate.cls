global class NKS_KnowledgeBTOtoSTOUpdate implements Database.Batchable<SObject>, Database.Stateful {
    private static LoggerUtility logger = new LoggerUtility('NKS_KnowledgeBTOtoSTOUpdate');

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query =
            'SELECT Id, KnowledgeArticleId, Title, Article__c, NKS_English__c, ' +
            'NKS_Nynorsk__c, NKS_Resources__c, NKS_Legislation__c, NKS_Summary__c, ' +
            'NKS_UserInformation__c, WhoDoesWhat__c, EmployerInformation__c, EmployerInformationInternal__c, ' +
            'NKS_English_Employer__c, NKS_Nynorsk_Employer__c ' +
            'FROM Knowledge__kav ' +
            'WHERE IsLatestVersion = TRUE AND PublishStatus = \'Online\' ' +
            'AND RecordType.DeveloperName != \'HOT_Kunnskapsartikkel\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Knowledge__kav> latestVersions) {
        List<String> articleIdsFromPublishingService = new List<String>();

        for (Knowledge__kav article : latestVersions) {
            if (!hasTextToReplace(article)) {
                // Skip unpublishing and creating new draft if no replacement needed
                continue;
            }

            try {
                String newDraftArticleId = KbManagement.PublishingService.editOnlineArticle(
                    article.KnowledgeArticleId,
                    true
                );
                if (!String.isBlank(newDraftArticleId)) {
                    articleIdsFromPublishingService.add(newDraftArticleId);
                }
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
        }

        Map<String, Knowledge__kav> draftsByDraftId = populateDraftsMap(articleIdsFromPublishingService);
        System.debug('draftsByDraftId: ' + draftsByDraftId);
        List<Knowledge__kav> modifiedDrafts = new List<Knowledge__kav>();

        for (String draftId : articleIdsFromPublishingService) {
            System.debug('draftId: ' + draftId);
            Knowledge__kav draft = draftsByDraftId.get(draftId);
            System.debug('draft from get: ' + draft);

            if (draft == null) {
                logger.error('Draft not found for id: ' + draftId, null, CRM_ApplicationDomain.Domain.NKS);
                continue;
            }

            Boolean changed = false;

            if (replaceValuesInField(draft, 'Title'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_Summary__c'))
                changed = true;
            if (replaceValuesInField(draft, 'Article__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_English__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_Nynorsk__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_Resources__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_Legislation__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_UserInformation__c'))
                changed = true;
            if (replaceValuesInField(draft, 'WhoDoesWhat__c'))
                changed = true;
            if (replaceValuesInField(draft, 'EmployerInformation__c'))
                changed = true;
            if (replaceValuesInField(draft, 'EmployerInformationInternal__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_English_Employer__c'))
                changed = true;
            if (replaceValuesInField(draft, 'NKS_Nynorsk_Employer__c'))
                changed = true;

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

    private Map<String, Knowledge__kav> populateDraftsMap(List<String> articleIdsFromPublishingService) {
        Map<String, Knowledge__kav> draftsMap = new Map<String, Knowledge__kav>();
        for (Knowledge__kav draft : [
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
                WhoDoesWhat__c,
                EmployerInformation__c,
                EmployerInformationInternal__c,
                NKS_English_Employer__c,
                NKS_Nynorsk_Employer__c
            FROM Knowledge__kav
            WHERE Id IN :articleIdsFromPublishingService
        ]) {
            draftsMap.put(Id.valueOf(draft.Id).to15(), draft); // editOnlineArticle returns 15 digit Id, so we have to convert
        }
        return draftsMap;
    }

    private Boolean replaceValuesInField(Knowledge__kav article, String fieldName) {
        String oldValue = (String) article.get(fieldName);
        String newValue = replaceBtoWithSto(oldValue);
        if (newValue != oldValue) {
            article.put(fieldName, newValue);
            return true;
        }
        return false;
    }

    private String replaceBtoWithSto(String original) {
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
            containsTarget(article.WhoDoesWhat__c) ||
            containsTarget(article.EmployerInformation__c) ||
            containsTarget(article.EmployerInformationInternal__c) ||
            containsTarget(article.NKS_English_Employer__c) ||
            containsTarget(article.NKS_Nynorsk_Employer__c);
    }

    private Boolean containsTarget(String input) {
        if (String.isBlank(input))
            return false;
        return Pattern.compile('(?i)\\bBTO\\b|Beskjed til oss').matcher(input).find();
    }
}
