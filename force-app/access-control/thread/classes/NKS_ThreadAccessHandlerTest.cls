@IsTest
private class NKS_ThreadAccessHandlerTest {
    @TestSetup
    static void makeData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // HOT Servicetjenesten rules
            Test.loadData(ApexSharingRule__mdt.SObjectType, 'MockData_ThreadAccessHandler');
        }
        TestDataFactory.getPublicGroup('NKS Veiledere', NKS_GroupVariables.VEILEDER_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Adresse', NKS_GroupVariables.FORTROLIG_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Skjermet', NKS_GroupVariables.SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('NKS Fortrolig Skjermet', NKS_GroupVariables.FORTROLIG_SKJERMET_GROUP_NAME);
        TestDataFactory.getPublicGroup('Tema SER', NKS_GroupVariables.TEMA_SER_NAME);
        TestDataFactory.getPublicGroup('Fortrolig SER', NKS_GroupVariables.FORTROLIG_SER_NAME);
        TestDataFactory.getPublicGroup('Skjermet SER', NKS_GroupVariables.SKJERMET_SER_NAME);
        TestDataFactory.getPublicGroup('Fortrolig Skjermet SER', NKS_GroupVariables.FORTROLIG_SKJERMET_SER_NAME);
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Veiledere', 'group_470011');
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Fortrolig', 'group_470012');
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Skjermet', 'group_470013');
        TestDataFactory.getPublicGroup('HOT_ST_Thread_Fortrolig_Skjermet', 'group_470014');

        //we don't want person trigger access handlers to be run on test data insert
        myTriggers.disable(PersonAccessHandler.class);

        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = false;
        insert person;
    }

    @IsTest
    private static void onAfterUpdateTemaChangeTest() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Common_Code__c cc1 = new Common_Code__c(Name = 'Arbeid', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'ARB');
        insert cc1;
        Common_Code__c cc2 = new Common_Code__c(Name = 'Pensjon', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'PEN');
        insert cc2;
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO', CRM_Theme__c = cc1.Id);
        insert thread;
        Thread__Share share = new Thread__Share();
        share.RowCause = 'Manual';
        share.UserOrGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        share.ParentId = thread.Id;
        share.AccessLevel = 'Edit';
        insert share;
        Test.startTest();
        thread.CRM_Theme__c = cc2.Id;
        update thread;
        Test.stopTest();

        List<Thread__Share> shareList = [
            SELECT Id
            FROM Thread__Share
            WHERE RowCause = 'Manual' AND ParentId = :thread.id
        ];

        System.assertEquals(1, shareList.size(), 'Expected only One sharing');
        System.assertNotEquals(share.Id, shareList[0].Id, 'Expected old share deleted and new created');
    }

    @IsTest
    private static void grantAccess_whenUgradertAndNotNavEmployee() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME LIMIT 1].Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 41002'
        );
    }

    @IsTest
    private static void grantAccess_whenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1]
        .Id;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected thread to be shared with code 7 group'
        );
    }

    @IsTest
    private static void grantAccess_whenSER() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.VEILEDER_GROUP_NAME
            LIMIT 1
        ]
        .Id;
        Id code7GroupId = [SELECT Id FROM Group WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_GROUP_NAME LIMIT 1]
        .Id;

        Id temaFortroligSER = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :NKS_GroupVariables.FORTROLIG_SER_NAME
            LIMIT 1
        ]
        .Id;
        Common_Code__c cc = new Common_Code__c(Name = 'Serviceklage', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'SER');

        insert cc;

        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO', CRM_Theme__c = cc.Id);
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected thread to be NOT shared with code 7 group'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :temaFortroligSER],
            'Expected thread to be shared with group Fortrolig SER'
        );
    }

    @IsTest
    private static void grantAccess_whenNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
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
        Test.startTest();
        Thread__c thread = new Thread__c(CRM_Account__c = accountId, CRM_Thread_Type__c = 'STO');
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be shared with skjermet group'
        );
    }

    @IsTest
    private static void grantAccess_whenConfEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
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
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread NOT to be shared with veiledere'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread NOT to be shared with fortrolig'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread NOT to be shared with skjermet group'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be shared with fortrolig skjermet group'
        );
    }

    @IsTest
    private static void grantAccessWhenUgradertAndNotNavEmployee() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
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
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 470011'
        );
    }
    @IsTest
    private static void grantAccessOnCategoryChange() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Arbeid'
        );
        insert thread;
        Test.getEventBus().deliver();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread not to be shared with group 470011'
        );

        Test.startTest();
        thread.STO_Category__c = 'Hjelpemidler';
        update thread;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 470011'
        );
    }
    @IsTest
    private static void revokeAccessWhenOnCategoryChange() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id groupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;

        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.getEventBus().deliver();
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be shared with group 410011'
        );
        Test.startTest();
        thread.STO_Category__c = 'Arbeid';
        update thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :groupId],
            'Expected thread to be not shared with group 410011'
        );
    }

    @IsTest
    private static void grantAccessWhenFortrolig() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = false;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470011'
            LIMIT 1
        ]
        .Id;
        Id code7GroupId = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'group_470012'
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
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :code7GroupId],
            'Expected thread to be shared with code 7 group'
        );
    }

    @IsTest
    private static void grantAccessWhenNavEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'UGRADERT';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
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
        Test.startTest();
        Thread__c thread = new Thread__c(
            CRM_Account__c = accountId,
            CRM_Thread_Type__c = 'STO',
            STO_Category__c = 'Hjelpemidler'
        );
        insert thread;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread not to be shared with veiledere'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread to be shared with skjermet group'
        );
    }

    @IsTest
    private static void grantAccessWhenConfEmployee() {
        Person__c person = TestDataFactory.getPersons(1, false)[0];
        person.INT_Confidential__c = 'FORTROLIG';
        person.INT_IsNavEmployee__c = true;
        insert person;
        Id accountId = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id LIMIT 1].Id;
        Id veiledereGroupId = [
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
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :veiledereGroupId],
            'Expected thread NOT to be shared with veiledere'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligGroupId],
            'Expected thread NOT to be shared with fortrolig'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :skjermetGroupId],
            'Expected thread NOT to be shared with skjermet group'
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Thread__Share WHERE RowCause = 'Manual' AND UserOrGroupId = :fortroligSkjermetGroupId],
            'Expected thread to be shared with fortrolig skjermet group'
        );
    }
}
