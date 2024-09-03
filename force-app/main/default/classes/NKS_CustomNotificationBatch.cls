public with sharing class NKS_CustomNotificationBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> userIds;
    private String notificationTypeId;
    private String notificationTitle;
    private String notificationBody;
    private Id targetId;
    private String pageRef;

    public NKS_CustomNotificationBatch(Set<Id> userIds, String notificationTypeId, String notificationTitle, String notificationBody, Id targetId, String pageRef) {
        this.userIds = userIds;
        this.notificationTypeId = notificationTypeId;
        this.notificationTitle = notificationTitle;
        this.notificationBody = notificationBody;
        this.targetId = targetId;
        this.pageRef = pageRef;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id FROM User WHERE Id IN :userIds
        ]); 
    }

    public void execute(Database.BatchableContext BC, List<User> scope) {
        if (scope.isEmpty()) return;

        Set<String> recipientsIds = new Set<String>();
        for (User u : scope) {
            recipientsIds.add(u.Id);
        }

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTitle(notificationTitle);
        notification.setBody(notificationBody);
        notification.setTargetId(targetId);
        notification.setTargetPageRef(pageRef);

        try {
            notification.send(recipientsIds);
        } catch (Exception ex) {
            System.debug('Problem sending notification: ' + ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Finished sending notifications.');
    }
}
