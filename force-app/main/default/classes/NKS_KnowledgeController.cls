public with sharing class NKS_KnowledgeController {
    private static LoggerUtility logger = new LoggerUtility('Knowledge Broken Links Report'); // Create logger to log errors while finding dead links

    /**
     * @description Function to get links which will be checked in Knowledge articles
     * @author Sara Mohammadi | 11. April 2023
     * @return List<String> links
     */
    @TestVisible
    private static List<String> getLinksToBeChecked() {
        Set<String> domains = new Set<String>{ '%_no', '%_com', '%_org' };
        List<String> links = new List<String>();
        try {
            // Query the NamedCredential object to retrieve the named credentials
            for (NamedCredential nc : [SELECT MasterLabel FROM NamedCredential WHERE DeveloperName LIKE :domains]) {
                links.add(nc.MasterLabel);
            }
        } catch (Exception ex) {
            System.debug(
                'An error occurred on function getLinksToBeChecked() in NKS_KnowledgeController Class: ' +
                ex.getMessage()
            );
        }
        return links;
    }

    /**
     * @description Function to get label for the specified field of Knowledge object
     * @author Sara Mohammadi | 11. April 2023
     * @param String field name
     * @return String  field label
     */
    @TestVisible
    private static String getFieldLabel(String fieldName) {
        String objectName = 'Knowledge__kav'; // Specify the object name for which you want to retrieve field labels
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe(); // Get the SObject Describe result for the specified object
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap(); // Get the fields map for the object
        return fieldsMap.get(fieldName).getDescribe().getLabel(); // return field label
    }

    /**
     * @description Function to check if matched urls are valid urls
     * @author Sara Mohammadi | 11. April 2023
     * @param String matched url
     * @param String link
     * @return Boolean True if url is valid, False otherwise
     */
    @TestVisible
    private static Boolean validateMatchedUrl(String matchedUrl, String link) {
        Integer index = matchedUrl.indexOf(link);
        Integer[] desiredIndices = new List<Integer>{ 8, 9, 12, 13 }; // List of desired indices
        return desiredIndices.contains(index);
    }

    /**
     * @description Function to find links per field
     * @author Sara Mohammadi | 11. April 2023
     * @param Map<String, String> map to be checked
     * @return Map<String, List<String>> list of links per field
     */
    @TestVisible
    private static Map<String, List<String>> findLinksPerField(Map<String, Object> fieldsToValue) {
        // String regex = '(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&/=]*)';
        String regex = '(http|https)://[\\w\\.-]+(/[\\w\\.-]+)*'; // regex/pattern to find links in a string
        Pattern linksPattern = Pattern.compile(regex);
        Map<String, List<String>> matches = new Map<String, List<String>>();
        try {
            for (String fieldName : fieldsToValue.keySet()) {
                // Loop through each field in the input map
                String fieldValue = String.valueOf(fieldsToValue.get(fieldName)); // Get the value of the field

                if (fieldValue != null) {
                    String fieldLabel = getFieldLabel(fieldName); // Get the field label
                    List<String> matchesPerField = new List<String>();
                    Matcher matcher = linksPattern.matcher(
                        fieldValue.replaceAll('[ø]', 'o').replaceAll('[æ]', 'ae').replaceAll('[å]', 'a')
                    );
                    while (matcher.find()) {
                        // Loop through all matches found in the field value
                        String groupValue = matcher.group(); // Get the matched value

                        if (!matchesPerField.contains(groupValue)) {
                            // Add the matched value to the list if not already present
                            matchesPerField.add(groupValue);
                        }
                    }
                    if (!matchesPerField.isEmpty()) {
                        // Check if matches are found for the field
                        matches.put(fieldLabel, matchesPerField); // Add the field label and its matches to the result map
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(
                'An error occurred on function findLinksPerField() in NKS_KnowledgeController Class: ' + ex.getMessage()
            );
        }
        System.debug('Fined links: ' + matches);
        return matches;
    }

    /**
     * @description Function to find dead links
     *  @author Sara Mohammadi | 11. April 2023
     * @param Map<String, List<String>> list of links per field
     * @return Map<String, List<String>> list of dead links per field
     */
    @TestVisible
    private static Map<String, List<String>> findBrokenLinks(Map<String, List<String>> mapToCheck) {
        Map<String, List<String>> resultList = new Map<String, List<String>>(); // Map to return
        for (String field : mapToCheck.keySet()) {
            List<String> linksToCheck = mapToCheck.get(field);
            List<String> deadLinks = new List<String>();
            for (String str : linksToCheck) {
                for (String link : getLinksToBeChecked()) {
                    // Loop through each link in the list of links to be checked
                    if (str.contains(link) && validateMatchedUrl(str, link)) {
                        // feil fordi lenken kan være i midten av string; sjekk hvis lenken kommer etter https
                        String endpoint = 'callout:' + link.replace('.', '_') + str.substringAfter(link); // Endpoint for the HTTP request
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint(endpoint);
                        req.setMethod('GET');
                        try {
                            HttpResponse res = new Http().send(req); // Send the HTTP request
                            if (res.getStatusCode() >= 400) {
                                // Check if the response status code indicates a broken link
                                deadLinks.add(str);
                            }
                        } catch (System.CalloutException ex) {
                            // Catch and handle callout exception
                            logger.error(
                                'Callout exception: ' +
                                ex.getMessage() +
                                '\n' +
                                ex.getStackTraceString(),
                                null,
                                CRM_ApplicationDomain.Domain.NKS,
                                null
                            );
                        } catch (Exception ex) {
                            // Catch and handle general exception
                            logger.error(
                                'Problem finding broken links: ' +
                                ex.getMessage() +
                                '\n' +
                                ex.getStackTraceString(),
                                null,
                                CRM_ApplicationDomain.Domain.NKS,
                                null
                            );
                        } finally {
                            Integer remainingCalls = 0;
                            if (Test.isRunningTest()) {
                                remainingCalls = -1;
                            }
                            if (!Test.isRunningTest()) {
                                remainingCalls = Limits.getLimitCallouts() - Limits.getCallouts(); // Check callout limits
                            }
                            if (remainingCalls <= 0) {
                                logger.error(
                                    'Callout limit has exceeded: ',
                                    null,
                                    CRM_ApplicationDomain.Domain.NKS,
                                    null
                                );
                            }
                        }
                    }
                }
            }
            if (deadLinks.size() > 0) {
                resultList.put(field, deadLinks);
            }
        }
        System.debug('Result list of dead links: ' + resultList);
        return resultList;
    }

    /**
     * @description Function to find dead links in a Knowledge article
     * @author Sara Mohammadi | 11. April 2023
     * @param Knowledge__kav article
     * @return Map<String, List<String>> list of dead links per field for input article
     */
    public static Map<String, List<String>> getBrokenLinks(Knowledge__kav article) {
        Map<String, List<String>> returnedMap = new Map<String, List<String>>(); // Map to return
        Map<String, Object> fieldsToValue = article.getPopulatedFieldsAsMap(); // Retrieve all populated fields (which are stored in memory of the article object)
        Map<String, List<String>> matches = findLinksPerField(fieldsToValue); // Find links per field in the article

        try {
            if (matches.size() > 0) {
                returnedMap = findBrokenLinks(matches); // Find dead links per field in the article
            }
        } catch (Exception ex) {
            System.debug('Problem getting broken links for article ' + article.Id + ': ' + ex.getMessage());
        } finally {
            logger.publish();
        }
        System.debug('Returned map for article ' + article.Id + ': ' + returnedMap);
        return returnedMap;
    }

    /**
     * @description Function to send email
     * @author Sara Mohammadi | 11. April 2023
     * @param Map<String, Map<String, List<String>>> list of links per field
     * @param List<String> toAddresses
     * @param List<String> bccAddresses
     */
    public static void sendEmail(
        Map<String, Map<String, List<String>>> listToSend,
        List<String> toAddresses,
        List<String> bccAddresses
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Set the recipient(s) of the email
        mail.setToAddresses(toAddresses);
        mail.setBccAddresses(bccAddresses);
        mail.setSenderDisplayName('Døde lenker i kunnskapsbasen'); // Set the sender of the email
        mail.setSubject('Rapport om døde lenker'); // Set the subject of the email
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
        mail.setHtmlBody(body); // Set the body of the email
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }); // Send the email

        // Check if the email was sent successfully
        if (results[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
            System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
        }
    }

    /*
    @TestVisible
    private static Integer detectRedirect(HttpRequest req, HttpResponse res) {
        String loc = res.getHeader('Location');
        if (loc != null) {
            req = new HttpRequest();
            req.setEndpoint(loc);
            req.setMethod('HEAD');
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
        req.setMethod('HEAD');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    } */
}
