public without sharing class FamilyRelationViewerController {
    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelatedPersons(Id recordId, String objectApiName) {
        Id personId;
        if (objectApiName == 'Case')
            personId = [SELECT Account.CRM_Person__c FROM Case WHERE Id = :recordId]
            .Account.CRM_Person__c;
        else if (objectApiName == 'Account')
            personId = [SELECT CRM_Person__c FROM Account WHERE Id = :recordId].CRM_Person__c;

        List<Relation> relations = new List<Relation>();

        Id userId = UserInfo.getUserId();
        Boolean access = [
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :userId AND RecordId = :personId
        ]
        .HasReadAccess;
        if (!access)
            return relations;

        List<PersonJSONFieldObjects.Familierelasjoner> familyRelations = (List<PersonJSONFieldObjects.Familierelasjoner>) System.JSON.deserialize(
            getFamilyRelationJSONString(personId),
            List<PersonJSONFieldObjects.Familierelasjoner>.class
        );

        Map<String, String> roleByRelatedPersonIdent = new Map<String, String>();
        for (PersonJSONFieldObjects.Familierelasjoner familyRelation : familyRelations) {
            roleByRelatedPersonIdent.put(
                familyRelation.relatertPersonsIdent,
                familyRelation.relatertPersonsRolle
            );
        }

        List<Person__c> relatedPersons = getRelatedPersons(roleByRelatedPersonIdent.keySet());
        Person__c p = getPerson(personId)[0];
        relatedPersons = removeChildrenUnder21(relatedPersons, roleByRelatedPersonIdent, p);
        relations.add(getMaritalRelation(p));
        relations.addAll(createRelations(relatedPersons, roleByRelatedPersonIdent));

        return relations;
    }

    public class Relation {
        @AuraEnabled
        public String personIdent;
        @AuraEnabled
        public String personId;
        @AuraEnabled
        public String accountId;
        @AuraEnabled
        public String personName;
        @AuraEnabled
        public String role;
        @AuraEnabled
        public String sex;
        @AuraEnabled
        public Integer age;
        @AuraEnabled
        public Boolean disableurl;
        @AuraEnabled
        public Boolean child;
    }

    private static List<Person__c> removeChildrenUnder21(
        List<Person__c> familyRelations,
        Map<String, String> relatedPersonIds,
        Person__c p
    ) {
        List<Person__c> withoutChildrenOver21 = new List<Person__c>();
        Integer personage = Integer.valueOf(
            Date.valueOf(p.INT_DateOfBirth__c + ' 00:00:00').daysBetween(Date.Today()) / 365
        );
        for (Person__c person : familyRelations) {
            String role = relatedPersonIds.get(person.Name).toLowerCase().capitalize();
            if (person.INT_DateOfBirth__c != null) {
                Integer age = Integer.valueOf(
                    Date.valueOf(person.INT_DateOfBirth__c + ' 00:00:00')
                        .daysBetween(Date.Today()) / 365
                );
                if (age <= 21 && role == 'Barn')
                    withoutChildrenOver21.add(person);
            }
            if (personage <= 21 && role != 'Barn')
                withoutChildrenOver21.add(person);
        }
        return withoutChildrenOver21;
    }

    private static Relation getMaritalRelation(Person__c p) {
        if (p.INT_MaritalStatus__c != null) {
            Relation maritalrelation = new Relation();
            if (p.INT_MaritalRelation__c != null) {
                Person__c marriedto = getMaritalPerson(p.INT_MaritalRelation__c)[0];
                maritalrelation.personId = marriedto.Id;
                maritalrelation.accountId = marriedto.CRM_Account__c;
                maritalrelation.personIdent = marriedto.Name;
                maritalrelation.personName = marriedto.CRM_Account__r.Name;
                if (marriedto.CRM_Account__r.Name == 'Ikke tilgjengelig')
                    maritalrelation.disableurl = true;
            }
            maritalrelation.role =
                'Sivilstatus: ' + p.INT_MaritalStatus__c.toLowerCase().capitalize();
            maritalrelation.child = false;
            return maritalrelation;
        } else
            return null;
    }

    private static List<Relation> createRelations(
        List<Person__c> relatedPersons,
        Map<String, String> roleByRelatedPersonIdent
    ) {
        List<Relation> relations = new List<Relation>();
        for (Person__c person : relatedPersons) {
            Integer age;
            if (person.INT_DateOfBirth__c != null)
                age = Integer.valueOf(
                    Date.valueOf(person.INT_DateOfBirth__c + ' 00:00:00')
                        .daysBetween(Date.Today()) / 365
                );
            String role = roleByRelatedPersonIdent.get(person.Name).toLowerCase().capitalize();

            Relation r = new Relation();
            r.personId = person.Id;
            r.accountId = person.CRM_Account__c;
            r.personIdent = person.Name;
            r.personName = person.CRM_Account__r.Name;
            r.role = role;
            if (role == 'Barn') {
                if (person.INT_Sex__c == 'Kvinne')
                    r.sex = 'Jente';
                else if (person.INT_Sex__c == 'Mann')
                    r.sex = 'Gutt';
                r.age = age;
                r.child = true;
            } else {
                r.sex = person.INT_Sex__c;
                r.child = false;
                r.age = age;
            }
            if (person.CRM_Account__r.Name == 'Ikke tilgjengelig')
                r.disableurl = true;
            else
                r.disableurl = false;
            relations.add(r);
        }
        return relations;
    }

    private static List<Person__c> getRelatedPersons(Set<String> relatedPersonIds) {
        return [
            SELECT
                Id,
                Name,
                INT_FirstName__c,
                INT_MiddleName__c,
                INT_LastName__c,
                INT_DateOfBirth__c,
                INT_Sex__c,
                CRM_Account__c,
                CRM_Account__r.Name
            FROM Person__c
            WHERE Name IN :relatedPersonIds
        ];
    }

    private static String getFamilyRelationJSONString(Id personId) {
        return [SELECT Id, INT_FamilyRelations__c FROM Person__c WHERE Id = :personId]
        .INT_FamilyRelations__c;
    }

    private static List<Person__c> getPerson(Id personId) {
        return [
            SELECT
                Id,
                INT_MaritalRelation__c,
                INT_MaritalStatus__c,
                INT_ActorId__c,
                INT_DateOfBirth__c
            FROM Person__c
            WHERE Id = :personId
            LIMIT 1
        ];
    }

    private static List<Person__c> getMaritalPerson(String personId) {
        return [
            SELECT Id, Name, INT_ActorId__c, CRM_Account__c, CRM_Account__r.Name
            FROM Person__c
            WHERE Name = :personId
            LIMIT 1
        ];
    }
}
