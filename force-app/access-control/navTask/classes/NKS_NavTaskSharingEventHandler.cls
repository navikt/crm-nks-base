public without sharing class NKS_NavTaskSharingEventHandler extends RecordSharingEvent {
   
    private static LoggerUtility logger = new LoggerUtility('NAV Task');
    List<Id> recordIds=new List<Id>();

    public override void execute(List<RecordSharingEvent__e> recordSharingEvents) {
        try{
            for(RecordSharingEvent__e sharingEvent:recordSharingEvents){
                if(sharingEvent.ObjectType__c!='NavTask__c'){
                    continue;
                } 
                recordIds.add(sharingEvent.RecordId__c);
            }
            List<NavTask__c> tasks=[SELECT Id, CRM_Account__c, NKS_Theme__r.CRM_Code__c FROM NavTask__c WHERE Id in:recordIds];
            if(tasks.size()>0){
                new NavTaskAccessHandler().grantAccessToNewTasks(tasks);
            }
        } catch (Exception ex) {
            String recordIdsString = String.join( recordIds, ', ' );  
            logger.error(
    
                'Failed to share records: ' +
                recordIdsString +
                '\n' +
                ex.getMessage() +
                '\n' +
                ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                null
            );
        } finally {
            logger.publish();
        }
    }
}
