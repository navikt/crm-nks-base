//Service class for retrieving payments for a person
public without sharing class NKS_PaymentService {
    private static final String BASE_CONFIG = 'UTBETALING_API';

    public static HttpResponse getPayments(String ident, DateTime startDate, DateTime endDate) {
        ApiController apiCtrl = new ApiController();
        String serviceName = 'GET_PERSON_UTBETALINGER';

        Map<String, String> paramMap = new Map<String, String>{ 'fnr' => ident };
        Map<String, String> queryParams = new Map<String, String>{
            'sluttdato' => endDate.format('yyyy-MM-dd'),
            'startdato' => startDate.format('yyyy-MM-dd')
        };
        apiCtrl.initRequest(BASE_CONFIG, serviceName, paramMap);
        apiCtrl.addServiceAuthHeader('Utbetaling');
        apiCtrl.setUrlParams(queryParams);
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }
}
