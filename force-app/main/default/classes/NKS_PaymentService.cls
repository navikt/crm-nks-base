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
            'startdato' => Date.today().format(),
            'sluttdato' => Date.today().addYears(-3).format()
        };
        apiCtrl.initRequest(BASE_CONFIG, serviceName, paramMap);
        apiCtrl.addServiceAuthHeader(serviceName);
        apiCtrl.setUrlParams(queryParams);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            //Success
            returnList = (List<NKS_Utbetaling>) JSON.deserialize(
                apiCtrl.getResponse().getBody(),
                List<NKS_Utbetaling>.class
            );
            returnList.sort(); //Sorts the entries by posteringsdato
            System.debug('SORTED LIST: ' + JSON.serializePretty(returnList));
        } else {
            //Error handling
        }

        return returnList;
    }
}
