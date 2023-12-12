public without sharing class NKS_AuditLogController {
    public static final Id USERID = UserInfo.getUserId();
    public Id recordId { get; set; }
    public Id knowledgeRecordTypeId {
        get {
            return getRecordTypeId('Knowledge Audit Log');
        }
        set;
    }
    public Id newsRecordTypeId {
        get {
            return getRecordTypeId('Announcement Audit Log');
        }
        set;
    }

    public NKS_AuditLogController() {
        recordId = System.currentPagereference().getParameters().get('id');
    }

    @TestVisible
    private static String getRecordTypeId(String recordTypeName) {
        return Schema.SObjectType.NKS_Audit_Log__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }

    @AuraEnabled(cacheable=true)
    public static Integer countViews(Id recordId, String lookupField) {
        List<Id> originalList = new List<Id>();
        Set<Id> resultList = new Set<Id>();
        String query =
            ' SELECT COUNT_DISTINCT(User__c) nmbOfUniqueViews FROM NKS_Audit_Log__c WHERE ' +
            lookupField +
            '= \'' +
            recordId +
            '\'';

        try {
            AggregateResult[] countResult = Database.query(query);

            return Integer.valueOf(countResult[0].get('nmbOfUniqueViews'));
        } catch (Exception ex) {
            throw new AuraHandledException('Problem counting article veiws: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isKnowledgeUser() {
        try {
            return [SELECT Id FROM User WHERE UserPermissionsKnowledgeUser = TRUE AND Id = :USERID]?.Id != null;
        } catch (Exception e) {
            throw new AuraHandledException('Problem checking knowlege user: ' + e.getMessage());
        }
    }
}
