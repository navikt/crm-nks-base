global class CloseOldSTBCases_Batch implements Database.Batchable<sObject> {
    private static LoggerUtility logger = new LoggerUtility('CloseOldSTBCases_Batch');
    private String query = 'SELECT Id, CRM_isActive__c FROM Thread__c WHERE RecordType.DeveloperName = \'NKS_Thread\' AND CRM_Thread_Type__c = \'STB\' AND CRM_Latest_Message_Datetime__c <= N_DAYS_AGO:60 AND CRM_isActive__c = TRUE';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Thread__c> scope) {
        for (Thread__c thread : scope) {
            thread.CRM_isActive__c = false;
        }
        try {
            Database.SaveResult[] results = Database.update(scope, false);
            for (Database.SaveResult result : results) {
                if (Test.isRunningTest() || !result.isSuccess()) {
                    logger.error(
                        'Failed to close STB with Id:  ' +
                            result.getId() +
                            '\n' +
                            'Status code: ' +
                            result.getErrors()[0]?.getStatusCode() +
                            '\n' +
                            'Error: ' +
                            result.getErrors()[0]?.getMessage(),
                        null,
                        CRM_ApplicationDomain.Domain.NKS
                    );
                }
            }
        } catch (Exception e) {
            logger.error(
                'CloseOldSTBCases_Batch failed: ' + e.getMessage() + '. ' + e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        }
        logger.publish();
    }

    global void finish(Database.BatchableContext bc) {
    }
}
