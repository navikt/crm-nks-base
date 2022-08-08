global class ArchiveNews_Schedule implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    private String query='';
    
    public ArchiveNews_Schedule(){
        this.query='SELECT Id, Name ,Skills__c, NKS_News_Publish_Date__c FROM NKS_Announcement__c WHERE NKS_News_Archive__c=TRUE AND NKS_News_Delete_Date__c=YESTERDAY AND NKS_News_Status__c=\'Published\'';
    }

    public ArchiveNews_Schedule(String query){
        this.query=query;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ArchiveNews_Schedule(query),1);
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
