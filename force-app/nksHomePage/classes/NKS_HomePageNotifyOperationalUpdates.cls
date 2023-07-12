public with sharing class NKS_HomePageNotifyOperationalUpdates {
    public static Set<Id> getUserIdsFromGroups(Set<Id> groupIds) {
        /** Final users result */
        Set<Id> result = new Set<Id>();
        /** Key prefix of SObjects types */
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxies = new Set<Id>();

        /** get active users and all groups */
        Map<Id, User> activeUsersMap = new Map<Id, User>(
            [
                SELECT Id
                FROM User
                WHERE IsActive = TRUE AND ProfileId IN (SELECT Id FROM Profile WHERE Name LIKE 'NAV Kontaktsenter%')
            ]
        );

        for (Id groupElementId : groupIds) {
            if (String.valueOf(groupElementId.getSobjectType()) == 'Group') {
                try {
                    for (GroupMember groupMember : [
                        SELECT Id, UserOrGroupId, GroupId, Group.type
                        FROM GroupMember
                        WHERE GroupId IN :groupIds
                    ]) {
                        if (
                            ((String) groupMember.UserOrGroupId).startsWith(userType) &&
                            activeUsersMap.get(groupMember.UserOrGroupId) != null
                        ) {
                            result.add(groupMember.UserOrGroupId);
                        } else if (((String) groupMember.UserOrGroupId).startsWith(groupType)) {
                            groupIdProxies.add(groupMember.UserOrGroupId);
                        }
                    }
                } catch (Exception ex) {
                    System.debug('Problem getting  group members: ' + ex.getMessage());
                }

                // Look for users from other groups
                if (groupIdProxies.size() > 0) {
                    result.addAll(getUserIdsFromGroups(groupIdProxies));
                }
            }
        } // END group ids loop
        return result;
    }

    public static void notifyUsers(Set<String> recipientsIds, String message) {
        String pageRef = '{"type": "standard__namedPage","attributes": {"pageName": "home","actionName": "view"}}';

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'Notify_Operational_Updates'
        ];

        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle('NKS Driftsmelding');
        notification.setBody(message);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetPageRef(pageRef);

        // Actually send the notification
        try {
            notification.send(recipientsIds);
        } catch (Exception ex) {
            System.debug('Problem sending notification: ' + ex.getMessage());
        }
    }

    @invocableMethod(label='Send Notification')
    public static void sendNotification(List<String> message) {
        // Get GroupId
        Set<Id> groupIds = new Set<Id>();
        Group g = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'group_41001'];
        groupIds.add(g.Id);

        // Get UserId for GroupMembers
        List<Id> IDSet = new List<Id>(getUserIdsFromGroups(groupIds));

        if (IDSet.size() > 500) {
            // Split List of Ids into smaller lists
            List<Set<String>> res = new List<Set<String>>();
            for (Integer i = 0; i < (IDSet.size() / 500) + 1; i++) {
                Set<String> tempList = new Set<String>();
                for (Integer j = (i * 500); (j < (i * 500) + 500) && j < IDSet.size(); j++) {
                    tempList.add(IDSet.get(j));
                }
                res.add(tempList);
            }

            // Send notification to all users
            try {
                for (Set<String> Ids : res) {
                    notifyUsers(Ids, message[0]);
                }
            } catch (Exception ex) {
                System.debug('There was problem to send notification to all users: ' + ex.getMessage());
            }

            System.debug('Final list: ' + res);
        } else {
            Set<String> ids = new Set<String>();
            for (Integer i = 0; i < IDSet.size(); ++i) {
                ids.add(IDSet.get(i));
            }
            try {
                notifyUsers(ids, message[0]);
            } catch (Exception ex) {
                System.debug('There was problem to send notification to users: ' + ex.getMessage());
            }
        }
    }
}
