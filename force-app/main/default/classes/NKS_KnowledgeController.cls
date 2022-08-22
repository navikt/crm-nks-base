public with sharing class NKS_KnowledgeController {
    @invocableMethod(label='Get Topic Assignments')
    public static List<List<TopicAssignment>> getTopicAssignments(List<String> articleNums) {
        List<List<TopicAssignment>> resultList = new List<List<TopicAssignment>>();
        List<TopicAssignment> taList = new List<TopicAssignment>();

        try {
            taList = [
                SELECT Id, EntityId, EntityKeyPrefix, EntityType, TopicId, CreatedDate
                FROM TopicAssignment
                WHERE
                    EntityId NOT IN (
                        SELECT Id
                        FROM Knowledge__kav
                        WHERE (IsLatestVersion = TRUE OR PublishStatus = 'Online') AND ArticleNumber = :articleNums[0]
                    )
                    AND EntityType = 'Knowledge'
            ];
        } catch (Exception ex) {
            System.debug('Problem getting TopicAssignment List ' + ex.getMessage());
        }
        resultList.add(taList);

        return resultList;
    }
}
