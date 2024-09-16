public with sharing class NKS_GetUserSkillsController {

    @TestVisible
    private static Map<Id, Set<String>> cachedUserSkillsMap = new Map<Id, Set<String>>();

    @InvocableMethod(label = 'Get User IDs Filtered By Skill')
    public static List<Result> getUsersToNotify(List<Request> requests) {
        Set<Id> usersToNotify = new Set<Id>();

        for (Request request : requests) {
            Set<Id> userIds = new Set<Id>(request.userIds);

            if (String.isBlank(request.newsSkills)) {
                return getResultList(userIds);
            }

            Set<String> newsSkillsSet = new Set<String>(request.newsSkills.split(';'));
            usersToNotify.addAll(extractUserIds(userIds, newsSkillsSet));
        }

        return getResultList(usersToNotify);
    }

    public static Set<Id> extractUserIds(Set<Id> userIds, Set<String> newsSkills) {
        // Check if cached data is available 
        if (cachedUserSkillsMap.isEmpty()) {
            initializeUserSkillsMap(userIds);
        }

        // Filter the cached map to get the relevant user IDs
        Set<Id> exactOrNoSkillUserIds = new Set<Id>();
        for (Id userId : userIds) {
            Set<String> skills = cachedUserSkillsMap.get(userId);
            if (skills == null) {
                skills = new Set<String>();
            }
            if (skills.isEmpty() || skillIncluded(newsSkills, skills)) {
                exactOrNoSkillUserIds.add(userId);
            }
        }

        return exactOrNoSkillUserIds;
    }

    @TestVisible
    private static void initializeUserSkillsMap(Set<Id> userIds) {
        Map<Id, Set<String>> userSkillsMap = new Map<Id, Set<String>>();

        for (Id userId : userIds) {
            userSkillsMap.put(userId, new Set<String>());
        }

        // Fetch users and their skills from ServiceResourceSkill
        for (ServiceResourceSkill srSkill : [
            SELECT ServiceResource.RelatedRecordId, Skill.DeveloperName
            FROM ServiceResourceSkill
            WHERE ServiceResource.RelatedRecordId IN :userIds
        ]) {
            Set<String> userSkills = userSkillsMap.get(srSkill.ServiceResource.RelatedRecordId);
            userSkills.add(srSkill.Skill.DeveloperName);
            userSkillsMap.put(srSkill.ServiceResource.RelatedRecordId, userSkills);
        }

        // Transform newsSkills to match the Group naming convention: 'NKS_Skill_<SkillName>'
        Set<String> groupSkillNames = new Set<String>();
        for (String skill : userSkillsMap.keySet()) {
            groupSkillNames.add('NKS_Skill_' + skill);
        }

        // Fetch users and their skills from GroupMember and Group
        for (Group g : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE DeveloperName IN :groupSkillNames
            AND Type = 'Regular'
        ]) {
            for (GroupMember gm : [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE UserOrGroupId IN :userIds
                AND GroupId = :g.Id
            ]) {
                String skillName = g.DeveloperName.replace('NKS_Skill_', '');
                Set<String> userSkills = userSkillsMap.get(gm.UserOrGroupId);
                if (userSkills == null) {
                    userSkills = new Set<String>();
                }
                userSkills.add(skillName);
                userSkillsMap.put(gm.UserOrGroupId, userSkills);
            }
        }
        cachedUserSkillsMap = userSkillsMap;
    }

    public static Boolean skillIncluded(Set<String> newsSkills, Set<String> userSkills) {
        for (String skill : newsSkills) {
            if (userSkills.contains(skill)) {
                return true;
            }
        }
        return false;
    }

    public static List<Result> getResultList(Set<Id> ids) {
        List<Result> results = new List<Result>();
        Result res = new Result();
        res.userIds = new List<String>();

        for (Id id : ids) {
            res.userIds.add((String) id);
        }

        results.add(res);
        return results;
    }

    public class Request {
        @InvocableVariable(required = true)
        public List<Id> userIds;

        @InvocableVariable
        public String newsSkills;
    }

    public class Result {
        @InvocableVariable(label = 'User IDs')
        public List<String> userIds;
    }
}