public with sharing class WebsakCaseNumberMapping {
    public string mapByTitle(String title, Boolean isSandbox, String type) {
        for (WebsakCaseNumberMapping__mdt mapping : [
            SELECT Id, MasterLabel, CaseNumberTest__c, CaseNumberProd__c
            FROM WebsakCaseNumberMapping__mdt
            WHERE Type__c = :type
            ORDER BY Order__c, MasterLabel
        ]) {
            if (title.startsWith(mapping.MasterLabel)) {
                return isSandbox ? mapping.CaseNumberTest__c : mapping.CaseNumberProd__c;
            }
        }
        return null;
    }
}
