public with sharing class NKS_PersonBadgesController {
    
    @AuraEnabled(cacheable=true)
    public static PersonBadgeData getPersonBadgesAndInfo(String field, String parentObject, String parentRecordId) {
        Id personId = getPersonId(field, parentObject, parentRecordId);
        Person__c person = getPerson(personId);
        return setBadgeData(person);
    }

    /**
     * *Example
     * - field = 'Account.CRM_Person__c';
     * - objString = 'Case';
     * - recordId = '5001X000007xMSuQAM';
     * - relation = 'Id';
     */
    private static Id getPersonId(String field, String parentObject, String parentRecordId) {
        Id personId = null;
        String queryString = 'SELECT ' + field + ' FROM ' + parentObject + ' WHERE Id = :parentRecordId LIMIT 1';
        List<SObject> objList = Database.query(String.escapeSingleQuotes(queryString));

        if(false == objList.isEmpty()) {
            personId = (Id) NKS_PersonBadgesController.getFieldValue(objList[0],field);
        }

        return personId;
    }

    private static Object getFieldValue(SObject obj, String fieldName) {
        List<String> fieldNameList = fieldName.split('\\.');

        if(1 < fieldNameList.size()) {
            return getFieldValue(obj.getSObject(fieldNameList.remove(0)), String.join(fieldNameList, '.'));
        }

        return obj.get(fieldNameList[0]);
    }

    private static Person__c getPerson(Id personId) {
        Person__c person = [SELECT Id,
                                INT_Confidential__c,
                                INT_IsDeceased__c,
                                INT_IsNavEmployee__c,
                                INT_SpokenLanguageIntepreter__c,
                                NKS_NumberOfSecurityMeasures__c,
                                (
                                    SELECT Id,
                                        INT_Person__c,
                                        INT_SecurityMeasure__c,
                                        INT_ValidFromDate__c,
                                        INT_ValidToDate__c
                                    FROM SecurityMeasures__r
                                )
                            FROM Person__c
                            WHERE Id = :personId];
        return person;
    }

    private static PersonBadgeData setBadgeData(Person__c person) {
        PersonBadgeData data = new PersonBadgeData();

        if(0 < person.NKS_NumberOfSecurityMeasures__c) {
            data.badges.add(new Badge('securityMeasures', person.NKS_NumberOfSecurityMeasures__c + ' sikkerhetstiltak', 'slds-theme_warning pointer', 'utility:warning', 'Vær oppmerksom', true));
        }

        if('UGRADERT' != person.INT_Confidential__c) {
            data.badges.add(new Badge('confidential', person.INT_Confidential__c));
        }

        if(true == person.INT_IsNavEmployee__c) {
            data.badges.add(new Badge('isNavEmployee','NAV Ansatt'));
        }

        if(true == String.isNotBlank(person.INT_SpokenLanguageIntepreter__c)){
            data.badges.add(new Badge('spokenLanguageIntepreter','Talespråktolk','pointer','','',true));

            for(String language : person.INT_SpokenLanguageIntepreter__c.split(';')) {
                data.spokenLanguagesIntepreter.add(language);
            }
        }

        if(true == person.INT_IsDeceased__c) {
            data.badges.add(new Badge('isDeceased','Dødsbo'));
        }

        for(SecurityMeasure__c sm : person.SecurityMeasures__r) {
            data.securityMeasures.add(new SecurityMeasure(sm.Id, sm.INT_ValidToDate__c, sm.INT_ValidFromDate__c, sm.INT_SecurityMeasure__c)); 
        }

        return data;
    }


    public class Badge {
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String styling {get;set;}
        @AuraEnabled
        public String iconName {get;set;}
        @AuraEnabled
        public String iconAltText {get;set;}
        @AuraEnabled
        public Boolean clickable {get;set;}
        @AuraEnabled
        public String tabindex {get;set;}

        public Badge(String name, String label) {
            this(name, label, '','','',false);
        }

        public Badge(String name, String label, String styling, String iconName, String iconAltText, Boolean clickable) {
            this.name = name;
            this.label = label;
            this.styling = styling;
            this.iconName = iconName;
            this.iconAltText = iconAltText;
            this.clickable = clickable;
            this.tabindex = this.clickable ? '0' : '-1';
        }
    }

    public class PersonBadgeData {
        @AuraEnabled
        public List<Badge> badges {get;set;}
        @AuraEnabled
        public List<SecurityMeasure> securityMeasures {get;set;}
        @AuraEnabled
        public List<String> spokenLanguagesIntepreter {get;set;}

        public PersonBadgeData() {
            badges = new List<Badge>();
            securityMeasures = new List<SecurityMeasure>();
            spokenLanguagesIntepreter = new List<String>();
        }
    }

    public class SecurityMeasure{
        @AuraEnabled
        public Id RecordId {get;set;}
        @AuraEnabled
        public Date ToDate {get;set;}
        @AuraEnabled
        public Date FromDate {get;set;}
        @AuraEnabled
        public string SecurityMeasure {get;set;}

        public SecurityMeasure(Id recordId, Date toDate, Date fromDate, String securityMeasure){
            this.RecordId=recordId;
            this.ToDate=toDate;
            this.FromDate=fromDate; 
            this.SecurityMeasure=securityMeasure;
        }
    }
}
