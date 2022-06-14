public with sharing class NKS_TaskOwnerHandler extends MyTriggers {
    public override void onBeforeInsert() {
        Id newOwnerId = RecordOwnerService.getDefaultOwner();

        if (newOwnerId != null) {
            List<NavTask__c> triggerTasks = (List<NavTask__c>) records;
            Set<String> assigneeIdents = getAssigneeIdents(triggerTasks);

            Map<String, Id> navIdentIdMap = getSfUserMapByNavIdents(assigneeIdents);

            for (NavTask__c task : triggerTasks) {
                //Do not change owner for AG task
                //Do not change owner for tasks assigned to Salesforce users
                if (task.CRM_Theme__c == null)
                    task.OwnerId = !navIdentIdMap.containsKey(task.NKS_Assignee__c)
                        ? newOwnerId
                        : navIdentIdMap.get(task.NKS_Assignee__c);
            }
        }
    }

    public override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        Id defaultOwnerId = getOrgDefaultOwner();
        List<String> fieldNamesToCheck = new List<String>{ 'NKS_Assignee__c' };

        List<NavTask__c> triggerTasks = (List<NavTask__c>) records;
        Set<String> assigneeIdents = getAssigneeIdents(triggerTasks);
        Map<String, Id> navIdentIdMap = getSfUserMapByNavIdents(assigneeIdents);

        for (NavTask__c navTask : triggerTasks) {
            NavTask__c oldRecord = (NavTask__c) triggerOldMap.get(navTask.Id);
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, navTask, oldRecord)) {
                if (String.isBlank(navTask.NKS_Assignee__c)) {
                    navTask.OwnerId = defaultOwnerId;
                } else {
                    navTask.OwnerId = !navIdentIdMap.containsKey(navTask.NKS_Assignee__c)
                        ? defaultOwnerId
                        : navIdentIdMap.get(navTask.NKS_Assignee__c);
                }
            }
        }
    }

    /**
     * Get the org default for the Default record owner custom setting
     * @author Stian Ruud Schikora | 06-14-2022
     * @return Id
     **/
    private Id getOrgDefaultOwner() {
        DefaultRecordOwner__c orgDefault = DefaultRecordOwner__c.getOrgDefaults();
        return orgDefault.UserOrQueueId__c;
    }

    /**
     * Returns a map of NAV_IDENT --> SF_USER_ID for all assignees who has a Salesforce user
     * @author Stian Ruud Schikora | 06-14-2022
     * @param navIdents
     * @return Map<String, Id>
     **/
    private Map<String, Id> getSfUserMapByNavIdents(Set<String> navIdents) {
        Map<String, Id> navIdentUserIdMap = new Map<String, Id>();

        if (!navIdents.isEmpty()) {
            for (User usr : [SELECT Id, CRM_NAV_Ident__c FROM User WHERE CRM_NAV_Ident__c IN :navIdents]) {
                navIdentUserIdMap.put(usr.CRM_NAV_Ident__c, usr.Id);
            }
        }

        return navIdentUserIdMap;
    }

    /**
     * Returns a list of assigned NAV idents from all NavTask__c that has NKS_Assignee__c set
     * @author Stian Ruud Schikora | 06-14-2022
     * @param navTasks
     * @return Set<String>
     **/
    private Set<String> getAssigneeIdents(List<NavTask__c> navTasks) {
        Set<String> assigneeIdents = new Set<String>();
        for (NavTask__c navTask : navTasks) {
            if (String.isNotBlank(navTask.NKS_Assignee__c)) {
                assigneeIdents.add(navTask.NKS_Assignee__c);
            }
        }

        return assigneeIdents;
    }
}
