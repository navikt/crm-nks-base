//Add default admin user to the chat queue and grant chat access and adds default role for community user creation
User usr = [SELECT Id FROM User WHERE Name = 'User User' limit 1];
CallCenter center = [Select Id from CallCenter where Name = 'Demo Call Center Adapter' limit 1];
usr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'NKS' LIMIT 1]?.Id;
usr.CRM_NAV_Ident__c = 'Z999999'; //Setting default nav ident for the scratch user
usr.CallCenterId = center.Id;
update usr;

