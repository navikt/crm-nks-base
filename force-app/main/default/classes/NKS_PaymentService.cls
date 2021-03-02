//Service class for retrieving payments for a person
public without sharing class NKS_PaymentService {
    private static final String BASE_CONFIG = 'UTBETALING_API';

    @AuraEnabled(cacheable=true)
    public static List<NKS_Utbetaling> getPayments() {
        ApiController apiCtrl = new ApiController();
        List<NKS_Utbetaling> returnList = new List<NKS_Utbetaling>();
        String serviceName = 'GET_PERSON_UTBETALINGER';

        Map<String, String> paramMap = new Map<String, String>{ 'actorId' => 'SOMEID' };
        apiCtrl.initRequest(BASE_CONFIG, serviceName, paramMap);
        apiCtrl.addServiceAuthHeader(serviceName);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            //Success
            returnList = (List<NKS_Utbetaling>) JSON.deserialize(
                apiCtrl.getResponse().getBody(),
                List<NKS_Utbetaling>.class
            );
        } else {
            //Error handling
        }

        return returnList;
    }
}
