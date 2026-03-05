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
            records.add(new ThreadTimelineRecord(obj));
        }

        String noteQuery =
            'SELECT Id, Name, CreatedDate, CRM_Date_Time_Registered__c, CRM_Conversation_Note__c, CRM_Created_By_Ident__c, NKS_Timeline_Name__c, CRM_Journal_Status_Formula_Icons__c, CRM_Theme_Group_Name__c ' +
            'FROM Conversation_Note__c ' +
            'WHERE CRM_Account__c = :recordId ' +
            'ORDER BY CRM_Date_Time_Registered__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(noteQuery)) {
            records.add(new ConvNoteTimelineRecord(obj));
        }

        String callLogQuery =
            'SELECT Id, Name, CreatedDate, NKS_Call_Time__c, NKS_Timeline_Name__c, NKS_Advisor_Ident__c, NKS_Timeline_Phone__c ' +
            'FROM NKS_Call_Log__c ' +
            'WHERE NKS_Account__c = :recordId ' +
            'ORDER BY NKS_Call_Time__c DESC NULLS LAST ' +
            'LIMIT :effectiveLimit';

        for (SObject obj : Database.query(callLogQuery)) {
            records.add(new CallLogTimelineRecord(obj));
        }

        records.sort();

        /* --- Chronological gap prevention ---

        Each record type is queried from different tables and the same LIMIT. This means
        they can cover different date ranges. For example, with limit=10:
        - Threads may all fall in March 2026
        - Conversation notes may all fall in January 2026
    
        If we show both as-is, the user will see March and January. On the next load (limit=20),
        threads from February 2026 would appear, giving the false impression that there were no threads/conv notes in February on the first load.
    
        To prevent this, we set a "cutoff date" and hide everything older than it.
        The cutoff is set to the oldest record date among all record types that are not yet exhausted.
        
        A type is considered non-exhausted when it returns exactly `effectiveLimit` records,
        meaning there are likely more older records waiting behind the query boundary.
        Using the newest of those oldest dates ensures we only display the part of the timeline
        that is complete across all non-exhausted types. Records behind the cutoff are revealed
        on subsequent loads as the limit grows and types become exhausted.
    
        Example with limit=10, 20 threads total (10 in March, 10 in February), 10 notes total (all in January):
        Load 1 (limit=10):  
            threads fetch 10 -> March only, threadOldest=March 1, non-exhausted.
            notes fetch 10   -> January only, noteOldest=Jan 1, non-exhausted.
            cutoff=max(March 1, Jan 1)=March 1 -> January notes hidden.
            User sees: March threads only.
        Load 2 (limit=20):  
            threads fetch 20 -> March+February, threadOldest=Feb 1, non-exhausted.
            notes fetch 10   -> January only (still all 10), noteOldest=Jan 1, exhausted (10 < 20).
            cutoff=Feb 1 (only threads non-exhausted) -> January notes still hidden.
            User sees: March+February threads.
        Load 3 (limit=30):  
            threads fetch 20 -> exhausted (20 < 30).
            notes fetch 10   -> exhausted (10 < 30).
            No non-exhausted types -> cutoffDate=null -> no filtering.
            User sees: March+February threads + January notes.
        Result: records always appear in strict chronological order, no months pop in out of sequence.
        */

        Integer threadCount = 0;
        Integer noteCount = 0;
        Integer callLogCount = 0;
        Datetime threadOldest = null;
        Datetime noteOldest = null;
        Datetime callLogOldest = null;

        // Count records per type and track each type's oldest (earliest) date.
        for (TimelineRecord rec : records) {
            if (rec.sObjectType == 'Thread__c') {
                threadCount++;
                if (threadOldest == null || rec.dateValue < threadOldest) {
                    threadOldest = rec.dateValue;
                }
            } else if (rec.sObjectType == 'Conversation_Note__c') {
                noteCount++;
                if (noteOldest == null || rec.dateValue < noteOldest) {
                    noteOldest = rec.dateValue;
                }
            } else if (rec.sObjectType == 'NKS_Call_Log__c') {
                callLogCount++;
                if (callLogOldest == null || rec.dateValue < callLogOldest) {
                    callLogOldest = rec.dateValue;
                }
            }
        }

        // For each non-exhausted type (count == effectiveLimit), its oldest date is a potential
        // gap boundary. The cutoff is the newest of those dates, since that is the point at which
        // all non-exhausted types have potential records for.
        Datetime cutoffDate = null;
        List<Integer> counts = new List<Integer>{ threadCount, noteCount, callLogCount };
        List<Datetime> oldestDates = new List<Datetime>{ threadOldest, noteOldest, callLogOldest };
        for (Integer i = 0; i < counts.size(); i++) {
            if (counts[i] == effectiveLimit && oldestDates[i] != null) {
                if (cutoffDate == null || oldestDates[i] > cutoffDate) {
                    cutoffDate = oldestDates[i];
                }
            }
        }

        // Remove any records older than the cutoff. If all types are exhausted, cutoffDate remains
        // null and every record is shown.
        if (cutoffDate != null) {
            List<TimelineRecord> withinWindow = new List<TimelineRecord>();
            for (TimelineRecord rec : records) {
                if (rec.dateValue >= cutoffDate) {
                    withinWindow.add(rec);
                }
            }
            records = withinWindow;
        }

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

    private class ThreadTimelineRecord extends TimelineRecord {
        public ThreadTimelineRecord(SObject obj) {
            super();
            this.recordId = obj.Id;
            this.sObjectType = 'Thread__c';
            this.sObjectLabel = 'Thread';
            Datetime latestMessageDate = (Datetime) obj.get('CRM_Latest_Message_Datetime__c');
            this.headers.add(new Header((String) obj.get('STO_Timeline_Name__c'), true));
            this.headers.add(new Header((String) obj.get('CRM_Timeline_Status__c'), true));
            this.headers.add(new Header(latestMessageDate, false));
            this.headers.add(new Header((String) obj.get('CRM_Journal_Status_Formula_Icons__c'), true));
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
            this.headers.add(new Header((String) obj.get('NKS_Timeline_Name__c'), true));
            this.headers.add(new Header(registeredDate, false));
            this.headers.add(new Header((String) obj.get('CRM_Journal_Status_Formula_Icons__c'), true));
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
            this.headers.add(new Header((String) obj.get('NKS_Advisor_Ident__c'), true));
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
