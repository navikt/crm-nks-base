public with sharing class NKS_HomePageController {
    @AuraEnabled
    public static string getField(String type) {
        String information = [SELECT NKS_Information__c FROM NKS_Announcement__c WHERE NKS_Type__c =: type ORDER BY LastModifiedDate DESC LIMIT 1].NKS_Information__c; 
        return information; 
    }

    @AuraEnabled
    public static List<Record> getList(String fields, String objectName, String filter) {
        List<Record> records = new List<Record>();

        String query = 'SELECT ' + fields + ' FROM ' + objectName;
        query += ' WHERE ' + filter;

        List<SObject> listtoreturn = Database.query(query);
        records = createRecords(listtoreturn); 
        return records; 
    }

    public class Record {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
    }

    private static List<Record> createRecords(List<sObject> listofrecords){
        system.debug('CREATE records'); 
        List<Record> records = new List<Record>();
        for (sObject r : listofrecords) {
            Record record = new Record();
            record.recordId = r.Id;
            records.add(record);
        }
        return records; 
    }
}
