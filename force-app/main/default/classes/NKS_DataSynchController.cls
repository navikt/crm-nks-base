public without sharing class NKS_DataSynchController {
    private static KRP_CalloutService krpService = new KRP_CalloutService();
    private static CRM_ApplicationDomain.Domain domain = CRM_ApplicationDomain.Domain.NKS;

    /**
     * @description Synchronize a persons bank information from KRP
     * @param ident
     * @return  `Boolean`
     */
    @AuraEnabled
    public static Boolean doBankAccountNumberSync(String ident) {
        Boolean isSynced = true;
        Set<Integer> successCodes = new Set<Integer>{ 200, 201, 202, 203, 204 };
        LoggerUtility logger = new LoggerUtility('KRP Bank Sync');

        try {
            HttpResponse resp = krpService.getBankAccount(ident);
            Integer statusCode = resp.getStatusCode();
            if (successCodes.contains(statusCode)) {
                if (String.isNotBlank(resp.getBody())) {
                    KRP_Konto accountInfo = (KRP_Konto) JSON.deserialize(resp.getBody(), KRP_Konto.class);
                    updatePersonBankAccount(ident, accountInfo);
                }
            } else {
                isSynced = false;
                logger.httpError('Error from KRP', resp, null, domain);
            }
        } catch (Exception e) {
            isSynced = false;
            logger.exception(e, domain);
        } finally {
            logger.publish();
        }

        return isSynced;
    }

    /**
     * @description Updates a person record with account info from KRP
     * @param ident
     * @param accountInfo
     */
    private static void updatePersonBankAccount(String ident, KRP_Konto accountInfo) {
        Person__c person = getPerson(ident);
        person.INT_BankAccountNumber__c = accountInfo.kontonummer;
        if (String.isNotBlank(accountInfo.gyldigFom))
            person.INT_BankAccountNumberLastModified__c = Datetime.valueOf(accountInfo.gyldigFom.replace('T', ' '))
                .date();
        update person;
    }

    /**
     * @description Query person based on ident and filter out any tombstones
     * @param ident
     * @return  `Person__c`
     */
    private static Person__c getPerson(String ident) {
        return [SELECT Id FROM Person__c WHERE Name = :ident AND INT_IsHasTombstone__c = FALSE LIMIT 1];
    }
}
