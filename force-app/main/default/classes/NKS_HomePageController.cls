public with sharing class NKS_HomePageController {
    @AuraEnabled(cacheable=true)
    public static List<String> getUserSkills() {
        try {
            List<String> skills = new List<String>();
            for (String skill : getUserSkills(UserInfo.getUserId())) {
                skills.add(skill.replaceAll('NKS_Skill_', ''));
            }
            return skills;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static string getField(String type) {
        List<NKS_Announcement__c> announcements = new List<NKS_Announcement__c>();
        String res = null;
        try {
            for (NKS_Announcement__c announcement : [
                SELECT NKS_Information__c
                FROM NKS_Announcement__c
                WHERE RecordType.DeveloperName = :type AND CreatedDate = LAST_N_DAYS:15
                ORDER BY SystemModstamp DESC
                LIMIT 1
            ]) {
                return announcement.NKS_Information__c.replace('<img', '<img style="max-height: 100px"');
            }
        } catch (Exception ex) {
            System.debug('Problem getting Information-field for Announcement' + ex.getMessage());
            throw new AuraException('Kunne ikke hente informasjonen/n' + ex.getMessage());
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<Record> getCaseList(
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField
    ) {
        List<Record> records = new List<Record>();

        fflib_QueryFactory qf = getQueryFactory(Case.getSObjectType(), title, content, filter, orderBy, limitNumber);
        qf.selectFields(new Set<String>{ 'LastModifiedDate', 'CreatedDate', title });
        String query = qf.toSOQL().replace('SELECT', 'SELECT toLabel(Status),');
        List<SObject> listToReturn = Database.query(query);

        records = createRecords(listToReturn, 'Case', title, content, dateField, false);
        return records;
    }

    @AuraEnabled(cacheable=true)
    public static List<Record> getAnnouncementList(
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField,
        Boolean showImage,
        Boolean filterBySkills,
        List<String> skills
    ) {
        List<Record> records = new List<Record>();

        // fflib_QueryFactory qf = getQueryFactory(
        //     NKS_Announcement__c.getSObjectType(),
        //     title,
        //     content,
        //     filter,
        //     orderBy,
        //     limitNumber
        // );

        String q =
            'SELECT NKS_News_Pin__c, NKS_News_Publish_Date__c, NKS_News_Update_Date__c, LastModifiedDate, CreatedDate, ' +
            title +
            ', ' +
            content;
        q = q.removeEnd(',') + ' FROM NKS_Announcement__c';

        // qf.selectFields(new Set<String>{ 'NKS_News_Pin__c', 'NKS_News_Publish_Date__c', 'NKS_News_Update_Date__c' });

        if (filterBySkills == true && skills != null) {
            String skillStringAnnouncement = ('\'' + String.join(skills, '\',\'') + '\'').removeEnd('\'\'');
            // qf.selectField('skills__c');

            if (String.isNotBlank(skillStringAnnouncement)) {
                filter += (String.isBlank(filter) ? '' : ' AND ');
                filter += '(Skills__c = \'\' OR Skills__c INCLUDES (' + skillStringAnnouncement + '))';
            }
            // qf.setCondition(filter);
        }
        // return createRecords(Database.query(qf.toSOQL()), 'NKS_Announcement__c', title, content, dateField, showImage);
        if (String.isNotBlank(filter)) {
            q += ' WHERE ' + filter;
        }

        if (String.isNotBlank(orderBy)) {
            q += ' ORDER BY ' + orderBy;
        }

        if (String.isNotBlank(limitNumber)) {
            q += ' LIMIT ' + limitNumber;
        }

        return createRecords(Database.query(q), 'NKS_Announcement__c', title, content, dateField, showImage);
    }

    @AuraEnabled(cacheable=true)
    public static List<Record> getKnowledgeList(
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField,
        Boolean showImage,
        Boolean filterBySkills,
        List<String> skills
    ) {
        List<Record> records = new List<Record>();

        fflib_QueryFactory qf = getQueryFactory(
            Knowledge__kav.getSObjectType(),
            title,
            content,
            filter,
            orderBy,
            limitNumber
        );

        if (filterBySkills == true && skills != null && skills.isEmpty() == false) {
            String skillStringKnowledge = String.join(skills, '__c,') + '__c';

            filter +=
                (String.isBlank(filter) ? '' : ' AND ') +
                'WITH DATA CATEGORY Tema__c ABOVE_OR_BELOW (' +
                skillStringKnowledge +
                ')';
            qf.setCondition(filter);
        }

        return createRecords(Database.query(qf.toSOQL()), 'Knowledge__kav', title, content, dateField, showImage);
    }

    private static fflib_QueryFactory getQueryFactory(
        sObjectType objType,
        String title,
        String content,
        String filter,
        String orderBy,
        String limitNumber
    ) {
        fflib_QueryFactory qf = new fflib_QueryFactory(objType);
        qf.selectFields(new Set<String>{ 'LastModifiedDate', 'CreatedDate', title });
        if (String.isNotBlank(content)) {
            qf.selectFields(content.split(','));
        }

        qf.setCondition(filter);

        if (String.isNotBlank(orderBy)) {
            List<String> orderBys = orderBy.normalizeSpace().split(' ');
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

        if (String.isNotBlank(limitNumber)) {
            qf.setLimit(Integer.valueOf(limitNumber));
        }

        return qf;
    }

    @AuraEnabled(cacheable=true)
    public static List<Record> getList(
        String title,
        String content,
        String objectName,
        String filter,
        String orderBy,
        String limitNumber,
        String dateField
    ) {
        List<Record> records = new List<Record>();
        fflib_QueryFactory qf = getQueryFactory(
            Schema.getGlobalDescribe().get(objectName),
            title,
            content,
            filter,
            orderBy,
            limitNumber
        );
        return createRecords(Database.query(qf.toSOQL()), objectName, title, content, dateField, false);
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
        public Datetime lastUpdatedDate;
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
        Map<Id, String> urlMap = new Map<Id, String>();

        if (listofrecords.isEmpty()) {
            return records;
        }

        if (showImage == true) {
            List<Id> recordIds = new List<Id>();
            for (sObject r : listofrecords) {
                recordIds.add(r.Id);
            }
            urlMap = getImageUrls(recordIds);
        }

        for (sObject r : listofrecords) {
            Record record = new Record();
            record.recordId = r.Id;
            record.pin = false;
            record.publishDate = null;
            record.lastUpdatedDate = null;
            record.name = r.get(title).toString();
            record.modifiedDate = Datetime.valueOf(r.get(datefield));

            if (showImage == true) {
                record.imageurl = urlMap.get(r.Id);
            }

            if (String.isNotBlank(content) && String.isNotBlank((String) r.get(content))) {
                record.content = r.get(content).toString().replaceAll('\\<.*?\\>', '');
                record.summary = (record.content.length() > 600) ? record.content.mid(0, 600) + '...' : record.content;
            }

            if (objectName == 'NKS_Announcement__c') {
                record.pin = (Boolean) r.get('NKS_News_Pin__c');
                record.publishDate = Datetime.valueOf(r.get('NKS_News_Publish_Date__c'));
                record.lastUpdatedDate = Datetime.valueOf(r.get('NKS_News_Update_Date__c'));
            }

            record.status = objectName == 'Case' ? r.get('Status').toString() : '';

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

    @AuraEnabled(cacheable=true)
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
                NKS_News_Update_Date__c,
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

    @AuraEnabled(cacheable=true)
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
            AggregateResult[] countResult = [
                SELECT COUNT_DISTINCT(User__c) nmbOfUniqueViews
                FROM NKS_Audit_Log__c
                WHERE Announcement__c = :recordId
            ];

            return Integer.valueOf(countResult[0].get('nmbOfUniqueViews'));
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
        return null;
    }
}
