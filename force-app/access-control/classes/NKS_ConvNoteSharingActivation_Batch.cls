
global class NKS_ConvNoteSharingActivation_Batch implements Database.Batchable<sObject> {
  
    global NKS_ConvNoteSharingActivation_Batch(){

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT CRM_Account__r.CRM_Person__c From Conversation_Note__c WHERE NKS_Incorrectly_Sent__c=false AND CRM_Account__r.CRM_Person__c!=null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Conversation_Note__c> scope) {

        Id veilederGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_41001' LIMIT 1].Id;
        Id skjermetGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'group_410098' LIMIT 1].Id;
        Id fortroligGroupId= [SELECT Id FROM Group WHERE DeveloperName = 'group_999907' LIMIT 1].Id;
        
        Set<Id> personIds=new Set<Id>();
        for(Conversation_Note__c note:scope){
            personIds.add(note.CRM_Account__r.CRM_Person__c);
        }

        Map<Id, Person__c> personById=new Map<Id,Person__c>();
        for(Person__c person : [SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c FROM Person__c WHERE Id in:personIds]){
            personById.put(person.Id,person);
        }
        
        List<Conversation_Note__Share> shareRecords = new List<Conversation_Note__Share>();
        for(Conversation_Note__c note:scope){

            Person__c person=personById.get(note.CRM_Account__r.CRM_Person__c);
            Id groupId;
            if(person.INT_Confidential__c=='UGRADERT' && person.INT_IsNavEmployee__c==false){
                groupId=veilederGroupId;
            }
            else if(person.INT_Confidential__c=='UGRADERT' && person.INT_IsNavEmployee__c==true){
                groupId=skjermetGroupId;
            }
            else if(person.INT_Confidential__c=='FORTROLIG'){
                groupId=fortroligGroupId;
            }

            Conversation_Note__Share share = new Conversation_Note__Share();
            share.ParentId = note.Id;
            share.UserOrGroupId = groupId;
            share.AccessLevel = 'Edit';
            share.RowCause = 'Manual';
            shareRecords.add(share);
        }
        Database.insert(shareRecords, false);
    }

    global void finish(Database.BatchableContext bc) {
    
    }
}
