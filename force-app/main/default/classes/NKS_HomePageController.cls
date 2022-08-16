public with sharing class NKS_HomePageController {
    @AuraEnabled
    public static string getField(String type) {
        List<NKS_Announcement__c> announcements = new List<NKS_Announcement__c>();
        String res = null;
        try {
            announcements = [
                SELECT NKS_Information__c
                FROM NKS_Announcement__c
                WHERE RecordType.Name = :type
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];

            if (announcements.size() > 0) {
                NKS_Announcement__c announcement = announcements[0];
                String information = announcement.NKS_Information__c.replace('<img', '<img style="max-height: 100px"');
                res = information;
            }
        } catch (Exception ex) {
            System.debug('Problem getting Information-field for Announcement' + ex.getMessage());
        }
        return res;
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
        String skillStringAnnouncement = '';
        String skillStringKnowledge = '';

        if (filterBySkills == true) {
            for (String u : getUserSkills(userId)) {
                u = u.replaceAll('NKS_Skill_', '');
                skillStringAnnouncement += '\'' + u + '\',';
                skillStringKnowledge += u + '__c ,';
            }
        }

        fflib_QueryFactory qf = new fflib_QueryFactory(Schema.getGlobalDescribe().get(objectName));
        qf.selectFields(new Set<String>{ 'LastModifiedDate', 'CreatedDate', title });

        if (String.isNotBlank(limitNumber)) {
            qf.setLimit(Integer.valueOf(limitNumber));
        }

        if (String.isNotBlank(orderby)) {
            List<String> orderBys = orderby.split(' ');
            Integer i = 0;
            Integer n = 1;
            while (i < orderBys.size()) {
                fflib_QueryFactory.SortOrder so = fflib_QueryFactory.SortOrder.ASCENDING;
                String orderByField = orderBys[i];
                if (n < orderBys.size() && orderBys[n] == 'ASC' || orderBys[n] == 'DESC') {
                    if (orderBys[n] == 'DESC') {
                        so = fflib_QueryFactory.SortOrder.DESCENDING;
                    }
                    i++;
                    n++;
                }

                qf.addOrdering(orderByField, so);
                i++;
                n++;
            }
        }

        if (String.isNotBlank(content)) {
            qf.selectFields(content.split(','));
        }

        if (objectName == 'NKS_Announcement__c') {
            qf.selectFields(new Set<String>{ 'NKS_News_Pin__c', 'NKS_News_Publish_Date__c' });

            if (filterBySkills == true) {
                qf.selectField('skills__c');

                if (String.isNotBlank(skillStringAnnouncement)) {
                    filter += (String.isBlank(filter) ? '' : ' AND ');
                    filter +=
                        '(Skills__c = \'\' OR Skills__c INCLUDES (' +
                        skillStringAnnouncement.removeEnd(',') +
                        '))';
                }
            }
        }

        if (objectName == 'Knowledge__kav' && filterbyskills == true && String.isNotBlank(skillStringKnowledge)) {
            filter +=
                (String.isBlank(filter) ? '' : ' AND ') +
                'WITH DATA CATEGORY Tema__c ABOVE_OR_BELOW (' +
                skillStringKnowledge.removeEnd(',') +
                ')';
        }

        qf.setCondition(filter);

        String query = qf.toSOQL();

        if (objectName == 'Case') {
            query = query.replace('SELECT', 'SELECT toLabel(Status),');
        }

        System.debug('QUERY: ' + query);

        List<SObject> listToReturn = Database.query(query);

        records = createRecords(listToReturn, objectName, title, content, dateField, showImage);
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
        @AuraEnabled
        public String status;
    }

    private static List<Record> createRecords(
        List<sObject> listofrecords,
        String objectName,
        String title,
        String content,
        String dateField,
        Boolean showImage
    ) {
        List<Record> records = new List<Record>();
        Map<Id, String> urlMap;

        if (showImage == true) {
            List<Id> recordIds = new List<Id>();
            for (sObject r : listofrecords) {
                recordIds.add(r.Id);
            }
            urlMap = getImageUrls(recordIds);
        } else {
            urlMap = new Map<Id, String>();
        }

        for (sObject r : listofrecords) {
            Record record = new Record();
            record.recordId = r.Id;
            record.name = r.get(title).toString();
            record.modifiedDate = Datetime.valueOf(r.get(datefield));
            if (showImage == true) {
                record.imageurl = urlMap.get(r.Id);
            }

            if (content != null) {
                record.content = r.get(content).toString().replaceAll('\\<.*?\\>', '');
                if (record.content.length() > 600) {
                    record.summary = record.content.mid(0, 600) + '...';
                } else {
                    record.summary = record.content;
                }
            }
            if (objectName == 'NKS_Announcement__c') {
                NKS_Announcement__c news = (NKS_Announcement__c) r;
                record.pin = news.NKS_News_Pin__c;
                record.publishDate = Datetime.valueOf(news.NKS_News_Publish_Date__c);
            } else {
                record.pin = false;
                record.publishDate = null;
            }

            if (objectName == 'Case') {
                Case enCase = (Case) r;
                record.status = enCase.Status;
            } else {
                record.status = '';
            }
            records.add(record);
        }
        return records;
    }

    public static Map<Id, String> getImageUrls(List<Id> recordIds) {
        Map<Id, String> urlMap = new Map<Id, String>();
        try {
            for (ContentDocumentLink cdl : [
                SELECT
                    Id,
                    ContentDocumentId,
                    ContentDocument.LatestPublishedVersionId,
                    ContentDocument.ContentModifiedDate,
                    ContentDocument.FileType,
                    LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :recordIds
                ORDER BY ContentDocument.ContentModifiedDate DESC
            ]) {
                if (urlMap.containsKey(cdl.LinkedEntityId)) {
                    continue;
                }
                String rendition = cdl.ContentDocument.FileType == 'PDF' ? 'SVGZ' : 'ORIGINAL_Png';
                String urlString =
                    '/sfc/servlet.shepherd/version/renditionDownload?rendition=' +
                    rendition +
                    '&versionId=' +
                    cdl.ContentDocument.LatestPublishedVersionId;
                urlMap.put(cdl.LinkedEntityId, urlString);
            }
        } catch (Exception ex) {
            System.debug('Problem getting  image for Annoucement: ' + ex.getMessage());
        }
        return urlMap;
    }

    public static String getImageUrl(Id recordId) {
        return getImageUrls(new List<Id>{ recordId }).get(recordId);
    }

    public static Set<String> getUserSkills(Id userId) {
        Set<String> skills = new Set<String>();
        skills.addAll(getChatSkills(userId));
        skills.addAll(getServiceResourceSkills(userId));
        return skills;
    }

    /**
     * @Get the assigned service resource skills for the given user ID
     * @author Stian Ruud Schikora | 05-10-2022
     * @param userId
     * @return Set<String>
     **/
    public static Set<String> getServiceResourceSkills(Id userId) {
        Set<String> skills = new Set<String>();

        for (ServiceResourceSkill srSkill : [
            SELECT Id, Skill.DeveloperName
            FROM ServiceResourceSkill
            WHERE ServiceResource.RelatedRecordId = :userId
        ]) {
            skills.add(srSkill.Skill.DeveloperName);
        }

        return skills;
    }

    public static Set<String> getChatSkills(Id userId) {
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
            WHERE RecordType.Name = 'Campaign' AND NKS_Campaign_To_Date__c >= TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (campaigns.size() > 0) {
            NKS_Announcement__c campaign = campaigns[0];
            campaign.NKS_ImageURL__c = getImageUrl(campaign.Id);
            if (campaign.NKS_ImageURL__c != null && campaign.NKS_ImageURL__c != '') {
                return campaign;
            } else {
                System.debug('You may not have uploaded any images for the campaign.');
                return null;
            }
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
                NKS_News_Other_Authors__c,
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

    @AuraEnabled
    public static List<Knowledge__kav> getReadyResponses() {
        try {
            List<Knowledge__kav> readyResponses = [
                SELECT Id, Title, LastModifiedDate
                FROM Knowledge__kav
                WHERE Title LIKE 'Felles - Svarberedskap%' AND PublishStatus = 'Online'
                ORDER BY LastModifiedDate DESC
                LIMIT 3
            ];

            if (readyResponses.size() > 0) {
                return readyResponses;
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
        return null;
    }

    @invocableMethod(label='Remove HTML Tags')
    public static List<String> removeHtmlTags(List<String> richTextList) {
        String richText = richTextList[0];
        List<String> plainTextList = new List<String>();
        richText = richText.stripHtmlTags();
        plainTextList.add(richText);
        return plainTextList;
    }

    @AuraEnabled(cacheable=true)
    public static Integer countNewsViews(Id recordId) {
        List<Id> originalList = new List<Id>();
        Set<Id> resultList = new Set<Id>();

        try {
            List<NKS_Audit_Log__c> alList = [
                SELECT Id, Name, Announcement__c, User__c, Viewed_date__c
                FROM NKS_Audit_Log__c
                WHERE Announcement__c = :recordId
                ORDER BY CreatedDate DESC
            ];

            if (alList.size() > 0) {
                for (Integer i = 0; i < alList.size(); i++) {
                    originalList.add(alList[i].User__c);
                }

                resultList.addAll(originalList);
                return resultList.size();
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
        return null;
    }
}
