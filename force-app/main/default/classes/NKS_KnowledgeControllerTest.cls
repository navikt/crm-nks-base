@isTest
public with sharing class NKS_KnowledgeControllerTest {
    @isTest
    static void testFindDeadLinks() {
        Boolean throwsException = false;
        Test.startTest();
        try {
            NKS_KnowledgeController.findDeadLinks();
        } catch (Exception ex) {
            throwsException = true;
        }
        Test.stopTest();
        System.assertEquals(false, throwsException);
    }
}
