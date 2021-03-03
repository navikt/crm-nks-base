global class NKS_NavTaskTriggerHandler extends MyTriggers {
    global override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        List<FeedItem> feedItems = new List<FeedItem>();
        System.debug('NAV TASK TRIGGER');
        for (NavTask__c navTask : (List<NavTask__c>) Records) {
            if (
                hasChangedFields(
                    new List<String>{ 'CRM_Comments__c' },
                    navTask,
                    existingRecords.get(navTask.Id)
                )
            ) {
                NavTask__c prevTask = (NavTask__c) existingRecords.get(navTask.Id);
                //Create feed item for previous field value as long as it was not blank
                if (String.isNotBlank(prevTask.CRM_Comments__c)) {
                    feedItems.add(createFeedItem(prevTask));
                }
            }
        }

        insert feedItems;
    }

    private FeedItem createFeedItem(NavTask__c navTask) {
        return new FeedItem(ParentId = navTask.Id, Body = navTask.CRM_Comments__c);
    }
}
