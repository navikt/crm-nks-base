public with sharing class FamilyRelationViewerController {

    @AuraEnabled(cacheable=true)
    public static List<Relation> getRelatedPersons(Id personId) {
        List<PersonJSONFieldObjects.Familierelasjoner> familyRelations = (List<PersonJSONFieldObjects.Familierelasjoner>) System.JSON.deserialize(
                getFamilyRelationJSONString(personId),
                List<PersonJSONFieldObjects.Familierelasjoner>.class
        );

        Map<String, String> roleByRelatedPersonIdent = new Map<String, String>();
        for (PersonJSONFieldObjects.Familierelasjoner familyRelation : familyRelations) {
            roleByRelatedPersonIdent.put(familyRelation.relatertPersonsIdent, familyRelation.relatertPersonsRolle);
        }

        List<Person__c> relatedPersons = getRelatedPersons(roleByRelatedPersonIdent.keySet());
        // TODO: Implement logic for filtering out children under 21. Currently missing required age data
//        relatedPersons = removeChildrenUnder21(relatedPersons);

        List<Relation> relations = new List<Relation>();
        for (Person__c person : relatedPersons) {
            Relation r = new Relation();
            r.personId = person.Id;
            r.personIdent = person.Name;
            r.personName = person.INT_FirstName__c + ' ' + person.INT_LastName__c;
            r.role = roleByRelatedPersonIdent.get(person.Name).toLowerCase().capitalize();
            relations.add(r);
        }
        return relations;
    }

    public class Relation {
        @AuraEnabled public String personIdent;
        @AuraEnabled public String personId;
        @AuraEnabled public String personName;
        @AuraEnabled public String role;
    }

    // TODO: Implement logic for filtering out children under 21. Currently missing required age data
    private static List<Person__c> removeChildrenUnder21(List<Person__c> familyRelations) {
        return familyRelations;
    }

    private static List<Person__c> getRelatedPersons(Set<String> relatedPersonIds) {
        return [
                SELECT Id,
                        Name,
                        INT_FirstName__c,
                        INT_MiddleName__c,
                        INT_LastName__c
                FROM Person__c
                WHERE Name IN :relatedPersonIds
        ];
    }

    private static String getFamilyRelationJSONString(Id personId) {
        return [
                SELECT Id,
                        INT_FamilyRelations__c
                FROM Person__c
                WHERE Id = :personId
        ].INT_FamilyRelations__c;
    }

}