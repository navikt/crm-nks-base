global with sharing class NavTaskAccessHandler extends MyTriggers {
    global override void onAfterInsert() {
        List<SharingEvent__e> events=new List<SharingEvent__e>();
        //run sharing in a platform event
        
        for(NavTask__c task:(List<NavTask__c>) records){
            SharingEvent__e event=new SharingEvent__e();
            event.RecordId__c=task.Id;
            event.ObjectType__c='NavTask__c';
            events.add(event);
        }
       
        if(events.size()>0){
            EventBus.publish(events);
        }
    }

    public void grantAccessToNewTasks(List<NavTask__c> tasks){
        new NavTaskAccessService().grantAccess(tasks, getPersons(tasks));
    }
    
    private List<Person__c> getPersons(List<NavTask__c> tasks) {
        Set<Id> accountIds = new Set<id>();
        for (NavTask__c task : tasks) {
            accountIds.add(task.CRM_Account__c);
        }

        return [
            SELECT INT_Confidential__c, INT_IsNavEmployee__c, CRM_Account__c
            FROM Person__C
            WHERE CRM_Account__c IN :accountIds
        ];
    }
}
