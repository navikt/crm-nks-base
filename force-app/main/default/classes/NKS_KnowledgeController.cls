public with sharing class NKS_KnowledgeController {
    private static LoggerUtility logger = new LoggerUtility('Knowledge Broken Links Report');
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

    public static Map<String, List<String>> getBrokenLinks(Knowledge__kav article) {
        // get label for Knowledge fields
        String type = 'Knowledge__kav';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

        // regex/pattern to find links in a string
        String regex1 = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        Pattern linksPattern = Pattern.compile(regex1);

        Map<String, List<String>> matches = new Map<String, List<String>>();
        Map<String, List<String>> returnedMap = new Map<String, List<String>>();

        // get all text fields for each article
        Map<String, String> strMap = new Map<String, String>();
        strMap.put('AdvisorInformation__c', article.AdvisorInformation__c);
        strMap.put('AdvisorInformationInternal__c', article.AdvisorInformationInternal__c);
        strMap.put('Article__c', article.Article__c);
        strMap.put('EmployerInformation__c', article.EmployerInformation__c);
        strMap.put('EmployerInformationInternal__c', article.EmployerInformationInternal__c);
        strMap.put('NKS_English__c', article.NKS_English__c);
        strMap.put('InternationalInformation__c', article.InternationalInformation__c);
        strMap.put('InternationalInformationInternal__c', article.InternationalInformationInternal__c);
        strMap.put('NKS_Legislation__c', article.NKS_Legislation__c);
        strMap.put('NKS_Nav_no__c', article.NKS_Nav_no__c);
        strMap.put('NKS_Nynorsk__c', article.NKS_Nynorsk__c);
        strMap.put('NKS_Resources__c', article.NKS_Resources__c);
        strMap.put('NKS_Summary__c', article.NKS_Summary__c);
        strMap.put('NKS_UserInformation__c', article.NKS_UserInformation__c);
        strMap.put('WhoDoesWhat__c', article.WhoDoesWhat__c);

        try {
            for (String field : strMap.keySet()) {
                String fieldValue = strMap.get(field);
                if (fieldValue != null) {
                    String fieldLabel = fieldMap.get(field).getDescribe().getLabel();
                    List<String> matchesPerField = new List<String>();
                    Matcher matcher = linksPattern.matcher(
                        fieldValue.replaceAll('ø', 'o').replaceAll('æ', 'ae').replaceAll('å', 'a')
                    );
                    while (matcher.find()) {
                        String groupValue = matcher.group();
                        if (!matchesPerField.contains(groupValue)) {
                            matchesPerField.add(groupValue);
                        }
                    }
                    if (matchesPerField.size() > 0) {
                        matches.put(fieldLabel, matchesPerField);
                    }
                }
            }
            if (matches.size() > 0) {
                returnedMap = findBrokenLinks(matches);
                if (Limits.getCallouts() > Limits.getLimitCallouts()) {
                    logger.error(
                        'Callout limit has exceeded for article ' +
                        article.Id +
                        '\n',
                        null,
                        CRM_ApplicationDomain.Domain.NKS,
                        null
                    );
                }
            }
        } catch (Exception ex) {
            logger.error(
                'Problem finding broken links for article ' +
                article.Id +
                '\n' +
                ex.getMessage() +
                '\n' +
                ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                null
            );
        } finally {
            logger.publish();
        }
        return returnedMap;
    }

    @TestVisible
    private static Map<String, List<String>> findBrokenLinks(Map<String, List<String>> mapToCheck) {
        Map<String, List<String>> resultList = new Map<String, List<String>>();
        for (String field : mapToCheck.keySet()) {
            List<String> linksToCheck = mapToCheck.get(field);
            List<String> deadLinks = new List<String>();
            for (String str : linksToCheck) {
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
                            if (statusCode == 404) {
                                deadLinks.add(str);
                            }
                        } catch (Exception ex) {
                            //System.debug('It is possbile this link is broken, check the link.');
                        }
                    }
                }
            }
            if (deadLinks.size() > 0) {
                resultList.put(field, deadLinks);
            }
        }
        return resultList;
    }

    @TestVisible
    private static Integer detectRedirect(HttpRequest req, HttpResponse res) {
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

    public static void sendEmail(
        Map<String, Map<String, List<String>>> listToSend,
        List<String> toAddresses,
        List<String> bccAddresses
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(toAddresses);
        mail.setBccAddresses(bccAddresses);
        mail.setSenderDisplayName('Døde lenker i kunnskapsbasen');
        mail.setSubject('Rapport om døde lenker');
        mail.setBccSender(false);
        mail.setUseSignature(false);

        // Specify the text content of the email.
        String body = '';
        for (String title : listToSend.keySet()) {
            Map<String, List<String>> fields = listToSend.get(title);
            body += 'Artikkel: "' + title + '" har døde lenker i følgende felter:<br/>';
            for (String field : fields.keySet()) {
                List<String> links = fields.get(field);
                body += field + ':<br/>';
                for (String link : links) {
                    body += link + '<br/>';
                }
            }
            body += '<br/>';
        }
        mail.setHtmlBody(body);
        try {
            // Send the email you have created.
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception ex) {
            System.debug('Problem sending email: ' + ex.getMessage());
        }
    }
}
