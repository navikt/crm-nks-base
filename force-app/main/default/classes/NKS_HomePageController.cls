public with sharing class NKS_HomePageController {
    @AuraEnabled
    public static string getField(String type) {
        String information = [
            SELECT NKS_Information__c
            FROM NKS_Announcement__c
            WHERE NKS_Type__c = :type
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ]
        .NKS_Information__c;
        information = information.replace('<img', '<img style="max-height: 100px"');
        return information;
    }

    @AuraEnabled
    public static List<Record> getList(
        String title,
        String content,
        String objectName,
        String filter,
        String orderby,
        String limitNumber,
        String datefield,
        Boolean showimage,
        Boolean filterbyskills
    ) {
        List<Record> records = new List<Record>();
        String userId = UserInfo.getUserID();
        String query = 'SELECT LastModifiedDate, CreatedDate, ' + title;
        if (content != null)
            query += ' , ' + content;
        if (filterbyskills)
            query += ' , Skills__c ';
        query += ' FROM ' + objectName;
        query += ' WHERE ' + filter;
        if (orderby != null)
            query += ' ORDER BY ' + orderby;
        if (limitNumber != null)
            query += ' LIMIT ' + limitNumber + 10;

        List<SObject> listtoreturn = Database.query(query);

        if (filterbyskills)
            listtoreturn = filterBySkills(listtoreturn, objectName, userId, limitNumber);

        records = createRecords(listtoreturn, objectName, title, content, datefield, showimage);
        return records;
    }

    public class Record {
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String content;
        @AuraEnabled
        public String summary;
        @AuraEnabled
        public Datetime modifiedDate;
        @AuraEnabled
        public String imageurl;
    }

    private static List<Record> createRecords(
        List<sObject> listofrecords,
        String objectName,
        String title,
        String content,
        String datefield,
        Boolean showimage
    ) {
        List<Record> records = new List<Record>();
        for (sObject r : listofrecords) {
            Record record = new Record();
            record.recordId = r.Id;
            record.name = r.get(title).toString();
            record.modifiedDate = Datetime.valueOf(r.get(datefield));
            if (showimage)
                record.imageurl = getImageUrl(r.Id);
            if (content != null) {
                record.content = r.get(content).toString().replaceAll('\\<.*?\\>', '');
                if (record.content.length() > 200) {
                    record.summary = record.content.mid(0, 200) + '...';
                } else
                    record.summary = record.content;
            }
            records.add(record);
        }
        return records;
    }

    private static String getImageUrl(Id recordId) {
        String contentversionid = [
            SELECT
                Id,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.ContentModifiedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.ContentModifiedDate DESC
            LIMIT 1
        ]
        ?.ContentDocument.LatestPublishedVersionId;
        return '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' +
            contentversionid;
    }

    private static Set<String> getUserSkills(Id userId) {
        Set<String> skills = new Set<String>();
        for (Group g : [
            SELECT DeveloperName, Name, Type, Id
            FROM Group
            WHERE
                DeveloperName LIKE 'NKS_Skill_%'
                AND Group.Type = 'Regular'
                AND Id IN (SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId)
        ]) {
            skills.add(g.Name);
        }
        return skills;
    }

    private static List<SObject> filterBySkills(
        List<sObject> listofrecords,
        String objectName,
        Id userId,
        String limitNumber
    ) {
        List<sObject> listtoreturn = new List<SObject>();
        Set<String> userskills = getUserSkills(userId);
        for (sObject r : listofrecords) {
            if (r.get('Skills__c') != null) {
                Set<String> selections = new Set<String>(r.get('Skills__c').toString().split(';'));
                userskills.retainAll(selections);
                if (userskills.size() > 0) {
                    listtoreturn.add(r);
                }
            } else
                listtoreturn.add(r);
            if (listtoreturn.size() == Integer.valueOf(limitNumber))
                return listtoreturn;
        }
        return listtoreturn;
    }
}
