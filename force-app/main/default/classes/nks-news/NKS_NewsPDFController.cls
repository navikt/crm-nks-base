public with sharing class NKS_NewsPDFController {
    public string title { get; set; }

    public string author { get; set; }

    public Datetime publishDate { get; set; }
    public Datetime lastModifiedDate { get; set; }
    public string information { get; set; }
    public string imageURL { get; set; }

    public NKS_NewsPDFController() {
        Id recordId = ApexPages.CurrentPage().getparameters().get('id');
        NKS_HomePageController instanceClass = new NKS_HomePageController();
        NKS_Announcement__c news = instanceClass.getNews(recordId);

        title = news.Name;
        author = news.NKS_News_Author__c;
        publishDate = news.NKS_News_Publish_Date__c;
        lastModifiedDate = news.LastModifiedDate;
        information = news.NKS_Information__c;
        imageURL = news.NKS_ImageURL__c;
    }
}
