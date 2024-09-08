public with sharing class NKS_GetUserSkillsBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Map<Id, Set<String>> userSkillsMap = new Map<Id, Set<String>>();

    private Set<Id> userIds;

    public NKS_GetUserSkillsBatch(Set<Id> userIds) {
        this.userIds = userIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id FROM User WHERE Id IN :userIds
        ]); 
    }

    public void execute(Database.BatchableContext BC, List<User> scope) {
        if (scope.isEmpty()) return;

        Set<Id> userIds = new Set<Id>();
        for (User user : scope) {
            userIds.add(user.Id);
        }

        for (Id userId : userIds) {
            try {
                Set<String> skills = NKS_HomePageController.getUserSkills(userId);
                Set<String> cleanedSkills = new Set<String>();

                for (String skill : skills) {
                    cleanedSkills.add(skill.replaceAll('NKS_Skill_', ''));
                }
                userSkillsMap.put(userId, cleanedSkills);

            } catch (Exception e) {
                System.debug('Error fetching user skills for user ' + userId + ': ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch completed. Processed user skills: ' + userSkillsMap);
    }
}