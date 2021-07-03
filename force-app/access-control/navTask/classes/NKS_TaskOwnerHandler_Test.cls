@IsTest private class NKS_TaskOwnerHandler_Test {
    
    @TestSetup
    private static void setupTestData() {
        TestDataFactory.getQueue('Oslo', 'queue_391', 'NavTask__c');
    }

    @IsTest
    private static void testInseertNewTask(){
                
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

       

        User user=[SELECT Id, ProfileId FROM User WHERE isActive=TRUE LIMIT 1];
        Group queue=TestDataFactory.getQueue('Oslo', 'queue_391', 'NavTask__c');

        //mock custom settings for default owner
        insert new DefaultRecordOwner__c(
            SetupOwnerId= user.ProfileId,
            UserOrQueueId__c=queue.Id
        );
       
        Test.startTest();
        System.runAs(user) {
            Person__c person = TestDataFactory.getPersons(1, false)[0];
            person.INT_Confidential__c = 'UGRADERT';
            person.INT_IsNavEmployee__c = false;
            insert person;

            Account acc=[SELECT Id FROM Account LIMIT 1];

            NavTask__c task = new NavTask__c(CRM_Account__c = acc.Id);
            insert task;
        }
       
        Test.stopTest();
        
        NavTask__c newTask=[SELECT OwnerId FROM NavTask__c LIMIT 1];
        System.assertEquals(queue.Id, newTask.OwnerId);

    }

    @IsTest
    private static void testInseertNewTask_whenDefaultOwnerIsNotSet(){
                
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        User user=[SELECT Id, ProfileId FROM User WHERE isActive=TRUE LIMIT 1];
    
        Test.startTest();
        System.runAs(user) {
            Person__c person = TestDataFactory.getPersons(1, false)[0];
            person.INT_Confidential__c = 'UGRADERT';
            person.INT_IsNavEmployee__c = false;
            insert person;

            Account acc=[SELECT Id FROM Account LIMIT 1];
            NavTask__c task = new NavTask__c(CRM_Account__c = acc.Id);
            insert task;
        }
       
        Test.stopTest();
        
        NavTask__c newTask=[SELECT OwnerId FROM NavTask__c LIMIT 1];
        System.assertEquals(user.Id, newTask.OwnerId);

    }

}


