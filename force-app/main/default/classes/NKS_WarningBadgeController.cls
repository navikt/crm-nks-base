public with sharing class NKS_WarningBadgeController {
    @AuraEnabled
    public static List<String> getBadges(String parentId) {
        List<Person__c> person = [
            SELECT
                Id,
                CRM_Account__c,
                INT_Confidential__c,
                INT_SpokenLanguageIntepreter__c
            FROM Person__c
            WHERE CRM_Account__c = :parentId
        ];
        List<String> badges = new List<String>();
        if (person[0].INT_Confidential__c != 'UGRADERT') {
            badges.add(person[0].INT_Confidential__c);
        }
        if (person[0].INT_SpokenLanguageIntepreter__c != null) {
            badges.add('Talespråktolk');
        }
        return badges;
    }
}
