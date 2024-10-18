global class NKS_NewsArchive_Scheduler implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    private String query='';
    
    public NKS_NewsArchive_Scheduler(){
        this.query='SELECT Id, Name , toLabel(Skills__c), NKS_News_Publish_Date__c FROM NKS_Announcement__c WHERE RecordType.Name=\'News\' AND NKS_News_Archive__c=TRUE AND NKS_News_Delete_Date__c=TOMORROW AND NKS_News_Status__c=\'Published\'';
    }

    public NKS_NewsArchive_Scheduler(String query){
        this.query=query;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new NKS_NewsArchive_Scheduler(query),1);
    } 

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext context, List<NKS_Announcement__c> scope) {
       
        NKS_NewsArchiveHandler handler=new NKS_NewsArchiveHandler();
        for(NKS_Announcement__c article:scope){
            handler.execute(article);
        }
    }
   
     public void finish(Database.BatchableContext context) {
       return;
    }
}