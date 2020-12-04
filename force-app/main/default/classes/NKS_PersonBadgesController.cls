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
                                INT_GuardianshipOrFuturePowerOfAttorney__c,
                                INT_IsDeceased__c,
                                INT_IsNavEmployee__c,
                                INT_PowerOfAttorney__c,
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

    @TestVisible
    private static PersonBadgeData setBadgeData(Person__c person) {
        PersonBadgeData data = new PersonBadgeData();

        if(0 < person.NKS_NumberOfSecurityMeasures__c) {
            data.badges.add(new Badge('securityMeasures', person.NKS_NumberOfSecurityMeasures__c + ' sikkerhetstiltak', 'slds-theme_warning pointer', 'utility:warning', 'Vær oppmerksom', true));

            for(SecurityMeasure__c sm : person.SecurityMeasures__r) {
                data.securityMeasures.add(new SecurityMeasure(sm.Id, sm.INT_ValidToDate__c, sm.INT_ValidFromDate__c, sm.INT_SecurityMeasure__c)); 
            }
        }

        if(String.isNotBlank(person.INT_Confidential__c) && 'UGRADERT' != person.INT_Confidential__c) {
            data.badges.add(new Badge('confidential', person.INT_Confidential__c));
        }

        if(true == person.INT_IsNavEmployee__c) {
            data.badges.add(new Badge('isNavEmployee',getFieldLabel('INT_IsNavEmployee__c')));
        }

        if(true == String.isNotBlank(person.INT_SpokenLanguageIntepreter__c)){
            data.badges.add(new Badge('spokenLanguageIntepreter',getFieldLabel('INT_SpokenLanguageIntepreter__c'),'pointer','','',true));

            for(String language : person.INT_SpokenLanguageIntepreter__c.split(';')) {
                data.spokenLanguagesIntepreter.add(language);
            }
        }

        if(true == person.INT_IsDeceased__c) {
            data.badges.add(new Badge('isDeceased',getFieldLabel('INT_IsDeceased__c')));
        }

        if(String.isNotBlank(person.INT_PowerOfAttorney__c)) {
            data.badges.add(new Badge('powerOfAttorney',getFieldLabel('INT_PowerOfAttorney__c'),'pointer','','',true));

            data.powerOfAttorney = (PowerOfAttorney) JSON.deserialize(person.INT_PowerOfAttorney__c, PowerOfAttorney.class);
        }

        if(String.isNotBlank(person.INT_GuardianshipOrFuturePowerOfAttorney__c)) {
            data.badges.add(new Badge('guardianshipOrFuturePowerOfAttorney',getFieldLabel('INT_GuardianshipOrFuturePowerOfAttorney__c'),'pointer','','',true));

            List<GuardianshipOrFuturePowerOfAttorney> guardienships = (List<GuardianshipOrFuturePowerOfAttorney>) JSON.deserialize(person.INT_GuardianshipOrFuturePowerOfAttorney__c, List<GuardianshipOrFuturePowerOfAttorney>.class);
            for(Integer i = 0; i<guardienships.size();i++) {
                guardienships[0].id = ''+i;
            }
            if(false == guardienships.isEmpty()) {
                data.guardianships.addAll(guardienships);
            }
        }
        return data;
    }

    private static String getFieldLabel(String fieldApiName) {
        SObjectType type = Schema.getGlobalDescribe().get('Person__c');
        Map<String,Schema.SObjectField> mfields = type.getDescribe().fields.getMap();
        return mfields.get(fieldApiName).getDescribe().getLabel();
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
        @AuraEnabled
        public List<GuardianshipOrFuturePowerOfAttorney> guardianships {get;set;}
        @AuraEnabled
        public PowerOfAttorney powerOfAttorney {get;set;}

        public PersonBadgeData() {
            badges = new List<Badge>();
            securityMeasures = new List<SecurityMeasure>();
            spokenLanguagesIntepreter = new List<String>();
            guardianships = new List<GuardianshipOrFuturePowerOfAttorney>();
        }
    }

    public class PowerOfAttorney {
        @AuraEnabled public String motpartsRolle { get { return motpartsRolle.toLowerCase().capitalize(); } set; }
        @AuraEnabled public String motpartsPersonident;
        @AuraEnabled public List<String> omraader;
        @AuraEnabled public String omraade { get{ return omraadeString(); } set;}
        @AuraEnabled public Date gyldigFraOgMed;
        @AuraEnabled public Date gyldigTilOgMed;

        private String omraadeString() {
            if(1 == omraader.size() && '*'.equalsIgnoreCase(omraader[0])) {
                return 'Gjelder alle ytelser';
            }

            if(1 < omraader.size()) {
                return String.join(omraader, ',');
            }

            return '';
        }
    }

    public class GuardianshipOrFuturePowerOfAttorney {
        @AuraEnabled public String type;
        @AuraEnabled public String embete;
        @AuraEnabled public String navn;
        @AuraEnabled public String motpartsPersonident;
        @AuraEnabled public String omfang;
        @AuraEnabled public Boolean omfangetErInnenPersonligOmraade;
        @AuraEnabled public String id;
    }

    public class SecurityMeasure{
        @AuraEnabled public Id RecordId;
        @AuraEnabled public Date ToDate;
        @AuraEnabled public Date FromDate;
        @AuraEnabled public string SecurityMeasure;

        public SecurityMeasure(Id recordId, Date toDate, Date fromDate, String securityMeasure){
            this.RecordId=recordId;
            this.ToDate=toDate;
            this.FromDate=fromDate; 
            this.SecurityMeasure=securityMeasure;
        }
    }
}
