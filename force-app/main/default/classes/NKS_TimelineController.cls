public with sharing class NKS_TimelineController {
    @AuraEnabled(cacheable=true)
    public static List<TimelineGroup> getRecords(String recordId, Integer recordLimit) {
        if (String.isBlank(recordId)) {
            return new List<TimelineGroup>();
        }

        List<TimelineRecord> records = new List<TimelineRecord>();
        Integer effectiveLimit = recordLimit != null && recordLimit > 0 ? recordLimit : 50;

        String threadQuery =
            'SELECT Id, Name, CreatedDate, CRM_Latest_Message_Datetime__c, CRM_Journal_Status_Formula__c, CRM_Thread_Type__c, ' +
            'CRM_Conversation_Summary__c, CRM_Timeline_Icon__c, STO_Timeline_Name__c, CRM_Timeline_Status__c, CRM_Journal_Status_Formula_Icons__c, CRM_Theme_Group_Name__c ' +
            'FROM Thread__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Latest_Message_Datetime__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(threadQuery)) {
            TimelineRecord rec = new TimelineRecord();
            rec.recordId = obj.Id;
            rec.sObjectType = 'Thread__c';
            rec.sObjectLabel = 'Thread';

            // Build headers from STO_Timeline_Name__c, CRM_Timeline_Status__c, CRM_Latest_Message_Datetime__c, CRM_Journal_Status_Formula_Icons__c
            rec.headers = new List<Header>();
            rec.headers.add(new Header((String) obj.get('STO_Timeline_Name__c'), true));
            rec.headers.add(new Header((String) obj.get('CRM_Timeline_Status__c'), true));
            Datetime latestMessageDate = (Datetime) obj.get('CRM_Latest_Message_Datetime__c');
            rec.headers.add(new Header(latestMessageDate, false));
            rec.headers.add(new Header((String) obj.get('CRM_Journal_Status_Formula_Icons__c'), true));

            rec.dateValue = latestMessageDate != null ? latestMessageDate : (Datetime) obj.get('CreatedDate');
            String iconValue = (String) obj.get('CRM_Timeline_Icon__c');
            rec.icon = String.isNotBlank(iconValue) ? iconValue : 'standard:messaging_user';
            rec.color = '7D7D7D';
            rec.subtitleOverride = (String) obj.get('CRM_Conversation_Summary__c');
            rec.customComponent = 'ThreadExpandedTimeline';
            rec.clampLines = 2;
            rec.themeGroupName = (String) obj.get('CRM_Theme_Group_Name__c'); // For filtering
            records.add(rec);
        }

        String noteQuery =
            'SELECT Id, Name, CreatedDate, CRM_Date_Time_Registered__c, CRM_Conversation_Note__c, CRM_Created_By_Ident__c, NKS_Timeline_Name__c, CRM_Journal_Status_Formula_Icons__c, CRM_Theme_Group_Name__c ' +
            'FROM Conversation_Note__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Date_Time_Registered__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(noteQuery)) {
            TimelineRecord rec = new TimelineRecord();
            rec.recordId = obj.Id;
            rec.sObjectType = 'Conversation_Note__c';
            rec.sObjectLabel = 'Conversation Note';

            // Build headers from NKS_Timeline_Name__c, CRM_Date_Time_Registered__c, CRM_Journal_Status_Formula_Icons__c
            rec.headers = new List<Header>();
            rec.headers.add(new Header((String) obj.get('NKS_Timeline_Name__c'), true));
            Datetime registeredDate = (Datetime) obj.get('CRM_Date_Time_Registered__c');
            rec.headers.add(new Header(registeredDate, false));
            rec.headers.add(new Header((String) obj.get('CRM_Journal_Status_Formula_Icons__c'), true));

            rec.dateValue = registeredDate != null ? registeredDate : (Datetime) obj.get('CreatedDate');
            rec.icon = 'standard:voice_call';
            rec.color = '7D7D7D';
            rec.subtitleOverride = (String) obj.get('CRM_Conversation_Note__c');
            rec.customComponent = 'ConvNoteExpandedTimeline';
            rec.clampLines = 1;
            rec.themeGroupName = (String) obj.get('CRM_Theme_Group_Name__c'); // For filtering
            records.add(rec);
        }

        String callLogQuery =
            'SELECT Id, Name, CreatedDate, NKS_Call_Time__c, NKS_Timeline_Name__c, NKS_Advisor_Ident__c, NKS_Timeline_Phone__c ' +
            'FROM NKS_Call_Log__c ' +
            'WHERE NKS_Account__c = :recordId ' +
            'ORDER BY NKS_Call_Time__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(callLogQuery)) {
            TimelineRecord rec = new TimelineRecord();
            rec.recordId = obj.Id;
            rec.sObjectType = 'NKS_Call_Log__c';
            rec.sObjectLabel = 'Call Log';

            // Build headers from NKS_Timeline_Name__c, NKS_Call_Time__c, NKS_Advisor_Ident__c, NKS_Timeline_Phone__c
            rec.headers = new List<Header>();
            rec.headers.add(new Header((String) obj.get('NKS_Timeline_Name__c'), true));
            Datetime callTime = (Datetime) obj.get('NKS_Call_Time__c');
            rec.headers.add(new Header(callTime, false));
            rec.headers.add(new Header((String) obj.get('NKS_Advisor_Ident__c'), true));
            rec.headers.add(new Header((String) obj.get('NKS_Timeline_Phone__c'), true));

            rec.dateValue = callTime != null ? callTime : (Datetime) obj.get('CreatedDate');
            rec.icon = 'standard:voice_call';
            rec.color = '7D7D7D';
            rec.subtitleOverride = null;
            rec.customComponent = null;
            rec.clampLines = 0;
            rec.slickBackgroundColor = 'EFEFEF';
            rec.slickIconColor = 'e3e3e3';
            records.add(rec);
        }

        records.sort();

        return groupRecordsByMonth(records);
    }

    private static List<TimelineGroup> groupRecordsByMonth(List<TimelineRecord> records) {
        Map<String, List<TimelineRecord>> groupMap = new Map<String, List<TimelineRecord>>();

        for (TimelineRecord rec : records) {
            String monthKey = rec.dateValue.format('MMMM yyyy');

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

    public class TimelineRecord implements Comparable {
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
