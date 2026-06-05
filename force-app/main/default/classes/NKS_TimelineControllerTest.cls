@isTest
private class NKS_TimelineControllerTest {
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Thread__c thread1 = new Thread__c(
            CRM_Account__c = acc.Id,
            CRM_Latest_Message_Datetime__c = Datetime.now().addDays(-1),
            CRM_Conversation_Summary__c = 'Summary 1'
        );
        Thread__c thread2 = new Thread__c(
            CRM_Account__c = acc.Id,
            CRM_Latest_Message_Datetime__c = Datetime.now().addMonths(-2),
            CRM_Conversation_Summary__c = 'Summary 2'
        );
        insert new List<Thread__c>{ thread1, thread2 };

        Conversation_Note__c note1 = new Conversation_Note__c(
            CRM_Account__c = acc.Id,
            CRM_Date_Time_Registered__c = Datetime.now().addDays(-3),
            CRM_Conversation_Note__c = 'Note content 1'
        );
        Conversation_Note__c note2 = new Conversation_Note__c(
            CRM_Account__c = acc.Id,
            CRM_Date_Time_Registered__c = Datetime.now().addMonths(-3),
            CRM_Conversation_Note__c = 'Note content 2'
        );
        insert new List<Conversation_Note__c>{ note1, note2 };

        Case case1 = new Case(AccountId = acc.Id, Subject = 'Test Case 1');
        Case case2 = new Case(AccountId = acc.Id, Subject = 'Test Case 2');
        insert new List<Case>{ case1, case2 };

        NKS_Call_Log__c log1 = new NKS_Call_Log__c(
            NKS_Case__c = case1.Id,
            NKS_Call_Time__c = Datetime.now().addDays(-5)
        );
        NKS_Call_Log__c log2 = new NKS_Call_Log__c(
            NKS_Case__c = case2.Id,
            NKS_Call_Time__c = Datetime.now().addMonths(-4)
        );
        insert new List<NKS_Call_Log__c>{ log1, log2 };
    }

    @isTest
    static void testGetRecordsBlankId() {
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords('', 10);
        Assert.areEqual(0, result.size(), 'Expected empty list for blank recordId');
    }

    @isTest
    static void testGetRecordsNullId() {
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(null, 10);
        Assert.areEqual(0, result.size(), 'Expected empty list for null recordId');
    }

    @isTest
    static void testGetRecordsDefaultLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, null);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null with null limit');
        Assert.isTrue(result.size() > 0, 'Should return results using default limit');
    }

    @isTest
    static void testGetRecordsZeroLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, 0);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null with zero limit (uses default)');
        Assert.isTrue(result.size() > 0, 'Should return results using default limit when zero passed');
    }

    @isTest
    static void testGetRecordsReturnsGroupedResults() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, 50);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Expected at least one timeline group');

        Integer totalModels = 0;
        for (NKS_TimelineController.TimelineGroup grp : result) {
            Assert.isNotNull(grp.id, 'Group id should not be null');
            Assert.isNotNull(grp.name, 'Group name should not be null');
            Assert.isNotNull(grp.models, 'Group models should not be null');
            Assert.areEqual(grp.models.size(), grp.size, 'Group size should match models count');
            totalModels += grp.size;
        }
        Assert.areEqual(
            6,
            totalModels,
            'Expected 6 total records across all groups (2 threads + 2 notes + 2 call logs)'
        );
    }

    @isTest
    static void testGetRecordsModelsHaveCorrectStructure() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<NKS_TimelineController.TimelineGroup> result = NKS_TimelineController.getRecords(acc.Id, 50);
        Test.stopTest();

        for (NKS_TimelineController.TimelineGroup grp : result) {
            for (NKS_TimelineController.TimelineModel model : grp.models) {
                Assert.isNotNull(model.record, 'Model record should not be null');
                Assert.isNotNull(model.theme, 'Model theme should not be null');
                Assert.isNotNull(model.filter, 'Model filter should not be null');
                Assert.isNotNull(model.record.recordId, 'RecordData recordId should not be null');
                Assert.isNotNull(model.record.dateValueDb, 'RecordData dateValueDb should not be null');
                Assert.isNotNull(model.theme.icon, 'Theme icon should not be null');
            }
        }
    }

    @isTest
    static void testTimelineRecordCompareTo() {
        NKS_TimelineController.TimelineRecord newer = new NKS_TimelineController.TimelineRecord();
        newer.dateValue = Datetime.now();

        NKS_TimelineController.TimelineRecord older = new NKS_TimelineController.TimelineRecord();
        older.dateValue = Datetime.now().addDays(-1);

        Assert.areEqual(-1, newer.compareTo(older), 'Newer record should sort first');
        Assert.areEqual(1, older.compareTo(newer), 'Older record should sort last');
        Assert.areEqual(0, newer.compareTo(newer), 'Same record should be equal');
    }

    @isTest
    static void testFilterDataThread() {
        NKS_TimelineController.FilterData fd = new NKS_TimelineController.FilterData('Thread__c', 'SomeThemeGroup');
        Assert.areEqual('SomeThemeGroup', fd.picklistValue1);
        Assert.isFalse(fd.shown);
    }

    @isTest
    static void testTheme() {
        NKS_TimelineController.Theme t = new NKS_TimelineController.Theme('standard:voice_call', '7D7D7D');
        Assert.areEqual('standard:voice_call', t.icon);
        Assert.areEqual('7D7D7D', t.sldsTimelineItemColor);
    }

    @isTest
    static void testTimelineModelAndRecordData() {
        NKS_TimelineController.TimelineRecord rec = new NKS_TimelineController.TimelineRecord();
        rec.recordId = UserInfo.getUserId();
        rec.dateValue = Datetime.now();
        rec.sObjectType = 'Thread__c';
        rec.sObjectLabel = 'Thread';
        rec.icon = 'standard:messaging_user';
        rec.color = '7D7D7D';
        rec.subtitleOverride = 'Summary';
        rec.customComponent = 'ThreadExpandedTimeline';
        rec.clampLines = 2;
        rec.themeGroupName = 'Group1';
        rec.slickBackgroundColor = null;
        rec.slickIconColor = null;
        rec.headers = new List<NKS_TimelineController.Header>{
            new NKS_TimelineController.Header('HeaderA', true),
            new NKS_TimelineController.Header(Datetime.now(), false)
        };

        NKS_TimelineController.TimelineModel model = new NKS_TimelineController.TimelineModel(rec);

        Assert.isNotNull(model.record);
        Assert.isNotNull(model.theme);
        Assert.isNotNull(model.filter);
        Assert.areEqual('standard:messaging_user', model.theme.icon);
        Assert.areEqual('7D7D7D', model.theme.sldsTimelineItemColor);
        Assert.areEqual('Group1', model.filter.picklistValue1);
        Assert.isNull(model.filter.picklistValue2);
        Assert.isNull(model.filter.checkBoxValue);
        Assert.isFalse(model.filter.shown);
        Assert.areEqual('Summary', model.record.subtitleOverride);
        Assert.areEqual('ThreadExpandedTimeline', model.record.customComponent);
        Assert.areEqual(2, model.record.clampLines);
        Assert.isFalse(model.record.isDate);
        Assert.isNull(model.record.slickBackgroundColor);
        Assert.isNull(model.record.slickIconColor);
        Assert.areEqual(2, model.record.headers.size());
    }
}
