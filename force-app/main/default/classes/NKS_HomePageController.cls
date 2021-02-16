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
        Boolean showimage
    ) {
        List<Record> records = new List<Record>();

        String query = 'SELECT LastModifiedDate, CreatedDate ,' + title;
        if (content != null)
            query += ' , ' + content;
        query += ' FROM ' + objectName;
        query += ' WHERE ' + filter;
        if (orderby != null)
            query += ' ORDER BY ' + orderby;
        if (limitNumber != null)
            query += ' LIMIT ' + limitNumber;

        List<SObject> listtoreturn = Database.query(query);
        records = createRecords(
            listtoreturn,
            objectName,
            title,
            content,
            datefield,
            showimage
        );
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
                record.content = r.get(content)
                    .toString()
                    .replaceAll('\\<.*?\\>', '');
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
}
