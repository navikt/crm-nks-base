public with sharing class NKS_GetUserSkillsController {
    public static Map<Id, Set<String>> cachedUserSkillsMap = new Map<Id, Set<String>>();

    @invocableMethod(label='Get User IDs Based on Skill')
    public static List<Result> getUsersToNotify(List<Request> requests) {
        List<Id> usersToNotify = new List<Id>();

        for (Request request : requests) {

            if (String.isBlank(request.newsSkills)) {
                return getResultList(request.userIds);
            }

            Set<Id> userIdsSet = new Set<Id>(request.userIds);
            Map<Id, Set<String>> userSkillsMap = getCachedUserSkills(userIdsSet);
            Set<String> newsSkillsSet = new Set<String>(request.newsSkills.split(';'));
           
            for (Id userId : userIdsSet) {
                Set<String> userSkills = userSkillsMap.get(userId);
    
                if (userSkills != null && !userSkills.isEmpty()) {
                    for (String userSkill : userSkills) {
                        if (newsSkillsSet.contains(userSkill)) {
                            usersToNotify.add(userId);
                            break; 
                        }
                    }
                } else {
                    usersToNotify.add(userId); 
                }
            }          
        }
        return getResultList(usersToNotify);
    }

    private static Map<Id, Set<String>> getCachedUserSkills(Set<Id> userIds) {
        Set<Id> missingUserIds = new Set<Id>();
        
        for (Id userId : userIds) {
            if (!cachedUserSkillsMap.containsKey(userId)) {
                missingUserIds.add(userId);
            }
        }

        if (!missingUserIds.isEmpty()) {
            Database.executeBatch(new NKS_GetUserSkillsBatch(missingUserIds), 10);
        }

        return cachedUserSkillsMap;
    }

    public static List<Result> getResultList(List<Id> ids) {
        List<Result> results = new List<Result>();
        Result res = new Result();
        res.userIds = new List<String>(); 
        
        for (Id id : ids) {
            res.userIds.add((String)id);  
        }
        
        results.add(res);  
        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public List<Id> userIds;

        @InvocableVariable(required=true)
        public String newsSkills;
    }

    public class Result {
        @InvocableVariable(label='User IDs')
        public List<String> userIds;
    }
}
