global class NKS_ArticleArchiveNewsScheduler extends NKS_ArticleArchiveBaseScheduler {
    public NKS_ArticleArchiveNewsScheduler() {
        this.query = 'SELECT Id, Name, toLabel(Skills__c), NKS_News_Publish_Date__c, RecordType.DeveloperName FROM NKS_Announcement__c WHERE RecordType.DeveloperName=\'News\' AND NKS_News_Archive__c=TRUE AND NKS_News_Delete_Date__c=TOMORROW AND NKS_News_Status__c=\'Published\'';
        this.settingName = 'Websak_NKS_News_Setting__mdt';
        this.journalPostType = 'Nyheter NKS';
    }

    public NKS_ArticleArchiveNewsScheduler(String query) {
        super(query, 'Websak_NKS_News_Setting__mdt', 'Nyheter NKS');
    }
}
