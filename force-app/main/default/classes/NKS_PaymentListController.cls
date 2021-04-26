public class NKS_PaymentListController {
    /**
     * @description: Calls utbetaling service to get payments made the last months for a user.
     * @author Stian Ruud Schikora | 04-13-2021
     * @param ident
     * @return List<NKS_Utbetaling>
     **/
    @AuraEnabled(cacheable=true)
    public static List<NKS_Utbetaling> getRecentPayments(String ident) {
        List<NKS_Utbetaling> returnList = new List<NKS_Utbetaling>();
        DateTime startDate = DateTime.newInstance(Date.today().addMonths(-1), Time.newInstance(0, 0, 0, 0));
        DateTime endDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));

        HttpResponse resp = NKS_PaymentService.getPayments(ident, startDate, endDate);

        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            //Success
            returnList = (List<NKS_Utbetaling>) JSON.deserialize(resp.getBody(), List<NKS_Utbetaling>.class);
            returnList.sort(); //Sorts the entries by utbetalingsdato
        } else {
            //Error handling
            handleError(resp);
        }

        return returnList;
    }

    /**
     * @description: Calls utbetaling service to get full payments history (last three years)
     * @author Stian Ruud Schikora | 04-13-2021
     * @param ident
     * @return List<NKS_Utbetaling>
     **/
    @AuraEnabled(cacheable=true)
    public static List<NKS_Utbetaling> getPaymentHistory(String ident) {
        List<NKS_Utbetaling> returnList = new List<NKS_Utbetaling>();
        DateTime startDate = DateTime.newInstance(Date.today().addYears(-3), Time.newInstance(0, 0, 0, 0));
        DateTime endDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));

        HttpResponse resp = NKS_PaymentService.getPayments(ident, startDate, endDate);

        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            //Success
            returnList = (List<NKS_Utbetaling>) JSON.deserialize(resp.getBody(), List<NKS_Utbetaling>.class);
            returnList.sort(); //Sorts the entries by utbetalingsdato
        } else {
            //Error handling
            handleError(resp);
        }

        return returnList;
    }

    /**
     * @description: If response code does not indicate success, log the response and thro AuraHandledException
     * @author Stian Ruud Schikora | 04-13-2021
     * @param resp
     **/
    private static void handleError(HttpResponse resp) {
        //Error handling
        LoggerUtility logger = new LoggerUtility('Utbetaling');
        logger.httpError('Error retrieving person payments', resp, null, CRM_ApplicationDomain.Domain.NKS);
        AuraHandledException auraEx = new AuraHandledException(logger.peek().UUID__c);
        auraEx.setMessage(logger.peek().UUID__c);
        logger.publish();
        throw auraEx;
    }
}
