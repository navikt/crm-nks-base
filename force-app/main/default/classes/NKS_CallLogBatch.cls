global class NKS_CallLogBatch implements Database.Batchable<sObject> {
    private static LoggerUtility logger = new LoggerUtility('NKS_CallLogBatch');
    private String query = 'SELECT Id, NKS_SessionId__c, NKS_Case__c FROM NKS_Call_Log__c WHERE NKS_Phone_Number__c = null or NKS_Case__r.NKS_Puzzel_Queue_Name__c in :puzzelQueuesNotToLog';

    private static final List<String> puzzelQueuesNotToLog = new List<String>{
        'gjeldsrådgivning',
        'gjeldsrådgivning nav-ansatt',
        'gjeldsveiledning',
        'gjeldsveiledning nav-ansatt',
        'sosiale tjenester',
        'sosiale tjenester nav-ansatt'
    };

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<NKS_Call_Log__c> scope) {
        try {
            List<NKS_Call_Log__c> callLogsToUpdate = new List<NKS_Call_Log__c>();
            List<NKS_Call_Log__c> callLogsToDelete = new List<NKS_Call_Log__c>();

            List<String> sessionIds = new List<String>();
            List<String> caseIds = new List<String>();
            for (NKS_Call_Log__c callLog : scope) {
                sessionIds.add(callLog.NKS_SessionId__c);
                caseIds.add(callLog.NKS_Case__c);
            }

            List<NKS_CallFlowController.CallQueueResponse> callQueueInfo = NKS_CallFlowController.getCallQueueInfo(
                sessionIds
            );

            Set<String> themeCodes = new Set<String>();
            for (NKS_CallFlowController.CallQueueResponse callQueue : callQueueInfo) {
                if (!String.isBlank(callQueue.themeGroup)) {
                    themeCodes.add(callQueue.themeGroup);
                }
            }

            Map<Id, Case> cases = new Map<Id, Case>([SELECT Id, NKS_Theme_Group__c FROM Case WHERE Id = :caseIds]);

            Map<String, Conversation_note__c> cNotes = new Map<String, Conversation_note__c>();
            List<Conversation_note__c> cNotesList = [
                SELECT Id, CRM_Case__c
                FROM Conversation_Note__c
                WHERE CRM_Case__c IN :cases.keySet()
            ];

            for (Conversation_note__c cNote : cNotesList) {
                cNotes.put(cNote.CRM_Case__c, cNote);
            }

            Map<String, Common_Code__c> themeMap = new Map<String, Common_code__c>();
            List<Common_code__c> themeList = [
                SELECT Id, CRM_Code__c, Name
                FROM Common_Code__c
                WHERE CRM_Code_set__c = 'Temagrupper' AND CRM_Code__c IN :themeCodes
            ];

            for (Common_Code__c theme : themeList) {
                themeMap.put(theme.CRM_Code__c, theme);
            }

            for (Integer i = 0; i < scope.size(); i++) {
                NKS_Call_Log__c callLog = scope[i];
                NKS_CallFlowController.CallQueueResponse queueInfo = callQueueInfo[i];
                Boolean logNeedsToBeDeleted = puzzelQueuesNotToLog.contains(queueInfo.queueName.toLowerCase());

                Case c = cases.get(callLog.NKS_Case__c);
                Common_Code__c themeGroup = themeMap.get(queueInfo.themeGroup);
                c.NKS_Puzzel_Queue_Name__c = queueInfo.queueName;
                if (themeGroup != null) {
                    callLog.NKS_Theme_Group__c = themeGroup.Id;
                    if (c.NKS_Theme_Group__c == null) {
                        c.NKS_Theme_Group__c = themeGroup.Id;
                    }
                }
                Conversation_note__c conv = cNotes.get(c.Id);
                if (conv != null) {
                    conv.NKS_Access_Number__c = logNeedsToBeDeleted ? null : queueInfo.accessNumber;
                }

                if (logNeedsToBeDeleted) {
                    callLogsToDelete.add(callLog);
                } else {
                    callLog.NKS_Phone_Number__c = queueInfo.accessNumber;
                    callLogsToUpdate.add(callLog);
                }
            }

            updateAndLog(callLogsToUpdate, 'Failed to update callLogs with Id:');
            updateAndLog(cases.values(), 'Failed to update cases with Id:');
            deleteAndLog(callLogsToDelete, 'Failed to delete callLogs with Id:');
            updateAndLog(cNotes.values(), 'Failed to update cNotes with Id:');
        } catch (Exception e) {
            logger.exception(e, null, CRM_ApplicationDomain.Domain.NKS);
        }
        logger.publish();
    }

    private void updateAndLog(List<SObject> records, String message) {
        try {
            Database.SaveResult[] results = Database.update(records, false);
            for (Database.SaveResult result : results) {
                if (Test.isRunningTest() || !result.isSuccess()) {
                    logger.error(
                        message +
                            ' ' +
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
                'NKS_CallLogBatch failed: ' + e.getMessage() + '. ' + e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        }
    }

    private void deleteAndLog(List<SObject> records, String message) {
        try {
            Database.DeleteResult[] results = Database.delete(records, false);
            for (Database.DeleteResult result : results) {
                if (Test.isRunningTest() || !result.isSuccess()) {
                    logger.error(
                        message +
                            ' ' +
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
                'NKS_CallLogBatch failed: ' + e.getMessage() + '. ' + e.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}
