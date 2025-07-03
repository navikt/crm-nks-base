@IsTest
private class NKS_ThreadPersonAccessHandlerTest {
    @TestSetup
    static void makeData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // HOT Servicetjenesten rules
            Test.loadData(ApexSharingRule__mdt.SObjectType, 'MockData_ThreadAccessHandler');
        }
        TestDataFactory.getPublicGroup('NKS Veileder', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Adresse', NKS_GroupVariables.FORTROLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Skjermet', NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Veiledere', 'group_470011');
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Fortrolig', 'group_470012');
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Skjermet', 'group_470013');
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Fortrolig_Skjermet', 'group_470014');
    }

    @IsTest
    private static void grantAccess_whePersonIsChagnedToNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.getEventBus().deliver();
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread NOT to be shared with group 410099'
        );
        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410099'
        );
    }

    @IsTest
    private static void grantAccess_whePersonIsChagnedFromNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.getEventBus().deliver();
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to not be shared with group 41002'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = false;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 41002'
        );
    }
    @isTest
    private static void grantAccess_whenPersonIsConfEmployee() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;

        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.getEventBus().deliver();
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 41002'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 410099'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 999908'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 999905'
        );
        Test.startTest();
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be NOT shared with group 41002'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 410099'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 999908'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be shared with group 999905'
        );
    }

    @isTest
    private static void grantAccess_onThreadCreate() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId],
            'Expected thread to be shared with group 41002'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be NOT shared with group 410099'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread to be NOT shared with group 999908'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be NOT shared with group 999905'
        );
    }

    @IsTest
    private static void grantAccessOnPersonChangeToNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.getEventBus().deliver();

        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;
        Id groupSkjermetId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470013'
            LIMIT 1
        ]
        .Id;

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupId
            ],
            'Expected thread to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupSkjermetId
            ],
            'Expected thread not to be shared with group 470013'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupId
            ],
            'Expected thread not to be shared with group 470011'
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupSkjermetId
            ],
            'Expected thread to be shared with group 470013'
        );
    }
    @IsTest
    private static void grantAccessOnPersonChagneFromNavEmployee() {
        //we don't want person trigger access handlers to be run on test data insert/update
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.getEventBus().deliver();

        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;
        Id groupSkjermetId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470013'
            LIMIT 1
        ]
        .Id;

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupId
            ],
            'Expected thread to not be shared with group 470011'
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupSkjermetId
            ],
            'Expected thread to be shared with group 470013'
        );

        Test.startTest();
        person.INT_IsNavEmployee__c = false;
        update person;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupId
            ],
            'Expected thread to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupSkjermetId
            ],
            'Expected thread not to be shared with group 470013'
        );
    }
    @isTest
    private static void grantAccessWhenPersonIsConfEmployee() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.getEventBus().deliver();

        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;
        Id groupSkjermetId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470013'
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470012'
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470014'
            LIMIT 1
        ]
        .Id;

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupId
            ],
            'Expected thread to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupSkjermetId
            ],
            'Expected thread not to be shared with group 470013'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId
            ],
            'Expected thread not to be shared with group 470012'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected thread not to be shared with group 470014'
        );

        Test.startTest();
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        update person;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupId
            ],
            'Expected thread to be shared with group 470011'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :groupSkjermetId
            ],
            'Expected thread not to be shared with group 470013'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId
            ],
            'Expected thread to be NOT shared with group 470012'
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected thread to be NOT shared with group 470014'
        );
    }

    @IsTest
    private static void grantAccessOnThreadCreate() {
        myTriggers.disable(PersonAccessHandler.class);
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470013'
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470012'
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470014'
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId
            ],
            'Expected thread to be shared with group 470011'
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected thread to be NOT shared with group 470013'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId
            ],
            'Expected thread to be NOT shared with group 470012'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected thread to be NOT shared with group 470014'
        );
    }

    @IsTest
    private static void grantNoAccessOnNotHjelpemidler() {
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;

        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;

        Id veilederGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;
        Id skjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470013'
            LIMIT 1
        ]
        .Id;
        Id fortroligGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470012'
            LIMIT 1
        ]
        .Id;
        Id fortroligSkjermetGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470014'
            LIMIT 1
        ]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Arbeid'
        );
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :veilederGroupId
            ],
            'Expected thread to be shared with group 470011'
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId
            ],
            'Expected thread to be NOT shared with group 470013'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId
            ],
            'Expected thread to be NOT shared with group 470012'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE ParentId = :thread.Id AND RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId
            ],
            'Expected thread to be NOT shared with group 470014'
        );
    }
}
