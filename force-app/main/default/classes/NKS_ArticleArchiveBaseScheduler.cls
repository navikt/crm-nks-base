global abstract class NKS_ArticleArchiveBaseScheduler implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    @TestVisible
    protected String query = '';
    protected String settingName;
    protected String journalPostType;

    public NKS_ArticleArchiveBaseScheduler() {
    }

    public NKS_ArticleArchiveBaseScheduler(String query, String settingName, String journalPostType) {
        this.query = query;
        this.settingName = settingName;
        this.journalPostType = journalPostType;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext context, List<NKS_Announcement__c> scope) {
        NKS_ArticleArchiveHandler handler = new NKS_ArticleArchiveHandler(this.settingName, this.journalPostType);
        for (NKS_Announcement__c article : scope) {
            handler.execute(article);
        }
    }

    public void finish(Database.BatchableContext context) {
        return;
    }
}
