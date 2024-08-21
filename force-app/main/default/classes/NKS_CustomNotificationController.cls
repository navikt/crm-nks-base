public with sharing class NKS_CustomNotificationController {

    public static Set<Id> getUserIdsFromGroups(Set<Id> groupIds) {
        Set<Id> result = new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxies = new Set<Id>();

        Map<Id, User> activeUsersMap = new Map<Id, User>(
            [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE /* AND ProfileId IN (SELECT Id FROM Profile WHERE Name LIKE 'NAV Kontaktsenter%') */
            ]
        );

        for (Id groupElementId : groupIds) {
            if (String.valueOf(groupElementId.getSobjectType()) == 'Group') {
                try {
                    for (GroupMember groupMember : [
                        SELECT UserOrGroupId
                        FROM GroupMember
                        WHERE GroupId IN :groupIds
                    ]) {
                        if (
                            ((String) groupMember.UserOrGroupId).startsWith(userType) &&
                            activeUsersMap.get(groupMember.UserOrGroupId) != null
                        ) {
                            result.add(groupMember.UserOrGroupId);
                        } else if (((String) groupMember.UserOrGroupId).startsWith(groupType)) {
                            groupIdProxies.add(groupMember.UserOrGroupId);
                        }
                    }
                } catch (Exception ex) {
                    System.debug('Problem getting group members: ' + ex.getMessage());
                }

                if (groupIdProxies.size() > 0) {
                    result.addAll(getUserIdsFromGroups(groupIdProxies));
                }
            }
        }
        return result;
    }

    @invocableMethod(label='Send Notification')
    public static void sendNotification(List<Request> requests) {
        for (Request request : requests) {
            Set<Id> groupIds = new Set<Id>();
            Group g = [SELECT Id FROM Group WHERE DeveloperName = :request.groupDeveloperName];
            groupIds.add(g.Id);

            Set<Id> userIds = getUserIdsFromGroups(groupIds);

            if (!containsAnySkill(request.newsSkills)) {
                userIds.remove(UserInfo.getUserId());
            }

            if (!userIds.isEmpty()) {
                Database.executeBatch(
                    new NKS_CustomNotificationBatch(
                        userIds, 
                        request.notificationTypeId, 
                        request.notificationTitle, 
                        request.notificationBody, 
                        request.targetId,
                        request.pageRef
                    ), 
                    200 
                );
            }
        }
    }

    public static Boolean containsAnySkill(List<String> newsSkills) {
        List<String> userSkills = NKS_HomePageController.getUserSkills();
    
        if (newsSkills == null || userSkills == null || newsSkills.isEmpty() || userSkills.isEmpty()) {
            return true;
        }
    
        Set<String> newsSkillsSet = new Set<String>(newsSkills);
    
        for (String skill : userSkills) {
            if (newsSkillsSet.contains(skill)) {
                return true; 
            }
        }
        return false;
    }
    

    public class Request {
        @InvocableVariable(required=true)
        public String groupDeveloperName;

        @InvocableVariable(required=true)
        public String notificationTypeId;

        @InvocableVariable(required=true)
        public String notificationTitle;

        @InvocableVariable(required=true)
        public String notificationBody;

        @InvocableVariable
        public Id targetId;

        @InvocableVariable
        public String pageRef;

        @InvocableVariable
        public List<String> newsSkills;
    }
}