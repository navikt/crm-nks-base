/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 14-02-2023
 * @last modified by  : mamikals
 **/
public with sharing class NKS_OppgaveCheckFailed {
    public static List<String> getFailedOppgaverPersonList(Date day) {
        List<NavTask__c> allEverySingleOneTasks = [SELECT Id FROM NavTask__c];
        List<NavTask__c> selectToSee = [
            SELECT
                RecordType.DeveloperName,
                CRM_Account__c,
                CRM_Account__r.CRM_Person__c,
                Int_external_reference__c,
                createdDate
            FROM NavTask__c
            LIMIT 1
        ];
        System.debug(allEverySingleOneTasks);
        System.debug(selectToSee);

        System.debug('WTf');

        List<String> returnList = new List<String>();

        try {
            CRM_OppgaveQueryList query = new CRM_OppgaveQueryList();
            Set<String> allAktoerIds = new Set<String>();
            Set<String> allAccountIds = new Set<String>();
            List<NavTask__c> failedTasks = [
                SELECT
                    Id,
                    CRM_Account__r.CRM_Person__r.Name,
                    CRM_Account__c,
                    NKS_Theme__r.CRM_Code__c,
                    NKS_TaskType__r.CRM_Code__c
                FROM NavTask__c
                WHERE
                    RecordType.DeveloperName != 'Employer'
                    AND CRM_Account__r.CRM_Person__c != NULL
                    AND Int_external_reference__c = NULL
                    AND DAY_ONLY(createdDate) = :day
            ];
            System.debug(failedTasks);
            for (NavTask__c task : failedTasks) {
                allAktoerIds.add(task.CRM_Account__r.CRM_Person__r.Name);
                allAccountIds.add(task.CRM_Account__c);
            }
            System.debug(allAccountIds);
            query.aktoerId = new List<String>(allAktoerIds);
            query.opprettetFom = day;
            if (!Test.isRunningTest()) {
                CRM_OppgaveSyncController.doMassOppgaveSync(query);
            }
            List<NavTask__c> allTasks = [
                SELECT Id, NKS_Theme__r.CRM_Code__c, NKS_TaskType__r.CRM_Code__c, CRM_account__c
                FROM NavTask__c
                WHERE
                    RecordType.DeveloperName != 'Employer'
                    AND CRM_Account__c IN :allAccountIds
                    AND NKS_Date_Registered__c = :Day
                    AND INT_External_Reference__c != NULL
            ];
            System.debug(allTasks);
            Map<Id, List<NavTask__c>> mappedTasks = new Map<Id, List<NavTask__c>>();
            for (NavTask__c groupTask : allTasks) {
                if (mappedTasks.containsKey(groupTask.CRM_account__c)) {
                    mappedTasks.get(groupTask.CRM_Account__c).add(groupTask);
                } else {
                    mappedTasks.put(groupTask.CRM_ACcount__c, new List<NavTask__c>{ groupTask });
                }
            }
            System.debug(mappedTasks);
            Boolean shouldAdd;
            for (NavTask__c checkTask : failedTasks) {
                shouldAdd = true;
                for (NavTask__c loopedTask : mappedTasks.get(checkTask.CRM_Account__c)) {
                    if (
                        loopedTask.NKS_Theme__r.CRM_Code__c == checkTask.NKS_Theme__r.CRM_Code__c &&
                        loopedTask.NKS_TaskType__r.CRM_Code__c == checkTask.NKS_TaskType__r.CRM_Code__c
                    ) {
                        shouldAdd = false;
                        break;
                    }
                }
                if (shouldAdd) {
                    returnList.add(checkTask.CRM_Account__r.CRM_Person__r.Name);
                }
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility('Oppgave');
            logger.exception(e, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }

        System.debug(returnList);
        return returnList;
    }
}
