@IsTest
private class AdGroupSyncHandler_ErrorHandlerTest {
    
    @TestSetup
    static void makeData(){
        //group for skjermede personer
        Group skjermedeGroup=TestDataFactory.getPublicGroup('Skjermede personer','ad_skjermede');


        //insert users from http mock
        Profile profile = [
            SELECT Id, UserLicense.Name
            FROM Profile
            WHERE Name = 'Standard Platform User'
            LIMIT 1
        ];
        String userName='F_Z994586.E_Z994586@trygdeetaten.no';
        List<User> users=new List<User>();
        users.add(new User(
            FirstName = 'F_Z994586',
            LastName = 'E_Z994586',
            Email = username,
            Username = username,
            Alias = 'E_Z99',
            LanguageLocaleKey = 'no',
            LocaleSidKey = 'no_NO',
            TimeZoneSidKey = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        ));
        insert users;
         
        //add running user to the group
         GroupMember member=new GroupMember();
         member.GroupId=skjermedeGroup.Id;
         member.UserOrGroupId=UserInfo.getUserId();
         insert member;
    }

    @IsTest
    private static void execute(){
        //http mock for Microosft Graph api
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'NKS_API_MOCK_GET_GROUP_MEMBERS_200' LIMIT 1];
        SingleRequestMock httpMock = new SingleRequestMock(200, 'Success', sr.Body.toString(),null);
        Test.setMock(HttpCalloutMock.class, httpMock);

        //get id of Salesforce Group
        Id salesforceGroupId=[SELECT Id FROM Group WHERE DeveloperName='ad_skjermede' LIMIT 1].Id;
        //get public group to 
        AsyncRequest__c req=new AsyncRequest__c();
        req.CRM_ApexJobType__c='Queueable';
        req.CRM_AsyncType__c='AdGroupSync';
        req.CRM_Params__c=salesforceGroupId + ', e48f9862-b4b3-4f9c-9dea-0fe8b2b48278';

        Test.startTest();
        AdGroupSyncHandler handler=new AdGroupSyncHandler();
        handler.execute(req);
        Test.stopTest();

        List<GroupMember> members=[SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId=:salesforceGroupId];
        System.assertEquals(1, members.size(), 'Expect one users to be added, and one removed and one insert to fail due to user is missing in Salesforce');
        Map<Id,Id> groupByUserId=new Map<Id,Id>();
        for(GroupMember m:members){
            groupByUserId.put(m.UserOrGroupId,m.GroupId);
        }

        //check which users who is member of group
        List<User> users=[SELECT Id FROM User WHERE Username='F_Z994586.E_Z994586@trygdeetaten.no'];
        System.assertEquals(salesforceGroupId, groupByUserId.get(users[0].Id), 'Expect first user to be member of group');

        //Error should be logged due to missing insert for users not existing in Salesforce
        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c WHERE Log_Level__c='Error'],'Expected error due to one missing user');
    }
}
