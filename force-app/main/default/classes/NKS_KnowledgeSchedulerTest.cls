@isTest
public with sharing class NKS_KnowledgeSchedulerTest {
    @isTest
    static void testExecuteScheduler() {
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2042';
        // Schedule the test job
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new NKS_KnowledgeScheduler());

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2042-09-03 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
    }
}
