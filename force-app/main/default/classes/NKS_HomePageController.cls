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
        Set<String> userskills = new Set<String>();
        String userId = UserInfo.getUserID();
        if (filterbyskills) {
            userskills = getUserSkills(userId);
        }

        String query = 'SELECT LastModifiedDate, CreatedDate, ' + title;
        if (content != null) {
            query += ' , ' + content;
        }

        if (filterbyskills && objectName == 'NKS_Announcement__c') {
            query += ' , Skills__c ';
        }
        query += ' FROM ' + objectName + ' WHERE ' + filter;

        if (filterbyskills && objectName == 'NKS_Announcement__c' && userskills.size() > 0) {
            String skillstring = '';
            for (String u : userskills) {
                skillstring += '\'' + u.replaceAll('NKS_Skill_', '') + '\',';
            }
            query += ' AND (Skills__c = \'\' OR Skills__c INCLUDES (' + skillstring.removeEnd(',') + '))';
        }

        if (filterbyskills && objectName == 'Knowledge__kav' && userskills.size() > 0) {
            String skillstring = '';
            for (String u : userskills) {
                skillstring += u.replaceAll('NKS_Skill_', '') + '__c ,';
            }
            query += ' WITH DATA CATEGORY Tema__c ABOVE_OR_BELOW (' + skillstring.removeEnd(',') + ')';
        }

        if (orderby != null)
            query += ' ORDER BY ' + orderby;

        if (limitNumber != null)
            query += ' LIMIT ' + limitNumber;

        System.debug('QUERY: ' + query);
        List<SObject> listtoreturn = Database.query(query);
        records = createRecords(listtoreturn, objectName, title, content, datefield, showimage);
        System.debug(records.size());
        return records;
    }

    public class Record {
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public String objectName;
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
            record.objectName = objectName;
            record.name = r.get(title).toString();
            record.modifiedDate = Datetime.valueOf(r.get(datefield));
            if (showimage)
                record.imageurl = getImageUrl(r.Id);
            if (content != null) {
                record.content = r.get(content).toString().replaceAll('\\<.*?\\>', '');
                if (record.content.length() > 600) {
                    record.summary = record.content.mid(0, 600) + '...';
                } else
                    record.summary = record.content;
            }
            records.add(record);
        }
        return records;
    }

    private static String getImageUrl(Id recordId) {
        String contentversionid = [
            SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.ContentModifiedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.ContentModifiedDate DESC
            LIMIT 1
        ]
        ?.ContentDocument.LatestPublishedVersionId;
        return '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' + contentversionid;
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
            skills.add(g.DeveloperName);
        }
        return skills;
    }

    @AuraEnabled
    public static NKS_Announcement__c getCampaign() {
        NKS_Announcement__c campaign = [
            SELECT Id, Name, Image_Alt__c, NKS_ImageURL__c, From_Date__c, To_Date__c
            FROM NKS_Announcement__c
            WHERE NKS_Type__c = 'Kampanje'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        campaign.NKS_ImageURL__c = getImageUrl(campaign.Id);
        return campaign;
    }

    @AuraEnabled
    public static List<ReadyResponse__c> getReadyResponse() {
        List<ReadyResponse__c> records = [
            SELECT Id, Name, URL__c
            FROM ReadyResponse__c
            ORDER BY CreatedDate DESC
            LIMIT 3
        ];
        return records;
    }
}
