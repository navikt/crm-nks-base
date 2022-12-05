@isTest
public with sharing class NKS_KnowledgeBrokenLinksFinderTest {
    @TestSetup
    static void makeData() {
        Knowledge__kav testArticle = new Knowledge__kav(
            Title = 'TestArticle',
            UrlName = 'Test-Article',
            Summary = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum',
            Article__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' +
                'test url :<a href="https://www.nav.no/testpath" target="_blank">nav.no</a>'
        );

        insert testArticle;
        Knowledge__kav a = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
    }

    @isTest
    static void testGetBrokenLinks() {
        Knowledge__kav a = [
            SELECT
                Title,
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
            LIMIT 1
        ];
        Map<String, List<String>> resMap = new Map<String, List<String>>();
        Test.startTest();
        resMap = NKS_KnowledgeController.getBrokenLinks(a);
        Test.stopTest();

        System.assertEquals(0, resMap.size());
    }

    @isTest(SeeAllData=false)
    static void testFindDeadLinks() {
        Boolean throwsException = false;
        Test.startTest();
        try {
            Database.executeBatch(new NKS_KnowledgeBrokenLinksFinder());
        } catch (Exception ex) {
            throwsException = true;
        }
        Test.stopTest();
        System.assertEquals(false, throwsException);
    }
}
