public with sharing class NKS_KnowledgeController {
    private static final List<String> LINKS = new List<String>{
        'afp.no',
        'akan.no',
        'altinn.no',
        'anskaffelser.no',
        'arbeidsmiljoportalen.no',
        'arbeidsplassen.no',
        'arbeidstilsynet.no',
        'behandlingshjelpemidler.no',
        'brreg.no',
        'bufdir.no',
        'deterdinpensjon.no',
        'doffin.no',
        'domstol.no',
        'ehelse.no',
        'eid.difi.no',
        'facebook.com',
        'garantikassen.no',
        'helfo.no',
        'helsedirektoratet.no',
        'helsenorge.no',
        'husbanken.no',
        'huseieren.no',
        'idebanken.org',
        'imdi.no',
        'jobbmesse.no',
        'karriereveiledning.no',
        'klp.no',
        'konkursradet.no',
        'lovdata.no',
        'nav.no',
        'nav.sabacloud.com',
        'norskpensjon.no',
        'politiet.no',
        'skatteetaten.no',
        'spk.no',
        'norge.no',
        'register.helsedirektoratet.no',
        'regjeringen.no',
        'udi.no',
        'utdanning.no',
        'veiviseren.no',
        'vilbli.no',
        'vimeo.com',
        'youtube.com'
    };

    public static List<String> findBrokenLinks(Knowledge__kav article) {
        String regex1 = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        Pattern linksPattern = Pattern.compile(regex1);
        Set<String> matches = new Set<String>();
        List<String> resultList = new List<String>();

        // get all text fields for each article
        List<String> strList = new List<String>{
            article.AdvisorInformation__c,
            article.AdvisorInformationInternal__c,
            article.Article__c,
            article.EmployerInformation__c,
            article.EmployerInformationInternal__c,
            article.NKS_English__c,
            article.InternationalInformation__c,
            article.InternationalInformationInternal__c,
            article.NKS_Legislation__c,
            article.NKS_Nav_no__c,
            article.NKS_Nynorsk__c,
            article.NKS_Resources__c,
            article.NKS_Summary__c,
            article.NKS_UserInformation__c,
            article.WhoDoesWhat__c
        };

        if (strList.size() > 0) {
            // find all links
            for (String str : strList) {
                try {
                    Matcher matcher = linksPattern.matcher(
                        str.replaceAll('ø', 'o').replaceAll('æ', 'ae').replaceAll('å', 'a')
                    );
                    while (matcher.find()) {
                        String groupValue = matcher.group();
                        matches.add(groupValue);
                    }
                } catch (Exception ex) {
                    //System.debug(ex.getMessage());
                }
            }
        }
        //System.debug('Matches: ' + matches);

        if (matches.size() > 0) {
            for (String str : matches) {
                if (Test.isRunningTest()) {
                    System.debug('Running tests.');
                } else {
                    for (String link : LINKS) {
                        if (str.contains(link)) {
                            String endpoint = 'callout:' + link.replace('.', '_') + str.substringAfter(link);
                            try {
                                HttpRequest req = new HttpRequest();
                                HttpResponse res = calloutHttpReq(req, endpoint);
                                Integer statusCode = res.getStatusCode();

                                if (statusCode.format().left(1) == '3') {
                                    statusCode = detectRedirect(req, res);
                                }
                                if (statusCode != 200 && statusCode != 500 && statusCode.format().left(1) != '3') {
                                    resultList.add(str);
                                }
                            } catch (Exception ex) {
                                //System.debug('It is possbile this link is broken, check the link.');
                            }
                        }
                    }
                }
            }
        }
        System.debug('Dead links: ' + resultList);
        return resultList;
    }

    @TestVisible
    private static Integer detectRedirect(HttpRequest req, HttpResponse res) {
        if (Test.isRunningTest()) {
            System.debug('Running tests.');
            return null;
        } else {
            String loc = res.getHeader('Location');
            if (loc != null) {
                req = new HttpRequest();
                req.setEndpoint(loc);
                req.setMethod('GET');
                Http http = new Http();
                res = http.send(req);
                if (res.getStatusCode() != 500) {
                    return res.getStatusCode();
                }
            }
        }
        return res.getStatusCode();
    }

    @TestVisible
    private static HttpResponse calloutHttpReq(HttpRequest req, String endpoint) {
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }
}
