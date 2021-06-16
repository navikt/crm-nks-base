public with sharing class nksDueDateUtility {
    /**
     * Method to populate a due date, based on both theme, and task type
     * Calculate number of days from mdt, and will not set on holidays
     * @author Lars Petter Johnsen
     * @date 11.06.2021
     */
    @invocableMethod(label='get Due Date' category='Oppgave')
    public static List<Date> setDueDate(List<NavTask__c> taskList) {
        NavTask__c task = taskList.get(0);
        List<Holiday> holidays = [SELECT ActivityDate FROM Holiday];
        List<Date> holidayDateList = new List<Date>();
        for (Holiday h : holidays) {
            holidayDateList.add(h.ActivityDate);
        }

        String theme = [SELECT CRM_Code__c FROM Common_Code__c WHERE Id = :task.NKS_Theme__c]?.CRM_Code__c;
        String taskType = [SELECT CRM_Code__c FROM Common_Code__c WHERE Id = :task.NKS_TaskType__c]?.CRM_Code__c;
        System.debug(theme);
        System.debug(taskType);
        if (theme != null && taskType != null) {
            NAV_Task_Due_Date__mdt duedateRecord;
            try {
                duedateRecord = [
                    SELECT nksBusiness_Days__c
                    FROM NAV_Task_Due_Date__mdt
                    WHERE nksTheme_Code__c = :theme AND nksTask_Type__c = :taskType
                ];
            } catch (QueryException e) {
                LoggerUtility logger = new LoggerUtility('Oppgave');
                logger.exception(e);
                logger.publish();
            }

            Date today = Date.today();
            Date startDate;
            if (duedateRecord != null) {
                startDate = today.addDays(Integer.valueOf(duedateRecord.nksBusiness_Days__c));
            } else {
                startDate = today.addDays(2); // If no valid configuration default to 2 days
            }

            Boolean valid = false;

            while (valid == false) {
                Date monday = startDate.toStartOfWeek();
                Integer dayNo = monday.daysBetween(startDate);

                if (dayNo == 6 || dayNo == 7 || holidayDateList.contains(startDate)) {
                    startdate = startDate.addDays(1);
                } else {
                    valid = true;
                    break;
                }
            }
            return new List<Date>{ startDate };
        }
        return null;
    }
}
