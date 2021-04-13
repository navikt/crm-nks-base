//Service class for retrieving payments for a person
public without sharing class NKS_PaymentService {
    private static final String BASE_CONFIG = 'UTBETALING_API';

    @AuraEnabled(cacheable=true)
    public static List<NKS_Utbetaling> getPayments(String ident) {
        ApiController apiCtrl = new ApiController();
        List<NKS_Utbetaling> returnList = new List<NKS_Utbetaling>();
        String serviceName = 'GET_PERSON_UTBETALINGER';

        Map<String, String> paramMap = new Map<String, String>{ 'fnr' => ident };
        Map<String, String> queryParams = new Map<String, String>{
            'sluttdato' => DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0))
                .format('yyyy-MM-dd'),
            'startdato' => DateTime.newInstance(
                    Date.today().addYears(-3),
                    Time.newInstance(0, 0, 0, 0)
                )
                .format('yyyy-MM-dd')
        };
        apiCtrl.initRequest(BASE_CONFIG, serviceName, paramMap);
        apiCtrl.addServiceAuthHeader('Utbetaling');
        apiCtrl.setUrlParams(queryParams);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            //Success
            returnList = (List<NKS_Utbetaling>) JSON.deserialize(
                apiCtrl.getResponse().getBody(),
                List<NKS_Utbetaling>.class
            );
            returnList.sort(); //Sorts the entries by utbetalingsdato
        } else {
            //Error handling
            LoggerUtility logger = new LoggerUtility('Utbetaling');
            logger.httpError(
                'Error retrieving person payments',
                apiCtrl.getResponse(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            AuraHandledException auraEx = new AuraHandledException(logger.peek().UUID__c);
            auraEx.setMessage(logger.peek().UUID__c);
            logger.publish();
            throw auraEx;
        }

        return returnList;
    }
}
