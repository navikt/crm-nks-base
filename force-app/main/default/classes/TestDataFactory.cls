// Class for creating test data
@isTest
public class TestDataFactory {

    /* This method is used for creating a record. The record is inserted before it's returned,
     * and default fields are populated.
     * @param record [sObject: the record]
     * @return       [sObject: the record, inserted and with defualt fields populated]
     */ 
    public static sObject createRecord(sObject record){
        return createRecord(record,true);
    }

    /* This method is used for creating a record using a dynamic reference. The record id is returned.
     * Use this when implementing field defaults for child objects that have required parent relationships
     * so that the framework stays independent of the database model
     * @param record [sObject: the record]
     * @return       [sObject: the record, inserted and with defualt fields populated]
     */ 
    public static Id createRecord(String objectName, String recordType){
        sObject record = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
        if(String.isNotBlank(recordType)) {
            record.put('RecordTypeId', Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId());
        }
        return (Id) createRecord(record,true).get('Id');
    }
    
    /* This method is used for creating a record. Default fields are populated before it's returned
     * @param record    [sObject: the record]
     * @param doInsert  [Boolean: true if the record is to be inserted, false otherwise]
     * @return          [sObject: the record, with defualt fields populate]
     */
    public static sObject createRecord(sObject record,Boolean doInsert){
        Type t = getDefaultClassName(record);
        if(t != null){
            FieldDefaults defaults = (FieldDefaults)t.newInstance();
            addFieldDefaults(record, defaults.getFieldDefaults());
        }
        if(doInsert) insert record;
        return record;
    }
    
     /* This method is used for creating a list of records. The list is inserted before it's returned,
     * and default fields are populated.
     * @param record    [sObject: a sObject record]
     * @param numRecords[Integer: the number of records to create]
     * @return          [List<sObject>: the list of sObjects, with defualt fields populate]
     */
    public static list<sObject> createRecordList(sObject record, Integer numRecords){
        return createRecordList(record, numRecords, true);
    }
    
      /* This method is used for creating a list of records. Default fields are populated before it's returned.
     * @param record    [sObject: a sObject record]
     * @param length    [Integer: the length of the list]
     * @param doInsert  [Boolean: true if the list is to be inserted, false otherwise]
     * @return          [List<sObject>: the list of sObjects, with defualt fields populate]
     */
    public static List<sObject> createRecordList(sObject record, Integer numRecords, Boolean doInsert){
        List<sObject> records = new List<sObject>();
        for(Integer i=0 ; i < numRecords ; i++){
            records.add(record.clone(false,false,false,false));   
        }
        return createRecordList(records,doInsert);
    }
    
    /* This method is used for creating a list of record. The list is inserted before it's returned,
     * and default fields are populated.
     * @param record    [List<sObject>: a list of records]
     * @return          [List<sObject>: the list of records, with default fields populated]
     */
    Public static List<sObject> createRecordList(List<sObject> records){
        return createRecordList(records,true); 
    }
    
     /* This method is used for creating a list of records. Default fields are populated before it's returned.
     * @param record    [List<sObject>: a list of records]
     * @param doInsert  [Boolean: true if the list is to be inserted, false otherwise]
     * @return          [List<sObject>: the list of sObjects, with defualt fields populated]
     */
    public static List<sObject> createRecordList(List<sObject> records, Boolean doInsert){
        String objectName = String.valueOf(records[0].getSObjectType());
        Type t = getDefaultClassName(records[0]);
        if(t != null){
            for(Integer i=0 ; i<records.size() ; i++){
                FieldDefaults defaults = (FieldDefaults)t.newInstance();
                addFieldDefaults(records[i], defaults.getFieldDefaults());
                String uniqFieldName = uniqueField.get(objectName);
                if(uniqFieldName == null){
                    uniqFieldName = 'Name';
                }
                if(objectName !='User') records[i].put(uniqFieldName,'Test '+i);
                if(objectName =='User') records[i].put(uniqFieldName,'Test' + i +'@test.com');
            }
        }
        if(doInsert) insert records;
        return records;
    }
   
    // Used, when creating a list, to define which fields should be unique among the records. 
    public static final Map<String,String> uniqueField = new Map<String,String>{
        'Contact' => 'LastName',
        'User' => 'Username',
        'QuickText' => 'Name'
    };
    
     /* This method is used for retrieving the type that corresponds to the class we want to use. The class
      * is used to set default field values.
     * @param record    [sObject: a record]
     * @return          [Type: the type that corresponds to the class]
     */    
    public static Type getDefaultClassName(sObject record){
        String objectName = String.valueOf(record.getSObjectType());
        String namespacePrefix = '';  
        String className = 'TestDataFactory.'+objectName.replaceAll('__c|__|_|'+namespacePrefix, '')+'Defaults';
        return Type.forName(className);
    }
    
    /* This method adds default fields to the record if they are blank
     * @param record    [sObject: the record]
     * @param defaults  [Map<String,Object>: map between defualt field names and values]
     */
    public static void addFieldDefaults(sObject record, Map<String,Object> defaults){
        for(String field : defaults.keySet()){
            if(record.get(field)==null){
                record.put(field,defaults.get(field));
            }
        }
    }

    //      HELPER METHODS              //
    // Helper methods needed for record creation

    /**
    * @description: Generation of random string to be used for i.e. setting
    * required unique fields for test data.
    * @author Stian Ruud Schikora | 10-12-2020 
    * @param len 
    * @return String 
    **/
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    /**
    * @description: Generates a string of random numbers of given length
    * Used for i.e. generating random person idents.
    * @author Stian Ruud Schikora | 10-12-2020 
    * @param len 
    * @return String 
    **/
    public static String generateRandomNumberString(Integer len) {
        final String chars = '0123456789';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
  
   
    // Field defaults for all objects
    public interface FieldDefaults{
        Map<String,Object> getFieldDefaults();
    }
    
    //        OBJECT DEFAULTS           //
    // The following classes defines default field values. When a field is made required on an
    // object, a default value should be defined for it in the object's respective class
     
    
    public class ContactDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'FirstName' => 'Test',
                'LastName' => 'Testesen'
            };
        }
    }


    public class CampaignDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Name' => 'Test',
                'Status' => 'Active',
                'isActive' => true
            };
        }
    }

    public class AccountDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Name' => 'Test Testesen'
            };
        } 
    }

    public class LeadDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'LastName' => 'Test Testesen',
                'Company' => 'Test Company'
            };
        } 
    }

    public class TaskDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Priority' => 'High',
                'Status' => 'In Progress'
            };
        } 
    }

    public class OrderDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Name' => 'Test Testesen',
                'AccountId' => createRecord('Account', null),
                'EffectiveDate' => Date.today(),
                'Status' => 'Draft',
                'PriceBook2Id' => Test.getStandardPricebookId()
            };
        } 
    }

    public class OrderItemDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'PriceBookEntryId' => createRecord('PricebookEntry', null),
                'OrderId' => createRecord('Order', null),
                'Quantity' => 1,
                'UnitPrice' => 100
            };
        } 
    }

    public class PriceBookEntryDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'PriceBook2Id' => Test.getStandardPricebookId(),
                'Product2Id' => createRecord('Product2', null),
                'isActive' => true,
                'UnitPrice' => 100
            };
        } 
    }

    public class Product2Defaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Name' => 'SF Merch',
                'ProductCode' => '1234',
                'isActive' => true
            };
        }
    }
    
    public class OpportunityDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Name' => 'Test Opportunity',
                'CloseDate' => Date.today(),
                'StageName' => 'Closed Won',
                'Amount' => 100,
                'CampaignId' => createRecord('Campaign', null)
            };
        }  
    }

    public class LiveChatTranscriptDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'LiveChatVisitorId' => createRecord('LiveChatVisitor', null)
            };
        }
    }

    public class LiveChatVisitorDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                //No defaults
            };
        }
    }

    public class QuickTextDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Message' => 'Dette er en melding'
            };
        }
    }

    public class PersonDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'Name' => generateRandomNumberString(11)
            };
        }
    }

    public class AsyncRequestDefaults implements FieldDefaults{
        public Map<String,Object> getFieldDefaults(){
            return new Map<String,Object>{
                'CRM_Params__c' => generateRandomString(18),
                'CRM_Status__c' => AsyncRequestService.STATUS_PENDING,
                'CRM_AsyncType__c' => 'TEST_TYPE'
            };
        }
    }
}