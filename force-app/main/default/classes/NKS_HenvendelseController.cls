public without sharing class NKS_HenvendelseController {
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
                    henvendelseJournalInit(
                        henvReq.behandlingskjedeId,
                        henvReq.navUnitNumber,
                        henvReq.navCaseId,
                        henvReq.themeCode
                    );
                }
                when else {
                    //UNDEFINED REQUEST TYPE
                }
            }
        }
        return respList;
    }

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
            return resp.getBody();
        } else {
            return null;
        }
    }

    private static void henvendelseJournalInit(
        String behandlingskjedeId,
        String navUnitNumber,
        String navCaseId,
        String themeCode
    ) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();

        HttpResponse resp = service.createHenvendelseJournal(behandlingskjedeId, navUnitNumber, navCaseId, themeCode);
        Integer statusCode = resp.getStatusCode();
        if (statusCode == 200 || statusCode == 201) {
        } else {
        }
    }

    public static void doHenvendelseSynch(String personIdent) {
        NKS_HenvendelseService service = new NKS_HenvendelseService();
        List<NKS_HenvendelseService.HENVENDELSE_TYPES> henvTypes = new List<NKS_HenvendelseService.HENVENDELSE_TYPES>();
        henvTypes.add(NKS_HenvendelseService.HENVENDELSE_TYPES.REFERAT_TELEFON);

        HttpResponse resp = service.getPersonHenvendelser(
            personIdent,
            henvTypes,
            NKS_HenvendelseService.HENVENDELSE_STATUSES.values()
        );
    }

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
