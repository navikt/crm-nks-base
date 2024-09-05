public with sharing class NKS_CustomNotificationController {

    @invocableMethod(label='Send Custom Notification')
    public static void sendNotification(List<Request> requests) {
        for (Request request : requests) {
            if (!request.userIds.isEmpty()) {
                Database.executeBatch(
                    new NKS_CustomNotificationBatch(
                        request.userIds, 
                        request.notificationTypeId, 
                        request.notificationTitle, 
                        request.notificationBody, 
                        request.targetId, 
                        request.pageRef
                    ), 
                    200
                );
            }  
        }
    }

    public class Request {
        @InvocableVariable(required=true)
        public List<Id> userIds;

        @InvocableVariable(required=true)
        public String notificationTypeId;

        @InvocableVariable(required=true)
        public String notificationTitle;

        @InvocableVariable(required=true)
        public String notificationBody;

        @InvocableVariable
        public Id targetId;

        @InvocableVariable
        public String pageRef;
    }
}
