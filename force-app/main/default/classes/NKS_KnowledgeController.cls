public with sharing class NKS_KnowledgeController {
    @invocableMethod(label='Get Topic Assignments')
    public static List<List<TopicAssignment>> getTopicAssignments(List<String> articleIds) {
        List<List<TopicAssignment>> resultList = new List<List<TopicAssignment>>();
        List<TopicAssignment> taList = new List<TopicAssignment>();

        try {
            taList = [
                SELECT Id, EntityId, EntityKeyPrefix, EntityType, TopicId, CreatedDate
                FROM TopicAssignment
                WHERE
                    EntityId IN (
                        SELECT Id
                        FROM Knowledge__kav
                        WHERE
                            KnowledgeArticleId = :articleIds[0]
                            AND IsLatestVersion = FALSE
                            AND PublishStatus = 'archived'
                    )
                    AND EntityType = 'Knowledge'
                    AND isDeleted = FALSE
            ];
        } catch (Exception ex) {
            System.debug('Problem getting TopicAssignment List ' + ex.getMessage());
        }
        resultList.add(taList);

        return resultList;
    }
}
