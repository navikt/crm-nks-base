public with sharing class NKS_HomePageGroupMemberFinder {
    private static Set<Id> getAllSubRoleIds(Set<Id> roleIds) {
        Set<Id> currentRoleIds = new Set<Id>();

        // Get all of the roles underneath the passed roles
        for (UserRole userRole : [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleId != NULL])
            currentRoleIds.add(userRole.Id);

        // Go fetch some more roles!
        if (currentRoleIds.size() > 0)
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));

        return currentRoleIds;
    }

    public static Set<Id> getUserIdsFromGroups(List<Id> groupIds) {
        /** Final users result */
        Set<Id> result = new Set<Id>();
        /** Key prefix of SObjects types */
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        String roleType = Schema.SObjectType.UserRole.getKeyPrefix();
        /** Loop through all group members in a group */
        Set<Id> groupIdProxies = new Set<Id>();
        Set<Id> groupWithRole = new Set<Id>();
        Set<Id> groupWithRoleNSub = new Set<Id>();
        /** get active users and all groups */
        Map<Id, User> activeUsersMap = new Map<Id, User>([SELECT Id FROM User WHERE IsActive = TRUE]);
        Map<Id, Group> groupMap = new Map<Id, Group>([SELECT Id, RelatedId, Type FROM Group]);

        for (Id groupElementId : groupIds) {
            if (String.valueOf(groupElementId.getSobjectType()) == 'Group') {
                for (GroupMember groupMember : [
                    SELECT Id, UserOrGroupId, GroupId, Group.type
                    FROM GroupMember
                    WHERE GroupId IN :groupIds
                ]) {
                    //System.debug('Group Member: ' + groupMember);
                    // If the user or group id is a user
                    if (
                        ((String) groupMember.UserOrGroupId).startsWith(userType) &&
                        activeUsersMap.get(groupMember.UserOrGroupId) != null
                    ) {
                        result.add(groupMember.UserOrGroupId);
                    } else if (
                        groupMap.get(groupMember.UserOrGroupId) != null &&
                        (groupMap.get(groupMember.UserOrGroupId).RelatedId != null &&
                        ((String) groupMap.get(groupMember.UserOrGroupId).RelatedId).startsWith(roleType))
                    ) {
                        //System.debug('Group Member Type is:::: ' + groupMap.get(groupMember.UserOrGroupId).Type);

                        if (groupMap.get(groupMember.UserOrGroupId).Type == 'Role') {
                            groupWithRole.add(groupMap.get(groupMember.UserOrGroupId).RelatedId);
                        } else if (groupMap.get(groupMember.UserOrGroupId).Type == 'RoleAndSubordinates') {
                            groupWithRoleNSub.add(groupMap.get(groupMember.UserOrGroupId).RelatedId);
                        }
                    } else if (((String) groupMember.UserOrGroupId).startsWith(groupType)) {
                        // If the user or group id is a group
                        // Note: there may be a problem with governor limits if this is called too many times
                        // Call this function again but pass in the group found within this group
                        groupIdProxies.add(groupMember.UserOrGroupId);
                    } else if (groupMap.get(groupMember.UserOrGroupId).Type == 'Organization') {
                        // All active users
                        //System.debug('One of group ids in the set contains all internal users');
                        return activeUsersMap.keySet();
                    }
                }
                //System.debug('groupWithRole:::: ' + groupWithRole);
                //System.debug('groupWithRoleNSub:::: ' + groupWithRoleNSub);
                if (groupWithRoleNSub.size() > 0) {
                    groupWithRoleNSub.addAll(getAllSubRoleIds(groupWithRoleNSub));
                    Map<Id, User> users = new Map<Id, User>(
                        [SELECT Id, Name FROM User WHERE UserRoleId IN :groupWithRoleNSub AND isActive = :true]
                    );
                    result.addAll(users.keySet());
                }
                if (groupWithRole.size() > 0) {
                    Map<Id, User> users = new Map<Id, User>(
                        [SELECT Id, Name FROM User WHERE UserRoleId IN :groupWithRole AND isActive = :true]
                    );
                    result.addAll(users.keySet());
                }
                // Look for users from other groups
                if (groupIdProxies.size() > 0) {
                    List<Id> Ids = new List<Id>(groupIdProxies);
                    result.addAll(getUserIdsFromGroups(Ids));
                }
            } else if (String.valueOf(groupElementId.getSobjectType()) == 'CollaborationGroup') {
                for (CollaborationGroupMember collaborationGroupMember : [
                    SELECT Id, CollaborationGroupId, MemberId
                    FROM CollaborationGroupMember
                    WHERE CollaborationGroupId IN :groupIds
                ]) {
                    //System.debug('CollaborationGroupMember' + collaborationGroupMember.MemberId);
                    // If the user or group id is a user
                    if (
                        ((String) collaborationGroupMember.MemberId).startsWith(userType) &&
                        activeUsersMap.get(collaborationGroupMember.MemberId) != null
                    ) {
                        result.add(collaborationGroupMember.MemberId);
                    }
                }
            }
        } // END group ids loop
        //System.debug('Result Count (Users): ' + result.size());
        //System.debug('Result (Users): ' + result);
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