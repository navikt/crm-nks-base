global without sharing class NKS_HenvendelseController {
    @InvocableMethod(
        label='Henvendelse Request'
        description='Posts the created conversation note to henvendelse'
        category='Henvendelse'
    )
    public static List<String> handleHenvendelseRequest(List<HenvendelseRequest> requests) {
        List<String> respList = new List<String>();
        for (HenvendelseRequest henvReq : requests) {
            switch on henvReq.requestType {
                when 'SEND' {
                    respList.add(
                        postToHenvendelse(
                            henvReq.personIdent,
                            henvReq.navUnitNumber,
                            henvReq.themeGroupCode,
                            henvReq.content
                        )
                    );
                }
                when 'JOURNAL' {
                    respList.add(
                        henvendelseJournalInit(
                            henvReq.behandlingskjedeId,
                            henvReq.navUnitNumber,
                            henvReq.navCaseId,
                            henvReq.themeCode
                        )
                    );
                }
                when else {
                    //UNDEFINED REQUEST TYPE
                }
            }
        }
        return respList;
    }

    /**
     * @description: Posts a conversation note to henvendelse and returns the unique BehandlingsID
     * on success. Throws AuraHandledException if the request fails.
     * @author Stian Ruud Schikora | 05-13-2021
     * @param personIdent
     * @param navUnitNumber
     * @param themeGroupCode
     * @param content
     * @return String
     **/
    private static String postToHenvendelse(
        String personIdent,
        String navUnitNumber,
        String themeGroupCode,
        String content
    ) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        HttpResponse resp = service.sendHenvendelse(personIdent, navUnitNumber, themeGroupCode, content);

        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            return Test.isRunningTest() ? UTIL_TestDataFactory.generateRandomString(10) : resp.getBody();
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Henvendelse post failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return '';
        }
    }

    /**
     * @description : Posts a behandlingsId for journal initiation to henvendelse
     * Throws AuraEnabledException if request status indicates post failure.
     * @author Stian Ruud Schikora | 05-13-2021
     * @param behandlingskjedeId
     * @param navUnitNumber
     * @param navCaseId
     * @param themeCode
     **/
    private static String henvendelseJournalInit(
        String behandlingskjedeId,
        String navUnitNumber,
        String navCaseId,
        String themeCode
    ) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        HttpResponse resp = service.createHenvendelseJournal(behandlingskjedeId, navUnitNumber, navCaseId, themeCode);
        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
            return 'OK';
        } else {
            LoggerUtility logger = new LoggerUtility('Henvendelse');
            logger.httpError('Henvendelse journal failed', resp, null, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
            return 'ERROR';
        }
    }

    //###########################################################//
    //###############     WRAPPER CLASSES      ##################//
    //###########################################################//

    public class HenvendelseRequest {
        @invocableVariable(label='Request Type (SEND or JOURNAL)' required=true)
        public String requestType;
        @invocableVariable(label='Person Identifier (FNR)')
        public String personIdent;
        @invocableVariable(label='Journal NAV Unit')
        public String navUnitNumber;
        @invocableVariable(label='Theme group code')
        public String themeGroupCode;
        @invocableVariable(label='Theme code')
        public String themeCode;
        @invocableVariable(label='NAV Case ID')
        public String navCaseId;
        @invocableVariable(label='BehandlingskjedeID')
        public String behandlingskjedeId;
        @invocableVariable(label='Free text conversation note')
        public String content;

        public HenvendelseRequest() {
        }

        public HenvendelseRequest(
            String requestType,
            String personIdent,
            String navUnitNumber,
            String themeGroupCode,
            String themeCode,
            String navCaseId,
            String behandlingskjedeId,
            String content
        ) {
            this.requestType = requestType;
            this.personIdent = personIdent;
            this.navUnitNumber = navUnitNumber;
            this.themeGroupCode = themeGroupCode;
            this.themeCode = themeCode;
            this.navCaseId = navCaseId;
            this.behandlingskjedeId = behandlingskjedeId;
            this.content = content;
        }
    }
}
