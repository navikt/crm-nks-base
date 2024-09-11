public with sharing class NKS_CustomNotificationController {
    private static LoggerUtility logger = new LoggerUtility ();

    @invocableMethod(label = 'Send Notification')
    public static void sendNotification(List<Request> requests) {
        for (Request request : requests) {
            if (!request.userIds.isEmpty()) {
                Set<Id> userIds = new Set<Id>(request.userIds);

                // Convert Set to List for indexing
                List<Id> userIdList = new List<Id>(userIds);

                // Check if the size exceeds 500
                if (userIdList.size() > 500) {
                    List<Set<Id>> res = new List<Set<Id>>();

                    // Split List of Ids into smaller lists of 500
                    for (Integer i = 0; i < (userIdList.size() / 500) + 1; i++) {
                        Set<Id> tempList = new Set<Id>();
                        for (Integer j = i * 500; j < (i + 1) * 500 && j < userIdList.size(); j++) {
                            tempList.add(userIdList[j]);
                        }
                        res.add(tempList);
                    }

                    for (Set<Id> ids : res) {
                        sendNotificationToUsers(
                            ids, 
                            request.notificationTypeId, 
                            request.notificationTitle, 
                            request.notificationBody, 
                            request.targetId, 
                            request.pageRef
                        );
                    }
                } else {                   
                    sendNotificationToUsers(
                        userIds, 
                        request.notificationTypeId, 
                        request.notificationTitle, 
                        request.notificationBody, 
                        request.targetId, 
                        request.pageRef
                    );
                }
            }
        }
    }

    private static void sendNotificationToUsers(
        Set<Id> userIds, 
        String notificationTypeId, 
        String notificationTitle, 
        String notificationBody, 
        Id targetId, 
        String pageRef
    ) {
        Set<String> recipientsIds = new Set<String>();
        for (Id id : userIds) {
            recipientsIds.add(id.toString());
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
            logger.error('Failed to send notification to users: ' + ex.getMessage(), null, CRM_ApplicationDomain.Domain.NKS);   
            logger.publish(); 
        }
    }

    public class Request {
        @InvocableVariable(required = true)
        public List<Id> userIds;

        @InvocableVariable(required = true)
        public String notificationTypeId;

        @InvocableVariable(required = true)
        public String notificationTitle;

        @InvocableVariable(required = true)
        public String notificationBody;

        @InvocableVariable
        public Id targetId;

        @InvocableVariable
        public String pageRef;
    }
}