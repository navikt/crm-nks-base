public inherited sharing class NKS_PersonAccessBadgesController {
    /**
     * @description Get an apex type holding all the data we need for showing badges.
     */
    @AuraEnabled(cacheable=true)
    public static PersonAccessBadges getPersonAccessBadges(
        String field,
        String parentObject,
        String parentRecordId
    ) {
        Id personId = getPersonId(field, parentObject, parentRecordId);

        if (hasAccess(personId)) {
            return new PersonAccessBadges(createAccessBadgeList(getPerson(personId)), '', true);
        } else {
            return new PersonAccessBadges(
                new List<AccessBadge>(),
                'Du mangler tilgang til å se informasjon knyttet til denne brukeren',
                false
            );
        }
    }

    private static List<AccessBadge> createAccessBadgeList(Person__c person) {
        List<AccessBadge> accessBadgeList = new List<AccessBadge>();

        if (person.INT_IsNavEmployee__c) {
            accessBadgeList.add(new AccessBadge('isNavEmployee', 'Skjermet person'));
        }

        if (false == person.INT_Confidential__c.equalsIgnoreCase('UGRADERT')) {
            accessBadgeList.add(new AccessBadge('isConfidential', 'Skjermet adresse'));
        }

        return accessBadgeList;
    }

    /**
     * @description Dynamically find the person ID
     * *Example
     * - field = 'Account.CRM_Person__c';
     * - objString = 'Case';
     * - recordId = '5001X000007xMSuQAM';
     * - relation = 'Id';
     */
    private static Id getPersonId(String field, String parentObject, String parentRecordId) {
        Id personId = null;
        String queryString =
            'SELECT ' +
            field +
            ' FROM ' +
            parentObject +
            ' WHERE Id = :parentRecordId LIMIT 1';
        List<SObject> objList = Database.query(String.escapeSingleQuotes(queryString));

        if (false == objList.isEmpty()) {
            personId = (Id) getFieldValue(objList[0], field);
        }

        return personId;
    }

    /**
     * @description recursive method for collecting the value of a field on a sObject
     */
    private static Object getFieldValue(SObject obj, String fieldName) {
        List<String> fieldNameList = fieldName.split('\\.');

        if (1 < fieldNameList.size()) {
            return getFieldValue(
                obj.getSObject(fieldNameList.remove(0)),
                String.join(fieldNameList, '.')
            );
        }

        return obj.get(fieldNameList[0]);
    }

    private static Boolean hasAccess(Id recordId) {
        List<UserRecordAccess> result = [
            SELECT RecordID, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordID = :recordId
        ];

        return result.isEmpty() ? false : result[0].HasReadAccess;
    }

    private static Person__c getPerson(Id personId) {
        List<Person__c> personList = [
            SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c
            FROM Person__c
            WHERE Id = :personId
        ];

        return personList.isEmpty() ? null : personList[0];
    }

    public class PersonAccessBadges {
        @AuraEnabled
        public List<AccessBadge> badges;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Boolean hasPersonAccess;

        public PersonAccessBadges(
            List<AccessBadge> badges,
            String message,
            Boolean hasPersonAccess
        ) {
            this.badges = badges;
            this.message = message;
            this.hasPersonAccess = hasPersonAccess;
        }
    }

    public class AccessBadge {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String label;

        public AccessBadge(String name, String label) {
            this.name = name;
            this.label = label;
        }
    }
}
