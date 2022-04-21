public with sharing class NKS_NewsPDFGenerator {
    public static Blob getPdf(Id articleId) {
        PageReference PDf = Page.NKS_NewsArticlePDF;
        PDf.getParameters().put('id', articleId);
        PDf.setRedirect(true);

        Blob b;
        if (Test.isRunningTest()) {
            return b;
        }
        b = PDf.getContent();
        return b;
    }
}
