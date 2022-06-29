public with sharing class NKS_HomePageGroupMemberFinder {
    public static Set<Id> getUserIdsFromGroups(List<Id> groupIds) {
        /** Final users result */
        Set<Id> result = new Set<Id>();
        /** Key prefix of SObjects types */
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxies = new Set<Id>();

        /** get active users and all groups */
        Map<Id, User> activeUsersMap = new Map<Id, User>([SELECT Id FROM User WHERE IsActive = TRUE]);

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
                    System.debug(ex.getStackTraceString());
                }

                // Look for users from other groups
                if (groupIdProxies.size() > 0) {
                    List<Id> Ids = new List<Id>(groupIdProxies);
                    result.addAll(getUserIdsFromGroups(Ids));
                }
            }
        } // END group ids loop
        return result;
    }

    @invocableMethod(label='Get Group Members')
    public static List<List<Id>> getGroupMembers(List<Id> IDs) {
        List<List<Id>> res = new List<List<Id>>();
        List<Id> IDSet = new List<Id>(getUserIdsFromGroups(IDs));
        res.add(IDSet);
        System.debug('Final list: ' + res);
        return res;
    }
}
