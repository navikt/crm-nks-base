public with sharing class TAG_FagsystemerArbeidsgiverController {

    @AuraEnabled(cacheable=true)
    public static String getAccount(String recordId) {
        try {
            String getAcc = String.ValueOf([SELECT Id FROM Account WHERE Id = :recordId].id);
            return getAcc;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    @AuraEnabled(cacheable=true)
    public static FagsoneIp checkFagsoneIpRange() {
        Map<String, String> currentSession = Auth.SessionManagement.getCurrentSession();
        String ip = currentSession.get('SourceIp');
        Boolean isInFagsone = Auth.SessionManagement.inOrgNetworkRange(ip);
        return new FagsoneIp(ip, isInFagsone);
    }

    public class FagsoneIp {
        @AuraEnabled
        public String ip;
        @AuraEnabled
        public Boolean isInFagsone;

        public FagsoneIp(String ip, Boolean isInFagsone) {
            this.ip = ip;
            this.isInFagsone = isInFagsone;
        }
    }*/
}