@IsTest
private class AdGroupSyncHandlerTest {
    
    @TestSetup
    static void makeData(){
        //group for skjermede personer
        Group skjermedeGroup=TestDataFactory.getPublicGroup('Skjermede personer','ad_skjermede');

        //add running user to the group
        GroupMember member=new GroupMember();
        member.GroupId=skjermedeGroup.Id;
        member.UserOrGroupId=UserInfo.getUserId();
        insert member;

        //insert user from http mock
        Profile profile = [
            SELECT Id, UserLicense.Name
            FROM Profile
            WHERE Name = 'Standard Platform User'
            LIMIT 1
        ];
        String userName='F_Z994586.E_Z994586@trygdeetaten.no';
        User user = new User(
            FirstName = 'F_Z994586',
            LastName = 'E_Z994586',
            Email = username,
            Username = username,
            Alias = 'E_Z994586',
            LanguageLocaleKey = 'no',
            LocaleSidKey = 'no_NO',
            TimeZoneSidKey = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        );
        insert user;

        

    }

    @IsTest
    private static void execute(){
        //get public group to 
        AsyncRequest__c req=new AsyncRequest__c();
        req.CRM_ApexJobType__c='Queueable';
        req.CRM_AsyncType__c='AdGroupSync';

    }
}
