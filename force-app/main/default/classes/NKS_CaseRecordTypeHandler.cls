global class NKS_CaseRecordTypeHandler extends MyTriggers {
    private final Id PHONE_CASE_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('NKS_Phone_Case')
        .getRecordTypeId();

    global override void onBeforeInsert() {
        for (Case casy : (List<Case>) Records) {
            if (casy.Origin == 'Phone') {
                casy.RecordTypeId = PHONE_CASE_TYPE;
            }
        }
    }
}
