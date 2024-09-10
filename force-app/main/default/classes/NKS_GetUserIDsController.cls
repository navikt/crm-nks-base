public with sharing class NKS_GetUserIDsController {

    private static Map<Set<Id>, Set<Id>> cachedUserIdsFromGroups = new Map<Set<Id>, Set<Id>>();

    @invocableMethod(label = 'Get User IDs')
    public static List<Result> getUserIdsFromGroups(List<Id> inputGroupIds) {
        Set<Id> groupIds = new Set<Id>(inputGroupIds);

        if (cachedUserIdsFromGroups.containsKey(groupIds)) {
            return getResultList(cachedUserIdsFromGroups.get(groupIds));
        }

        Set<Id> result = new Set<Id>();
        Set<Id> groupIdProxies = new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();

        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId, GroupId
            FROM GroupMember
            WHERE GroupId IN :groupIds
        ];

        Map<Id, User> activeUsersMap = new Map<Id, User>(
            [SELECT Id
             FROM User
             WHERE IsActive = TRUE
               AND ProfileId IN (SELECT Id FROM Profile WHERE Name LIKE 'NAV Kontaktsenter%')]
        );

        for (GroupMember member : groupMembers) {
            if (member.UserOrGroupId.getSObjectType() == Schema.User.SObjectType) {
                if (activeUsersMap.containsKey(member.UserOrGroupId)) {
                    result.add(member.UserOrGroupId);
                }
            } else if (member.UserOrGroupId.getSObjectType() == Schema.Group.SObjectType) {
                groupIdProxies.add(member.UserOrGroupId);
            }
        }

        if (!groupIdProxies.isEmpty()) {
            List<Id> groupIdProxiesList = new List<Id>(groupIdProxies);
            List<Result> groupIdProxiesResult = getUserIdsFromGroups(groupIdProxiesList);

            for (Result res : groupIdProxiesResult) {
                for (String userId : res.userIds) {
                    result.add((Id)userId);
                }
            }
        }

        cachedUserIdsFromGroups.put(groupIds, result);
        return getResultList(result);
    }

    public static List<Result> getResultList(Set<Id> ids) {
        List<Result> results = new List<Result>();
        Result res = new Result();
        res.userIds = new List<String>();

        for (Id id : ids) {
            res.userIds.add((String)id);
        }

        results.add(res);
        return results;
    }

    public class Result {
        @InvocableVariable(label = 'User IDs')
        public List<String> userIds;
    }
}