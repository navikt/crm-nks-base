public with sharing class NKS_SendNavTaskHandler {
    @AuraEnabled
    public static Boolean invokeSendNavTaskFlow(NavTask__c navTask) {
        Map<String, Object> resultMap = new Map<String, Object>();
        Boolean res = false;
        try {   
            Map<String, Object> flowInputs = new Map<String, Object>{
                'NAV_Task' => navTask, 
                'Created_By_Unit_Number' => getCurrentUserDepartment()
            };

            Flow.Interview flowInv = Flow.Interview.createInterview('CRM_Send_NAV_Task_Auto', flowInputs); 
            flowInv.start();
            
            res = (Boolean)flowInv.getVariableValue('SUCCESSFUL_POST');

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserDepartment() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Department FROM User WHERE Id = :currentUserId LIMIT 1];
        return currentUser.Department;
    }

    @AuraEnabled
    public static string getProcessingId(Id recordId){
        try {
            return [SELECT Id, NKS_Henvendelse_BehandlingsId__c FROM Case WHERE Id = :recordId LIMIT 1].NKS_Henvendelse_BehandlingsId__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
