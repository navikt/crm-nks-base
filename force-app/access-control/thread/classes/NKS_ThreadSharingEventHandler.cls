public without sharing class NKS_ThreadSharingEventHandler extends RecordSharingEvent {
    private static final List<String> THREAD_TYPES_OF_INTEREST = new List<String>{ 'STO', 'STB', 'BTO', 'CHAT' };
    private static final Set<String> TOLK_THREAD_TYPES = new Set<String>{ 'HOT_BRUKER-TOLK' };
    private static LoggerUtility logger = new LoggerUtility('STO');
    List<Id> recordIds = new List<Id>();

    public override void execute(List<RecordSharingEvent__e> recordSharingEvents) {
        try {
            for (RecordSharingEvent__e sharingEvent : recordSharingEvents) {
                if (sharingEvent.ObjectType__c != 'Thread__c') {
                    continue;
                }
                recordIds.add(sharingEvent.RecordId__c);
            }

            List<Thread__c> threads = getThreadsByIds(recordIds);
            List<Thread__c> nksThreads = new List<Thread__c>();
            List<Thread__c> tolkThreads = new List<Thread__c>();
            for (Thread__c thread : threads) {
                if (THREAD_TYPES_OF_INTEREST.contains(thread.CRM_Thread_Type__c)) {
                    nksThreads.add(thread);
                } else if (TOLK_THREAD_TYPES.contains(thread.CRM_Thread_Type__c)) {
                    tolkThreads.add(thread);
                }
            }
            if (nksThreads.size() > 0 || tolkThreads.size() > 0) {
                if (nksThreads.size() > 0) {
                    new NKS_ThreadAccessHandler().grantAccessToNewThreads(threads);
                }
                if (tolkThreads.size() > 0) {
                    this.processTolkThreads(tolkThreads);
                }
            } else {
                logger.critical(
                    'Recieved Record Sharing event but found no Threads: \n' + String.join(recordIds, ', '),
                    null,
                    CRM_ApplicationDomain.Domain.NKS
                );
            }
        } catch (Exception ex) {
            String recordIdsString = String.join(recordIds, ', ');
            logger.critical(
                'Failed to share records: ' +
                    recordIdsString +
                    '\n' +
                    ex.getMessage() +
                    '\n' +
                    ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        } finally {
            logger.publish();
        }
    }
    private static List<Thread__c> getThreadsByIds(List<Id> threadIds) {
        String queryString =
            'SELECT Id, CRM_Account__c, CRM_Henvendelse_BehandlingsId__c, CRM_Office_Restriction__c, ' +
            'CRM_Theme_Code__c, CRM_Theme_Group_Name__c, STO_Category__c, CRM_Theme__c, CRM_Thread_Type__c, ' +
            (Test.isRunningTest() ? '' : 'HOT_ParticipantIds__c, ') +
            'CRM_Related_Object__c ' +
            'FROM Thread__c ' +
            'WHERE Id IN :threadIds';
        return (List<Thread__c>) Database.queryWithBinds(
            queryString,
            new Map<String, Object>{ 'threadIds' => threadIds },
            AccessLevel.SYSTEM_MODE
        );
    }
    private void processTolkThreads(List<Thread__c> threads) {
        Type hotThreadHandlerType = Type.forName('HOT_ThreadHandler');
        if (hotThreadHandlerType == null || !Callable.class.isAssignableFrom(hotThreadHandlerType)) {
            logger.critical(
                'HOT_ThreadHandler class not found or not Callable:\n' +
                String.join(new List<Id>(new Map<Id, Thread__c>(threads).keySet()), ', '),
                null,
                CRM_ApplicationDomain.Domain.HOT
            );
            return;
        }
        Callable hotThreadHandler = (Callable) hotThreadHandlerType.newInstance();
        Map<String, List<Thread__c>> params = new Map<String, List<Thread__c>>{ 'threads' => threads };
        hotThreadHandler.call('setInterpreter', params);
    }
}
