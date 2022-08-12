public with sharing class NKS_KnowledgeBrokenLinksFinder {
    public static void findLinks(Id articleId) {
        Knowledge__kav article = [
            SELECT
                Id,
                AdvisorInformation__c,
                AdvisorInformationInternal__c,
                Article__c,
                EmployerInformation__c,
                EmployerInformationInternal__c,
                NKS_English__c,
                InternationalInformation__c,
                InternationalInformationInternal__c,
                NKS_Legislation__c,
                NKS_Nav_no__c,
                NKS_Nynorsk__c,
                NKS_Resources__c,
                NKS_Summary__c,
                NKS_UserInformation__c,
                WhoDoesWhat__c
            FROM Knowledge__kav
            WHERE Id = :articleId
        ];

        String regex1 = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        String regex2 = '<a.+<\\/a>';
        Pattern linksPattern = Pattern.compile(regex1);
        Pattern anchorsPattern = Pattern.compile(regex2);
        List<String> matches = new List<String>();

        // get all text fields for each article
        List<String> strList = new List<String>{
            article.AdvisorInformation__c,
            article.AdvisorInformationInternal__c,
            article.Article__c,
            article.EmployerInformation__c,
            article.EmployerInformationInternal__c,
            article.NKS_English__c,
            article.InternationalInformation__c,
            article.InternationalInformationInternal__c,
            article.NKS_Legislation__c,
            article.NKS_Nav_no__c,
            article.NKS_Nynorsk__c,
            article.NKS_Resources__c,
            article.NKS_Summary__c,
            article.NKS_UserInformation__c,
            article.WhoDoesWhat__c
        };

        if (strList.size() > 0) {
            // find all links
            for (String str : strList) {
                try {
                    List<Matcher> matchers = new List<Matcher>{
                        linksPattern.matcher(str),
                        anchorsPattern.matcher(str)
                    };
                    for (Matcher m : matchers) {
                        while (m.find()) {
                            String groupValue = m.group();
                            matches.add(groupValue);
                        }
                    }
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                }
            }
        }
        System.debug(matches);
    }
}
