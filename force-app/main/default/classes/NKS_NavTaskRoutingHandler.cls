global class NKS_NavTaskRoutingHandler {
    @InvocableMethod
    public static List<String> getQueueIds(List<Id> accountIds) {
        List<String> queueIds = new List<String>();
        Map<Integer, ApexSharingRuleWrapper> ruleByByNavTask = RecordOwnerService.getQueuesAndNavUnits(
            getSobjectWrappers(accountIds),
            'TemporaryLayoff__c'
        );
        for (ApexSharingRuleWrapper sharingRule : ruleByByNavTask.values()) {
            queueIds.add(sharingRule.queueId);
        }
        return queueIds;
    }

    private static List<SobjectWrapper> getSobjectWrappers(
        List<Id> accountIds
    ) {
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        Integer recordIndex = 0;
        for (Account acc : [
            SELECT INT_MunicipalityNumber__c, ShippingPostalCode
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            SobjectWrapper wrapper = new SobjectWrapper();
            wrapper.Municipality = acc.INT_MunicipalityNumber__c;
            wrapper.PostalCode = acc.ShippingPostalCode;
            wrappers.add(wrapper);
        }
        return wrappers;
    }
}
