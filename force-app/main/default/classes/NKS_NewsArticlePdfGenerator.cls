public with sharing class NKS_NewsArticlePdfGenerator {
    public static Blob getPdf(Id articleId) {
        PageReference PDf = Page.NKS_NewsArticlePDF;
        PDf.getParameters().put('id', articleId);
        PDf.setRedirect(true);

        Blob b;
        b = Test.isRunningTest() ? Blob.valueOf('Unit.Test') : PDf.getContent();
        return b;
    }
}
