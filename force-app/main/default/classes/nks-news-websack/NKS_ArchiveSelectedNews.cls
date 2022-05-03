global class NKS_ArchiveSelectedNews implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    private String query = '';

    public NKS_ArchiveSelectedNews() {
        this.query = 'SELECT Id, Name FROM NKS_Announcement__c WHERE NKS_TypeFormula__c=\'Nyhet\' AND NKS_News_Archive__c = true AND NKS_News_Delete_Date__c=TOMORROW AND NKS_News_Status__c=\'Published\'';
    }

    public NKS_ArchiveSelectedNews(String query) {
        this.query = query;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new NKS_ArchiveSelectedNews(), 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext context, List<NKS_Announcement__c> scope) {
        NKS_NewsArchiveHandler handler = new NKS_NewsArchiveHandler();
        for (NKS_Announcement__c news : scope) {
            handler.execute(news);
        }
    }

    public void finish(Database.BatchableContext context) {
        return;
    }
}
