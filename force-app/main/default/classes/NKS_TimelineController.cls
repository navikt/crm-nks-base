public with sharing class NKS_TimelineController {
    @AuraEnabled(cacheable=true)
    public static TimelinePage getRecords(String recordId, Integer recordLimit) {
        TimelinePage page = new TimelinePage();
        if (String.isBlank(recordId)) {
            return page;
        }

        List<TimelineRecord> records = new List<TimelineRecord>();
        Integer effectiveLimit = recordLimit != null && recordLimit > 0 ? recordLimit : 50;
        Integer queryLimit = effectiveLimit + 1;

        String threadQuery =
            'SELECT Id, Name, CreatedDate, CRM_Latest_Message_Datetime__c, CRM_Journal_Status_Formula__c, CRM_Thread_Type__c, ' +
            'CRM_Conversation_Summary__c, CRM_Timeline_Icon__c, STO_Timeline_Name__c, CRM_Timeline_Status__c, CRM_Journal_Status_Formula_Icons__c, CRM_Theme_Group_Name__c, CRM_Journal_Case_Reference__c ' +
            'FROM Thread__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Latest_Message_Datetime__c DESC NULLS LAST ' +
            'LIMIT :queryLimit';

        List<TimelineRecord> threadRecords = new List<TimelineRecord>();
        for (SObject obj : Database.query(threadQuery)) {
            threadRecords.add(new ThreadTimelineRecord(obj));
        }
        page.recordPages.add(new RecordPage('Thread__c', threadRecords, effectiveLimit));
        records.addAll(threadRecords);

        String noteQuery =
            'SELECT Id, Name, CreatedDate, CRM_Date_Time_Registered__c, CRM_Conversation_Note__c, CRM_Created_By_Ident__c, NKS_Timeline_Name__c, CRM_Journal_Status_Formula_Icons__c, CRM_Theme_Group_Name__c, CRM_Journal_Case_Reference__c ' +
            'FROM Conversation_Note__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Date_Time_Registered__c DESC NULLS LAST ' +
            'LIMIT :queryLimit';

        List<TimelineRecord> noteRecords = new List<TimelineRecord>();
        for (SObject obj : Database.query(noteQuery)) {
            noteRecords.add(new ConvNoteTimelineRecord(obj));
        }
        page.recordPages.add(new RecordPage('Conversation_Note__c', noteRecords, effectiveLimit));
        records.addAll(noteRecords);

        String callLogQuery =
            'SELECT Id, Name, CreatedDate, NKS_Call_Time__c, NKS_Timeline_Name__c, NKS_Advisor_Ident__c, NKS_Timeline_Phone__c ' +
            'FROM NKS_Call_Log__c ' +
            'WHERE NKS_Case__r.AccountId = :recordId ' +
            'AND NKS_Conversation_Note_Created__c  = false ' +
            'ORDER BY NKS_Call_Time__c DESC NULLS LAST ' +
            'LIMIT :queryLimit';

        List<TimelineRecord> callLogRecords = new List<TimelineRecord>();
        for (SObject obj : Database.query(callLogQuery)) {
            callLogRecords.add(new CallLogTimelineRecord(obj));
        }
        page.recordPages.add(new RecordPage('NKS_Call_Log__c', callLogRecords, effectiveLimit));
        records.addAll(callLogRecords);

        records.sort();
        page.groups = groupRecordsByMonth(records);
        return page;
    }

    public class TimelinePage {
        @AuraEnabled
        public List<TimelineGroup> groups = new List<TimelineGroup>();
        @AuraEnabled
        public List<RecordPage> recordPages = new List<RecordPage>();
    }

    public class RecordPage {
        @AuraEnabled
        public String sObjectType;
        @AuraEnabled
        public Boolean hasMore;
        @AuraEnabled
        public Datetime oldestDate;

        public RecordPage(String sObjectType, List<TimelineRecord> records, Integer recordLimit) {
            this.sObjectType = sObjectType;
            this.hasMore = records.size() > recordLimit;
            if (this.hasMore) {
                records.remove(recordLimit);
            }
            for (TimelineRecord rec : records) {
                if (this.oldestDate == null || rec.dateValue < this.oldestDate) {
                    this.oldestDate = rec.dateValue;
                }
            }
        }
    }

    private static final Map<Integer, String> NORWEGIAN_MONTHS = new Map<Integer, String>{
        1 => 'Januar',
        2 => 'Februar',
        3 => 'Mars',
        4 => 'April',
        5 => 'Mai',
        6 => 'Juni',
        7 => 'Juli',
        8 => 'August',
        9 => 'September',
        10 => 'Oktober',
        11 => 'November',
        12 => 'Desember'
    };

    private static List<TimelineGroup> groupRecordsByMonth(List<TimelineRecord> records) {
        Map<String, List<TimelineRecord>> groupMap = new Map<String, List<TimelineRecord>>();

        for (TimelineRecord rec : records) {
            Integer month = rec.dateValue.month();
            Integer year = rec.dateValue.year();
            String monthKey = NORWEGIAN_MONTHS.get(month) + ' ' + year;

            if (!groupMap.containsKey(monthKey)) {
                groupMap.put(monthKey, new List<TimelineRecord>());
            }
            groupMap.get(monthKey).add(rec);
        }

        // Convert map to list of TimelineGroup with wrapped models
        List<TimelineGroup> groups = new List<TimelineGroup>();
        for (String monthKey : groupMap.keySet()) {
            List<TimelineRecord> monthRecords = groupMap.get(monthKey);

            List<TimelineModel> wrappedModels = new List<TimelineModel>();
            for (TimelineRecord rec : monthRecords) {
                // Mark last header on each record for non-bold text on last header
                if (rec.headers != null && !rec.headers.isEmpty()) {
                    rec.headers[rec.headers.size() - 1].isLast = true;
                }
                wrappedModels.add(new TimelineModel(rec));
            }

            TimelineGroup timelineGroup = new TimelineGroup();
            timelineGroup.id = monthKey;
            timelineGroup.name = monthKey;
            timelineGroup.models = wrappedModels;
            timelineGroup.size = wrappedModels.size();
            groups.add(timelineGroup);
        }

        groups.sort();

        return groups;
    }

    public class TimelineGroup implements Comparable {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public List<TimelineModel> models;
        @AuraEnabled
        public Integer size;

        public TimelineGroup() {
            this.models = new List<TimelineModel>();
            this.size = 0;
        }

        // Newest -> oldest
        public Integer compareTo(Object other) {
            TimelineGroup otherGroup = (TimelineGroup) other;
            if (models == null || models.isEmpty() || otherGroup.models == null || otherGroup.models.isEmpty()) {
                return 0;
            }
            Datetime thisDate = models[0].record.dateValueDb;
            Datetime otherDate = otherGroup.models[0].record.dateValueDb;
            return thisDate > otherDate ? -1 : (thisDate < otherDate ? 1 : 0);
        }
    }

    public class TimelineModel {
        @AuraEnabled
        public RecordData record;
        @AuraEnabled
        public Theme theme;
        @AuraEnabled
        public FilterData filter;

        public TimelineModel(TimelineRecord rec) {
            this.record = new RecordData(rec);
            this.theme = new Theme(rec.icon, rec.color);
            this.filter = new FilterData(rec.sObjectType, rec.themeGroupName);
        }
    }

    public class RecordData {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public Datetime dateValueDb;
        @AuraEnabled
        public String sObjectKind;
        @AuraEnabled
        public String subtitleOverride;
        @AuraEnabled
        public String customComponent;
        @AuraEnabled
        public Integer clampLines;
        @AuraEnabled
        public Boolean isDate;
        @AuraEnabled
        public List<Header> headers;
        @AuraEnabled
        public String slickBackgroundColor;
        @AuraEnabled
        public String slickIconColor;

        public RecordData(TimelineRecord rec) {
            this.recordId = rec.recordId;
            this.dateValueDb = rec.dateValue;
            this.sObjectKind = rec.sObjectType;
            this.subtitleOverride = rec.subtitleOverride;
            this.customComponent = rec.customComponent;
            this.clampLines = rec.clampLines;
            this.isDate = false;
            this.headers = rec.headers;
            this.slickBackgroundColor = rec.slickBackgroundColor;
            this.slickIconColor = rec.slickIconColor;
        }
    }

    public class Theme {
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String sldsTimelineItemColor;

        public Theme(String icon, String color) {
            this.icon = icon;
            this.sldsTimelineItemColor = color;
        }
    }

    public class FilterData {
        @AuraEnabled
        public String picklistValue1;
        @AuraEnabled
        public String picklistValue2;
        @AuraEnabled
        public String checkBoxValue;
        @AuraEnabled
        public Boolean shown;

        public FilterData(String sObjectType, String themeGroupName) {
            // Set picklistValue1 based on theme group for Thread and ConvNote
            if (sObjectType == 'Thread__c' || sObjectType == 'Conversation_Note__c') {
                this.picklistValue1 = themeGroupName;
            }
            // Call logs hidden by default (shown=true is counter-intuitive but required by timelineFilter)
            this.shown = (sObjectType == 'NKS_Call_Log__c');
        }
    }

    private class ThreadTimelineRecord extends TimelineRecord {
        public ThreadTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'Thread__c';
            this.sObjectLabel = 'Thread';
            Datetime latestMessageDate = (Datetime) obj.get('CRM_Latest_Message_Datetime__c');
            String journalStatus = (String) obj.get('CRM_Journal_Status_Formula_Icons__c');
            String caseReference = (String) obj.get('CRM_Journal_Case_Reference__c');

            if (String.isNotBlank(caseReference)) {
                journalStatus += '\u00A0\u00A0\u00A0' + caseReference;
            }

            this.headers.add(new Header((String) obj.get('STO_Timeline_Name__c'), true));
            this.headers.add(new Header((String) obj.get('CRM_Timeline_Status__c'), true));
            this.headers.add(new Header(latestMessageDate, false));
            this.headers.add(new Header(journalStatus, true));
            this.dateValue = latestMessageDate != null ? latestMessageDate : (Datetime) obj.get('CreatedDate');
            String iconValue = (String) obj.get('CRM_Timeline_Icon__c');
            this.icon = String.isNotBlank(iconValue) ? iconValue : 'standard:messaging_user';
            this.color = '7D7D7D';
            this.subtitleOverride = (String) obj.get('CRM_Conversation_Summary__c');
            this.customComponent = 'ThreadExpandedTimeline';
            this.clampLines = 2;
            this.themeGroupName = (String) obj.get('CRM_Theme_Group_Name__c');
        }
    }

    private class ConvNoteTimelineRecord extends TimelineRecord {
        public ConvNoteTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'Conversation_Note__c';
            this.sObjectLabel = 'Conversation Note';
            Datetime registeredDate = (Datetime) obj.get('CRM_Date_Time_Registered__c');
            String journalStatus = (String) obj.get('CRM_Journal_Status_Formula_Icons__c');
            String caseReference = (String) obj.get('CRM_Journal_Case_Reference__c');

            if (String.isNotBlank(caseReference)) {
                journalStatus += '\u00A0\u00A0\u00A0' + caseReference;
            }

            this.headers.add(new Header((String) obj.get('NKS_Timeline_Name__c'), true));
            this.headers.add(new Header(registeredDate, false));
            this.headers.add(new Header(journalStatus, true));
            this.dateValue = registeredDate != null ? registeredDate : (Datetime) obj.get('CreatedDate');
            this.icon = 'standard:voice_call';
            this.color = '7D7D7D';
            this.subtitleOverride = (String) obj.get('CRM_Conversation_Note__c');
            this.customComponent = 'ConvNoteExpandedTimeline';
            this.clampLines = 1;
            this.themeGroupName = (String) obj.get('CRM_Theme_Group_Name__c');
        }
    }

    private class CallLogTimelineRecord extends TimelineRecord {
        public CallLogTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'NKS_Call_Log__c';
            this.sObjectLabel = 'Call Log';
            Datetime callTime = (Datetime) obj.get('NKS_Call_Time__c');
            this.headers.add(new Header((String) obj.get('NKS_Timeline_Name__c'), true));
            this.headers.add(new Header(callTime, false));
            String advisorIdent = (String) obj.get('NKS_Advisor_Ident__c');
            if (String.isNotBlank(advisorIdent)) {
                this.headers.add(new Header(advisorIdent, true));
            }
            this.headers.add(new Header((String) obj.get('NKS_Timeline_Phone__c'), true));
            this.dateValue = callTime != null ? callTime : (Datetime) obj.get('CreatedDate');
            this.icon = 'standard:voice_call';
            this.color = '7D7D7D';
            this.customComponent = null;
            this.clampLines = 0;
            this.slickBackgroundColor = 'EFEFEF';
            this.slickIconColor = 'e3e3e3';
        }
    }

    public virtual class TimelineRecord implements Comparable {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public Datetime dateValue;
        @AuraEnabled
        public String sObjectType;
        @AuraEnabled
        public String sObjectLabel;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public String subtitleOverride;
        @AuraEnabled
        public String customComponent;
        @AuraEnabled
        public Integer clampLines;
        @AuraEnabled
        public List<Header> headers;
        @AuraEnabled
        public String slickBackgroundColor;
        @AuraEnabled
        public String slickIconColor;
        @AuraEnabled
        public String themeGroupName; // For filter picklistValue1

        public TimelineRecord() {
            this.headers = new List<Header>();
        }

        // Newest -> oldest
        public Integer compareTo(Object other) {
            TimelineRecord otherRec = (TimelineRecord) other;
            if (dateValue == otherRec.dateValue) {
                return 0;
            }
            return dateValue > otherRec.dateValue ? -1 : 1;
        }
    }

    public class Header {
        @AuraEnabled
        public Object header;
        @AuraEnabled
        public Boolean isString;
        @AuraEnabled
        public Boolean isDatetime;
        @AuraEnabled
        public Boolean isDate;
        @AuraEnabled
        public Boolean isLast;

        public Header(Object headerValue, Boolean isStringType) {
            this.header = headerValue;
            this.isString = isStringType;
            this.isDatetime = !isStringType && headerValue instanceof Datetime;
            this.isDate = false;
            this.isLast = false;
        }
    }
}
