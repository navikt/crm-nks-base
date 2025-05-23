@IsTest
public with sharing class NKS_CallLogBatch_Test {
    @TestSetup
    static void makeData() {
        NKS_Call_log__c callLog = new NKS_Call_Log__c();
        Case casey = new Case();
        Conversation_note__c cNote = new Conversation_Note__c();

        insert casey;

        callLog.NKS_Case__c = casey.Id;
        callLog.NKS_SessionId__c = NKS_CallFlowController_Test.TEST_SESSION_ID;
        cNote.CRM_Case__c = casey.Id;

        insert callLog;
        insert cNote;

        insert new Common_Code__c(CRM_Code__c = 'ARBD', CRM_Code_Set__c = 'Temagrupper', Name = 'Arbeid');
    }

    @IsTest
    static void NKS_CallLogBatch_runTest() {
        NKS_CallLogBatch batch = new NKS_CallLogBatch();

        Test.startTest();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();
        NKS_Call_Log__c callLog = [
            SELECT
                Id,
                NKS_Theme_Group__c,
                NKS_Theme_Group__r.CRM_Code__c,
                NKS_SessionId__c,
                NKS_Case__c,
                NKS_Phone_Number__c
            FROM NKS_Call_Log__c
            WHERE NKS_SessionId__c = :NKS_CallFlowController_Test.TEST_SESSION_ID
            LIMIT 1
        ];
        Conversation_Note__c conv = [
            SELECT Id, NKS_Access_Number__c
            FROM Conversation_note__c
            WHERE CRM_Case__c = :callLog.NKS_Case__c
            LIMIT 1
        ];
        Case casey = [
            SELECT Id, NKS_Theme_Group__c, NKS_Theme_Group__r.CRM_Code__c, NKS_Puzzel_Queue_Name__c
            FROM Case
            WHERE Id = :callLog.NKS_Case__c
            LIMIT 1
        ];

        Assert.isNotNull(callLog.NKS_Theme_Group__c);
        Assert.areEqual('ARBD', callLog.NKS_Theme_Group__r.CRM_Code__c);

        Assert.isNotNull(casey.NKS_Theme_Group__c);
        Assert.areEqual('ARBD', casey.NKS_Theme_Group__r.CRM_Code__c);

        Assert.areEqual(NKS_CallFlowController_Test.TEST_ACCESSNUMBER, callLog.NKS_Phone_Number__c);
        Assert.areEqual(NKS_CallFlowController_Test.TEST_ACCESSNUMBER, conv.NKS_Access_Number__c);

        Assert.areEqual(NKS_CallFlowController_Test.TEST_QUEUE, casey.NKS_Puzzel_Queue_Name__c);
    }

    @IsTest
    static void NKS_CallLogBatch_dontUpdateThemeIfSet() {
        NKS_Call_Log__c oldCallLog = [
            SELECT Id, NKS_Case__c
            FROM NKS_Call_Log__c
            WHERE NKS_SessionId__c = :NKS_CallFlowController_Test.TEST_SESSION_ID
            LIMIT 1
        ];

        Case oldCasey = [
            SELECT Id
            FROM Case
            WHERE Id = :oldCallLog.NKS_Case__c
            LIMIT 1
        ];

        Common_Code__c cCode = new Common_Code__c(
            CRM_Code__c = 'FMLI',
            CRM_Code_Set__c = 'Temagrupper',
            Name = 'Familie'
        );
        insert cCode;

        oldCasey.NKS_Theme_Group__c = cCode.Id;

        update oldCasey;

        NKS_CallLogBatch batch = new NKS_CallLogBatch();

        Test.startTest();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();
        NKS_Call_Log__c callLog = [
            SELECT
                Id,
                NKS_Theme_Group__c,
                NKS_Theme_Group__r.CRM_Code__c,
                NKS_SessionId__c,
                NKS_Case__c,
                NKS_Phone_Number__c
            FROM NKS_Call_Log__c
            WHERE NKS_SessionId__c = :NKS_CallFlowController_Test.TEST_SESSION_ID
            LIMIT 1
        ];
        Conversation_Note__c conv = [
            SELECT Id, NKS_Access_Number__c
            FROM Conversation_note__c
            WHERE CRM_Case__c = :callLog.NKS_Case__c
            LIMIT 1
        ];
        Case casey = [
            SELECT Id, NKS_Theme_Group__c, NKS_Theme_Group__r.CRM_Code__c, NKS_Puzzel_Queue_Name__c
            FROM Case
            WHERE Id = :callLog.NKS_Case__c
            LIMIT 1
        ];

        Assert.isNotNull(callLog.NKS_Theme_Group__c);
        Assert.areEqual('ARBD', callLog.NKS_Theme_Group__r.CRM_Code__c);

        Assert.isNotNull(casey.NKS_Theme_Group__c);
        Assert.areEqual('FMLI', casey.NKS_Theme_Group__r.CRM_Code__c);

        Assert.areEqual(NKS_CallFlowController_Test.TEST_ACCESSNUMBER, callLog.NKS_Phone_Number__c);
        Assert.areEqual(NKS_CallFlowController_Test.TEST_ACCESSNUMBER, conv.NKS_Access_Number__c);

        Assert.areEqual(NKS_CallFlowController_Test.TEST_QUEUE, casey.NKS_Puzzel_Queue_Name__c);
    }

    @IsTest
    static void NKS_CallLogBatch_checkLogCount() {
        NKS_CallLogBatch batch = new NKS_CallLogBatch();

        Test.startTest();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();
        List<Application_Log__c> logs = [SELECT Id FROM Application_Log__c WHERE Category__c = 'NKS_CallLogBatch'];

        Assert.areEqual(3, logs.size());
    }

    @IsTest
    static void NKS_CallLogBatch_deleteSosial() {
        String testSessionId = 'Sosial_Test';
        String testQueueName = 'Sosiale Tjenester';
        String testAccessNumber = '12345678';

        NKS_Call_log__c callLog = new NKS_Call_Log__c();
        Case casey = new Case();
        Conversation_note__c cNote = new Conversation_Note__c();

        casey.NKS_Puzzel_Queue_Name__c = testQueueName;

        insert casey;

        callLog.NKS_Case__c = casey.Id;
        callLog.NKS_SessionId__c = testSessionId;
        cNote.CRM_Case__c = casey.Id;
        cNote.NKS_Access_Number__c = testAccessNumber;

        insert callLog;
        insert cNote;

        Id callLogId = callLog.Id;
        Id cNoteId = cNote.Id;

        List<Object> originalList = (List<Object>) JSON.deserializeUntyped(
            NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG
        );
        originalList.add(
            (Object) JSON.deserializeUntyped(
                '{"puzzel__SessionId__c":"' +
                    testSessionId +
                    '", "puzzel__Queue__c": "' +
                    testQueueName +
                    '", "puzzel__AccessNumber__c": "' +
                    testAccessNumber +
                    '"}'
            )
        );
        NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG = JSON.serialize(originalList);
        NKS_CallLogBatch batch = new NKS_CallLogBatch();

        Test.startTest();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();
        List<NKS_Call_log__c> callLogResult = [SELECT Id FROM NKS_Call_Log__c WHERE Id = :callLogId];
        Conversation_Note__c cNoteResult = [
            SELECT Id, NKS_Access_Number__c
            FROM Conversation_note__c
            WHERE Id = :cNoteId
            LIMIT 1
        ];

        Assert.areEqual(0, callLogResult.size());
        Assert.isNull(cNoteResult.NKS_Access_Number__c);
    }
}
