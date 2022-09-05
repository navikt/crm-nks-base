@isTest
global with sharing class NKS_KnowledgeBrokenLinksFinderTest {
    @TestSetup
    static void makeData() {
        Knowledge__kav testKnowledge = new Knowledge__kav(
            Title = 'Test article for broken links',
            UrlName = 'Test-article-for-broken-links',
            Summary = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' +
                'test url 1: <a href="https://www.nav.no/test" target="_blank">test url</a>',
            Article__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' +
                'test url 2: <a href="https://www.nav.no" target="_blank">nav.no</a>'
        );
        insert testKnowledge;
    }

    @isTest
    static void testBrokenLinksFinder() {
        Test.startTest();
        NKS_KnowledgeBrokenLinksFinder batchFinder = new NKS_KnowledgeBrokenLinksFinder();
        Database.executeBatch(batchFinder, 2000);
        Test.stopTest();

        System.assertEquals(batchFinder.finalList.size(), 1);
    }
}
