public with sharing class NKS_KnowledgeController {
    @invocableMethod(label='Find Broken List')
    public static void findDeadLinks() {
        Database.executeBatch(new NKS_KnowledgeBrokenLinksFinder(), 50);
    }
}
