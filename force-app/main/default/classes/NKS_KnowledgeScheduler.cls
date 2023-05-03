public with sharing class NKS_KnowledgeScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        NKS_KnowledgeBrokenLinksFinder b = new NKS_KnowledgeBrokenLinksFinder();
        Database.executeBatch(b, 1);
    }
}
