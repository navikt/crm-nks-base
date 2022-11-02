@isTest
public with sharing class NKS_KnowledgeBrokenLinksFinderTest {
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
