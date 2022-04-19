public with sharing class NKS_HomePageController {
    @AuraEnabled
    public static string getField(String type) {
        List<NKS_Announcement__c> announcements = [
            SELECT NKS_Information__c
            FROM NKS_Announcement__c
            WHERE NKS_Type__c = :type
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        if (announcements.size() > 0) {
            NKS_Announcement__c announcement = announcements[0];
            String information = announcement.NKS_Information__c.replace('<img', '<img style="max-height: 100px"');
            return information;
        } else {
            System.debug('There was problem to fetch Announcement!');
            return null;
        }
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

        if (
            objectName == 'NKS_Announcement__c' &&
            Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByDeveloperName().get('News') != null
        ) {
            query += ' , NKS_News_Pin__c, NKS_News_Publish_Date__c';
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

        if (orderby != null) {
            query += ' ORDER BY ' + orderby;
        }

        if (limitNumber != null) {
            query += ' LIMIT ' + limitNumber;
        }

        System.debug('QUERY: ' + query);
        List<SObject> listtoreturn = Database.query(query);

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
        @AuraEnabled
        public Boolean pin;
        @AuraEnabled
        public Datetime publishDate;
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
            if (showimage) {
                record.imageurl = getImageUrl(r.Id);
            }

            if (content != null) {
                record.content = r.get(content).toString().replaceAll('\\<.*?\\>', '');
                if (record.content.length() > 600) {
                    record.summary = record.content.mid(0, 600) + '...';
                } else {
                    record.summary = record.content;
                }
            }

            if (
                objectName == 'NKS_Announcement__c' &&
                Schema.SObjectType.NKS_Announcement__c.getRecordTypeInfosByDeveloperName().get('News') != null
            ) {
                NKS_Announcement__c news = (NKS_Announcement__c) r;
                record.pin = news.NKS_News_Pin__c;
                record.publishDate = Datetime.valueOf(news.NKS_News_Publish_Date__c);
            } else {
                record.pin = false;
                record.publishDate = null;
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
        return contentversionid != null
            ? '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' + contentversionid
            : '';
    }

    public static Set<String> getUserSkills(Id userId) {
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
        List<NKS_Announcement__c> campaigns = [
            SELECT
                Id,
                Name,
                NKS_Campaign_Image_Alt__c,
                NKS_ImageURL__c,
                NKS_Campaign_From_Date__c,
                NKS_Campaign_To_Date__c
            FROM NKS_Announcement__c
            WHERE NKS_Type__c = 'Kampanje' AND NKS_Campaign_To_Date__c >= TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (campaigns.size() > 0) {
            NKS_Announcement__c campaign = campaigns[0];
            campaign.NKS_ImageURL__c = getImageUrl(campaign.Id);
            return campaign;
        } else {
            System.debug('The list in empty!');
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static NKS_Announcement__c getNews(Id recordId) {
        NKS_Announcement__c news = [
            SELECT
                Id,
                Name,
                NKS_News_Author__c,
                NKS_News_Publish_Date__c,
                LastModifiedDate,
                NKS_Information__c,
                NKS_ImageURL__c
            FROM NKS_Announcement__c
            WHERE Id = :recordId
        ];
        if (news != null) {
            news.NKS_ImageURL__c = getImageUrl(news.Id);
            return news;
        } else {
            System.debug('Record was not found!');
            return null;
        }
    }
}
