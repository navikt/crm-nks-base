public with sharing class NKS_CustomNotificationController {

    private static Map<Set<Id>, Set<Id>> cachedUserIdsFromGroups = new Map<Set<Id>, Set<Id>>();
    private static Map<Id, Set<String>> cachedUserSkillsMap = new Map<Id, Set<String>>();

    public static Set<Id> getUserIdsFromGroups(Set<Id> groupIds) {
        if (cachedUserIdsFromGroups.containsKey(groupIds)) {
            return cachedUserIdsFromGroups.get(groupIds);
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
            [SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId IN (SELECT Id FROM Profile WHERE Name LIKE 'NAV Kontaktsenter%')]
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
            result.addAll(getUserIdsFromGroups(groupIdProxies));
        }

        cachedUserIdsFromGroups.put(groupIds, result);
        return result;
    }

    @invocableMethod(label='Send Notification')
    public static void sendNotification(List<Request> requests) {
        for (Request request : requests) {
            Group g = [SELECT Id FROM Group WHERE DeveloperName = :request.groupDeveloperName LIMIT 1];
            Set<Id> groupIds = new Set<Id> { g.Id };

            Set<Id> userIds = getUserIdsFromGroups(groupIds);
            Set<Id> usersToNotify = getUsersToNotify(userIds, request.newsSkills);

            if (!usersToNotify.isEmpty()) {
                Database.executeBatch(
                    new NKS_CustomNotificationBatch(
                        usersToNotify, 
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

    private static Set<Id> getUsersToNotify(Set<Id> userIds, String newsSkills) {
        Set<Id> usersToNotify = new Set<Id>();

        if (String.isBlank(newsSkills)) {
            return userIds;
        }

        Map<Id, Set<String>> userSkillsMap = getCachedUserSkills(userIds);
        Set<String> newsSkillsSet = new Set<String>(newsSkills.split(';'));

        for (Id userId : userIds) {
            Set<String> userSkills = userSkillsMap.get(userId);

            if (userSkills != null && !userSkills.isEmpty()) {
                for (String userSkill : userSkills) {
                    if (newsSkillsSet.contains(userSkill)) {
                        usersToNotify.add(userId);
                        break; 
                    }
                }
            } else {
                usersToNotify.add(userId); // Add if no skills or null
            }
        }

        return usersToNotify;
    }

    private static Map<Id, Set<String>> getCachedUserSkills(Set<Id> userIds) {
        Set<Id> missingUserIds = new Set<Id>();
        for (Id userId : userIds) {
            if (!cachedUserSkillsMap.containsKey(userId)) {
                missingUserIds.add(userId);
            }
        }

        if (!missingUserIds.isEmpty()) {
            cachedUserSkillsMap.putAll(fetchUserSkills(missingUserIds));
        }

        return cachedUserSkillsMap;
    }

    private static Map<Id, Set<String>> fetchUserSkills(Set<Id> userIds) {
        Map<Id, Set<String>> userSkillsMap = new Map<Id, Set<String>>();

        try {
            for (Id userId : userIds) {
                Set<String> skills = NKS_HomePageController.getUserSkills(userId);
                Set<String> cleanedSkills = new Set<String>();
                for (String skill : skills) {
                    cleanedSkills.add(skill.replaceAll('NKS_Skill_', ''));
                }
                userSkillsMap.put(userId, cleanedSkills);
            }
        } catch (Exception e) {
            System.debug('Error fetching user skills: ' + e.getMessage());
        }

        return userSkillsMap;
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
        public String newsSkills;
    }
}
