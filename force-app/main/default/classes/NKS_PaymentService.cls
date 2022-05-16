//Service class for retrieving payments for a person
public without sharing class NKS_PaymentService {
    private static final String BASE_CONFIG = 'UTBETALING_API';

    public static HttpResponse getPayments(String ident, DateTime startDate, DateTime endDate){
        ApiController apiCtrl = new ApiController();
        String serviceName = 'GET_PERSON_UTBETALINGER';
        apiCtrl.initRequest(BASE_CONFIG, serviceName);
        apiCtrl.setBody(new PaymentRequest(ident, startDate, endDate).getJSON());
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }
    class PaymentRequest {
        String ident;
        PaymenRequestRolle rolle;
        PaymentRequestPeriode periode;
        PaymentRequestPeriodetype periodetype;
        PaymentRequest(String ident, Date fom, Date tom){
            this(ident, fom, tom, PaymenRequestRolle.RETTIGHETSHAVER, PaymentRequestPeriodetype.UTBETALINGSPERIODE);
        }
        PaymentRequest(String ident, Date fom, Date tom, PaymenRequestRolle rolle, PaymentRequestPeriodetype periodetype){
            this.ident = ident;
            this.rolle = rolle;
            this.periode = new PaymentRequestPeriode(fom,tom);
            this.periodetype = periodetype;
        }
        String getJSON(){
           return System.JSON.serialize(this);
        }
    }
    class PaymentRequestPeriode{
        Date fom;
        Date tom;
        PaymentRequestPeriode(Date fom, Date tom){
            this.fom = fom;
            this.tom = tom;
        }
    }
    public enum PaymentRequestRolle{
        RETTIGHETSHAVER,
        UTBETALT_TIL
    }
    public enum PaymentRequestPeriodetype{
        UTBETALINGSPERIODE,
        YTELSESPERIODE
    }
}
