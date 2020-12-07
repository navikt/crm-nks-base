public with sharing class NKS_PersonBadgesController {
    
    public static final Set<String> HOT_ENTITLEMENT_FIELDS = new Set<String>{
        'HOT_DailyLifeInterpreter__c',
        'HOT_EducationInterpreter__c',
        'HOT_Escort__c',
        'HOT_HapticCommunication__c',
        'HOT_InterpreterAtWork__c',
        'HOT_RemoteInterpreter__c',
        'HOT_SignLanguage__c',
        'HOT_SignLanguageWithLimitedFieldOfView__c',
        'HOT_SignToSupportMouthReading__c',
        'HOT_SpeechInterpreting__c',
        'HOT_TactileSignLanguage__c',
        'HOT_WritenInterpreting__c'
    };

    @AuraEnabled(cacheable=true)
    public static PersonBadgeData getPersonBadgesAndInfo(String field, String parentObject, String parentRecordId) {
        Id personId = getPersonId(field, parentObject, parentRecordId);
        Person__c person = getPerson(personId);
        return new PersonBadgeData(person);
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

    /**
     * @description recursive method for collecting the value of a field on a sObject
     */
    private static Object getFieldValue(SObject obj, String fieldName) {
        List<String> fieldNameList = fieldName.split('\\.');

        if(1 < fieldNameList.size()) {
            return getFieldValue(obj.getSObject(fieldNameList.remove(0)), String.join(fieldNameList, '.'));
        }

        return obj.get(fieldNameList[0]);
    }

    /**
     * @description The get Person query is made dynamic in order to use some HOT fields without having a package dependancy.
     */
    private static Person__c getPerson(Id personId) {
        Person__c person;
        Set<String> objectFields = Schema.SObjectType.Person__c.fields.getMap().keySet();
        Set<String> fields = new Set<String>();
        Set<String> fieldsToLabel = new Set<String>();
        String queryString = 'SELECT ';
        
        
        fields.add('Id');
        fieldsToLabel.add('INT_Confidential__c');
        fields.add('INT_GuardianshipOrFuturePowerOfAttorney__c');
        fields.add('INT_IsDeceased__c');
        fields.add('INT_IsNavEmployee__c');
        fields.add('INT_PowerOfAttorney__c');
        fields.add('INT_SpokenLanguageIntepreter__c');
        fields.add('NKS_NumberOfSecurityMeasures__c');

        //HOT Fields
        fields.add('HOT_HasEntitlement__c');
        fields.addAll(HOT_ENTITLEMENT_FIELDS);
        fieldsToLabel.add('HOT_DegreeOfHearingAndVisualImpairment__c');
        
        for(String str : fields) {
            if(objectFields.contains(str.toLowerCase())) {
                queryString += str += ', ';
            }
        }

        for(String str : fieldsToLabel) {
            if(objectFields.contains(str.toLowerCase())) {
                queryString += 'toLabel(' + str + '), ';
            }
        }

        queryString += '('
        +'	SELECT Id,'
        +'		INT_Person__c,'
        +'		toLabel(INT_SecurityMeasure__c),'
        +'		INT_ValidFromDate__c,'
        +'		INT_ValidToDate__c'
        +'	FROM SecurityMeasures__r'
        +')';
        
        queryString += ' FROM Person__c WHERE Id = :personId';
        
        person = (Person__c) Database.query(queryString)[0];

        return person;
    }

    public class PersonBadgeData {
        @AuraEnabled public List<Badge> badges;
        @AuraEnabled public List<SecurityMeasure> securityMeasures;
        @AuraEnabled public List<String> spokenLanguagesIntepreter;
        @AuraEnabled public List<GuardianshipOrFuturePowerOfAttorney> guardianships;
        @AuraEnabled public PowerOfAttorney powerOfAttorney;
        @AuraEnabled public List<String> entitlements;
        private Person__c person;
        private Set<String> fieldSet;

        public PersonBadgeData(Person__c person) {
            badges = new List<Badge>();
            securityMeasures = new List<SecurityMeasure>();
            spokenLanguagesIntepreter = new List<String>();
            guardianships = new List<GuardianshipOrFuturePowerOfAttorney>();
            entitlements = new List<String>();
            this.person = person;
            fieldSet = Schema.SObjectType.Person__c.fields.getMap().keySet();
            setBadgeData();
        }

        private void setBadgeData() {
            setSecurityMeasures();
            setIsConfidential();
            setIsNavEmployee();
            setIsDeceased();
            setPowerOfAttorney();
            setGuardianshipOrFuturePowerOfAttorney();
            setSpokenLanguagesIntepreter();
            setDegreeOfHearingAndVisualImpairment();
            setEntitlements();
        }

        private void setSecurityMeasures() {
            if(0 < person.NKS_NumberOfSecurityMeasures__c) {
                badges.add(new Badge('securityMeasures', person.NKS_NumberOfSecurityMeasures__c + ' sikkerhetstiltak', 'slds-theme_warning pointer', 'utility:warning', 'Vær oppmerksom', true));
    
                for(SecurityMeasure__c sm : person.SecurityMeasures__r) {
                    securityMeasures.add(new SecurityMeasure(sm.Id, sm.INT_ValidToDate__c, sm.INT_ValidFromDate__c, sm.INT_SecurityMeasure__c)); 
                }
            }
        }

        private void setIsConfidential() {
            if(String.isNotBlank(person.INT_Confidential__c) && 'UGRADERT' != person.INT_Confidential__c) {
                badges.add(new Badge('confidential', person.INT_Confidential__c));
            }
        }

        private void setIsNavEmployee() {
            if(true == person.INT_IsNavEmployee__c) {
                badges.add(new Badge('isNavEmployee', getFieldLabel('INT_IsNavEmployee__c')));
            }
        }

        private void setSpokenLanguagesIntepreter() {
            if(true == String.isNotBlank(person.INT_SpokenLanguageIntepreter__c)){
                badges.add(new Badge('spokenLanguageIntepreter', getFieldLabel('INT_SpokenLanguageIntepreter__c'), 'pointer', '', '', true));
    
                for(String language : person.INT_SpokenLanguageIntepreter__c.split(';')) {
                    spokenLanguagesIntepreter.add(language);
                }
            }
        }

        private void setIsDeceased() {
            if(true == person.INT_IsDeceased__c) {
                badges.add(new Badge('isDeceased', getFieldLabel('INT_IsDeceased__c')));
            }
        }

        private void setPowerOfAttorney() {
            if(String.isNotBlank(person.INT_PowerOfAttorney__c)) {
                badges.add(new Badge('powerOfAttorney', getFieldLabel('INT_PowerOfAttorney__c'), 'pointer', '', '', true));
    
                powerOfAttorney = (PowerOfAttorney) JSON.deserialize(person.INT_PowerOfAttorney__c, PowerOfAttorney.class);
            }
        }

        private void setGuardianshipOrFuturePowerOfAttorney() {
            if(String.isNotBlank(person.INT_GuardianshipOrFuturePowerOfAttorney__c)) {
                badges.add(new Badge('guardianshipOrFuturePowerOfAttorney',getFieldLabel('INT_GuardianshipOrFuturePowerOfAttorney__c'),'pointer','','',true));
    
                List<GuardianshipOrFuturePowerOfAttorney> guardienships = (List<GuardianshipOrFuturePowerOfAttorney>) JSON.deserialize(person.INT_GuardianshipOrFuturePowerOfAttorney__c, List<GuardianshipOrFuturePowerOfAttorney>.class);
                for(Integer i = 0; i<guardienships.size();i++) {
                    guardienships[0].id = ''+i;
                }
                if(false == guardienships.isEmpty()) {
                    guardianships.addAll(guardienships);
                }
            }
        }

        private void setDegreeOfHearingAndVisualImpairment() {
            if(fieldSet.contains('hot_degreeofhearingandvisualimpairment__c')) {
                
                String degreeOfHearingAndVisualImpairment = (String) person.get('HOT_DegreeOfHearingAndVisualImpairment__c');

                if(String.isNotBlank(degreeOfHearingAndVisualImpairment)) {
                    badges.add(new Badge('degreeOfHearingAndVisualImpairment', degreeOfHearingAndVisualImpairment));
                }
            }
        }

        private void setEntitlements() {
            if(fieldSet.contains('hot_hasentitlement__c')) {
                if(true == (Boolean) person.get('HOT_HasEntitlement__c')) {
                    badges.add(new Badge('entitlements',getFieldLabel('HOT_HasEntitlement__c'),'pointer','','',true));
        
                    for(String entitlementField : NKS_PersonBadgesController.HOT_ENTITLEMENT_FIELDS) {
                        if(true == (Boolean) person.get(entitlementField)) {
                            entitlements.add(getFieldLabel(entitlementField));
                        }    
                    }
                }
            }
        }

        private String getFieldLabel(String fieldApiName) {
            SObjectType type = Schema.getGlobalDescribe().get('Person__c');
            Map<String,Schema.SObjectField> mfields = type.getDescribe().fields.getMap();
            return mfields.get(fieldApiName).getDescribe().getLabel();
        }
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
