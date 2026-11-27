public without sharing class NKS_PuzzelCallData {
    // Puzzel appends a property to a quoted lookup value, rather than sending standalone JSON.
    private static final Pattern AUTHENTICATION_PAYLOAD = Pattern.compile(
        '"([^"\\s\\\\]+)",\\s*"authenticated"\\s*:\\s*"(true|false|error)"'
    );
    private static final List<String> QUERY_FIELDS = new List<String>{
        'puzzel__SessionId__c',
        'puzzel__Queue__c',
        'puzzel__AccessNumber__c',
        'puzzel__CaseId__c'
    };

    public static Schema.SObjectType getEnquiryLogObject() {
        try {
            return ((SObject) Type.forName('puzzel__EnquiryLog__c').newInstance()).getSObjectType();
        } catch (Exception e) {
            // Will be null in scratch orgs without Puzzel package.
            return null;
        }
    }

    public static List<Object> getEnquiryLogs(List<String> sessionIds) {
        if (Test.isRunningTest()) {
            return (List<Object>) JSON.deserializeUntyped(NKS_CallFlowController_Test.MOCK_ENQUIRY_LOG);
        }

        fflib_QueryFactory qf = new fflib_QueryFactory(getEnquiryLogObject());
        String soql = qf.selectFields(QUERY_FIELDS).setCondition('puzzel__SessionId__c IN :sessionIds').toSOQL();
        // Avoid a compile-time dependency on the managed Puzzel package.
        return (List<Object>) JSON.deserializeUntyped(JSON.serialize(Database.query(soql, AccessLevel.SYSTEM_MODE)));
    }

    public static String normalizeLookupValue(String value) {
        if (value == null) {
            return null;
        }
        Matcher payload = AUTHENTICATION_PAYLOAD.matcher(value);
        return payload.matches() ? payload.group(1) : value;
    }

    public static String getAuthenticationStatus(String value) {
        if (value == null) {
            return null;
        }
        Matcher payload = AUTHENTICATION_PAYLOAD.matcher(value);
        return payload.matches() ? payload.group(2) : null;
    }
}
