public class AdGroupSyncHandler extends AsyncJob {

    public override void execute(AsyncRequest__c ar){
        List<String> parameters = ar.CRM_Params__c.split(',');
        //Salesforce group id is first parameter
        Map<String,Id> salesforceGroupMembers=getSalesforceGroupMembers(parameters[0]);

        //get ad group members from Graph api. Ad Group Id is second paramter
        Map<String,Id> adGroupMembers=getAdGroupMembers(parameters[1]);

        //find user to be created as Salesforce group member
        List<GroupMember> membersToCreate=new List<GroupMember>();
        for(String username:adGroupMembers.keySet()){
            //add users who is not already member of Salesforce group
            if (!salesforceGroupMembers.keySet().contains(username)){
                membersToCreate.add(new GroupMember(UserOrGroupId=adGroupMembers.get(username), GroupId=parameters[0]));
            }
        }

      //delete users who are removed from AD group
      List<GroupMember> membersToDelete=new List<GroupMember>();
      Set<Id> userIdsToDelete=new Set<Id>();
      for(String username:salesforceGroupMembers.keySet()){
          if (!adGroupMembers.keySet().contains(username)){
              userIdsToDelete.add(salesforceGroupMembers.get(username));
          }
      }

      //delete members
      if(userIdsToDelete.size()>0){
          membersToDelete=[SELECT Id FROM GroupMember WHERE GroupId=:parameters[0] AND UserOrGroupId in:userIdsToDelete];
          delete membersToDelete;
      }

      //add members
      if(membersToCreate.size()>0){
        insert membersToCreate;
      }
    }

    private Map<String,Id> getSalesforceGroupMembers(Id salesforceGroupId){
        //get userid of group members
        Set<Id> userIds=new Set<Id>();
        for(GroupMember m:[SELECT UserOrGroupId FROM GroupMember WHERE GroupId=:salesforceGroupId]){
            userIds.add(m.UserOrGroupId);
        }

        //map username and userid
        Map<String,Id> userIdByUsername=new Map<String,Id>();
        for(User u:[SELECT Id, Username FROM User WHERE Id in:userids]){
            userIdByUsername.put(u.Username.toLowerCase(),u.Id);
        }
        return userIdByUsername;
    }

    private Map<String,Id> getAdGroupMembers(String adGroupId){
        AdGroupService.AdGroupResponse adGroupMembers=new AdGroupService().getAdGroupMembers(adGroupId);
        
        Map<String,Id> userIdByUsername=new Map<String,Id>();
        for(User u:[SELECT Id, Username FROM User WHERE Username in:adGroupMembers.usernames]){
            userIdByUsername.put(u.Username,u.Id);
        }

        //check if user is missing in Salesforce
        if(userIdByUsername.size()!=adGroupMembers.usernames.size()){
            for(String username:adGroupMembers.usernames){
                if(!userIdByUsername.keySet().contains(username)){
                   logError('AdGroupSyncHandler kunne ikke opprette medlem ' + username + ' fra gruppen ' + adGroupId);
                }
            }
        }
        return userIdByUsername;
    }

    private void logError(String message){
        LoggerUtility logger = new LoggerUtility();
        logger.error(message,null);
        logger.publish();
    }
}