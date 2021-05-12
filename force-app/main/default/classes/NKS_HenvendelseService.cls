public without sharing class NKS_HenvendelseService {
    public enum HENVENDELSE_TYPES {
        SVAR,
        REFERAT_TELEFON,
        SPORSMAL
    }

    public enum HENVENDELSE_STATUSES {
        FERDIG,
        UNDER_ARBEID,
        AVBRUTT_AV_BRUKER,
        AVBRUTT_AUTOMATISK
    }
    private LoggerUtility logger = new LoggerUtility();

    /**
     * @description
     * @author Stian Ruud Schikora | 05-10-2021
     * @param personIdent : Person identifier (FNR)
     * @param types : List of henvendelse types to query
     * @param statuses : List of henvendelse statuses to include in result
     * @return HttpResponse
     **/
    public HttpResponse getPersonHenvendelser(
        String personIdent,
        List<HENVENDELSE_TYPES> types,
        List<HENVENDELSE_STATUSES> statuses
    ) {
        ApiController apiCtrl = new ApiController();
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };
        //Generate string list for types to be added as query parameters
        List<String> typeList = new List<String>();
        for (HENVENDELSE_TYPES type : types) {
            typeList.add(type.name());
        }
        Map<String, String> queryParams = new Map<String, String>{
            'fodselsnummer' => personIdent,
            'typer' => String.join(typeList, ',')
        };

        apiCtrl.initRequest('HENVENDELSE_API', 'GET_HENVENDELSER');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.addServiceAuthHeader('Henvendelse');
        addXCorrelationId('X-Correlation created for henvendelselist GET', apiCtrl, this.logger);
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    /**
     * @description
     * @author Stian Ruud Schikora | 05-10-2021
     * @param personIdent : Person identifier (FNR)
     * @param unitNumber : Unit number of user performing the request
     * @param themeGroupCode : Unique common code for theme group
     * @param content : Actual free text conversation note
     * @return HttpResponse
     **/
    public HttpResponse sendHenvendelse(
        String personIdent,
        String navUnitNumber,
        String themeGroupCode,
        String content
    ) {
        ApiController apiCtrl = new ApiController();
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };

        apiCtrl.initRequest('HENVENDELSE_API', 'POST_HENVENDELSE');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.addServiceAuthHeader('Henvendelse');
        addXCorrelationId('X-Correlation created for henvendelse POST', apiCtrl, this.logger);
        apiCtrl.setBody(
            JSON.serialize(new SendHenvendelseRequest(personIdent, navUnitNumber, content, themeGroupCode))
        );

        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * @description : Sends the conversation note for journal entry initiation
     * @author Stian Ruud Schikora | 05-11-2021
     * @param behandlingskjedeId
     * @param journalNavUnit
     * @param navCaseId
     * @param themeCode
     * @return HttpResponse
     **/
    public HttpResponse createHenvendelseJournal(
        String behandlingskjedeId,
        String journalNavUnit,
        String navCaseId,
        String themeCode
    ) {
        ApiController apiCtrl = new ApiController();
        Map<String, String> httpHeaders = new Map<String, String>{
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        };

        apiCtrl.initRequest('HENVENDELSE_API', 'POST_HENVENDELSE');
        apiCtrl.setHeaders(httpHeaders);
        apiCtrl.addServiceAuthHeader('Henvendelse');
        addXCorrelationId('X-Correlation created for henvendelse journal initiation', apiCtrl, this.logger);
        apiCtrl.setBody(
            JSON.serialize(new JournalHenvendelseRequest(behandlingskjedeId, journalNavUnit, navCaseId, themeCode))
        );

        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    /**
     * @description: Adds a unique X-Correlation header to an outbound request.
     * @author Stian Ruud Schikora | 05-10-2021
     * @param message
     * @param apiCtrl
     * @param logger
     **/
    private void addXCorrelationId(String message, ApiController apiCtrl, LoggerUtility logger) {
        logger.info(message + '\n' + apiCtrl.getEndpoint(), null);
        apiCtrl.addHeader('X-Correlation-ID', logger.peek().UUID__c); //Adds the unique app log id to the request
    }

    private class JournalHenvendelseRequest {
        String behandlingskjedeId;
        String journalforendeEnhet;
        String saksId;
        String temakode;

        private JournalHenvendelseRequest(
            String behandlingskjedeId,
            String journalforendeEnhet,
            String saksId,
            String temakode
        ) {
            this.behandlingskjedeId = behandlingskjedeId;
            this.journalforendeEnhet = journalforendeEnhet;
            this.saksId = saksId;
            this.temakode = temakode;
        }
    }

    private class SendHenvendelseRequest {
        private String fnr;
        private String enhet;
        private String fritekst;
        private String temagruppe;
        private String kanal = 'TELEFON'; //Hardkoded for temporary solution as all posts will be phone notes

        private SendHenvendelseRequest(String fnr, String enhet, String fritekst, String temagruppe) {
            this.fnr = fnr;
            this.enhet = enhet;
            this.fritekst = fritekst;
            this.temagruppe = temagruppe;
        }
    }
}
