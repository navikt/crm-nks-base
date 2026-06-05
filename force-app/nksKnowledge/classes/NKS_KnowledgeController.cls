public with sharing class NKS_KnowledgeController {
    private static LoggerUtility logger = new LoggerUtility('Knowledge Broken Links Report');
    private static Map<String, String> fieldLabelsCache = new Map<String, String>(); // Cache field labels (Store previously retrieved field labels to optimize performance)
    private static Pattern compiledRegexPattern;

    /**
     * @description Function to get links which will be checked in Knowledge articles
     * @author Sara Mohammadi | 11. April 2023
     * @return List<String> links
     */
    private static List<String> getLinksToBeChecked() {
        List<String> links = new List<String>();
        try {
            // Query the NamedCredential object to retrieve the named credentials
            for (NamedCredential nc : [SELECT MasterLabel FROM NamedCredential WHERE DeveloperName LIKE 'knowledge%']) {
                links.add(nc.MasterLabel);
            }
        } catch (Exception ex) {
            logger.error(
                'Problem getting links (NamedCredentials) to be checked: ' +
                    ex.getMessage() +
                    '\n' +
                    ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                null
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
    private static String getFieldLabel(String fieldName) {
        if (fieldLabelsCache.containsKey(fieldName)) {
            return fieldLabelsCache.get(fieldName);
        }

        String objectName = 'Knowledge__kav';
        if (Type.forName(objectName) != null) {
            Schema.DescribeSObjectResult describeResult;
            try {
                List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(
                    new List<String>{ 'Knowledge__kav' },
                    SObjectDescribeOptions.DEFERRED
                );
                describeResult = describes[0];
            } catch (InvalidParameterValueException ipve) {
                describeResult = null;
            }
            Map<String, Schema.SObjectField> fieldsMap = describeResult?.fields.getMap();

            if (fieldsMap?.containsKey(fieldName)) {
                String label = fieldsMap.get(fieldName).getDescribe().getLabel();
                fieldLabelsCache.put(fieldName, label);
                return label;
            }
        }
        return fieldName;
    }

    /**
     * @description Function to check if matched urls are valid urls
     * @author Sara Mohammadi | 11. April 2023
     * @param String matched url
     * @param String link
     * @return Boolean True if url is valid, False otherwise
     */
    private static Boolean validateMatchedUrl(String matchedUrl, String link) {
        Integer index = matchedUrl.indexOf(link);
        /**
         * List of desired indices (Some urls include a link not at the start but in the middle. All these urls are matched when finding urls in an article while it is not necessary to check all of them.
         * This will help to reduce http-calls and prevent to reach call-out limits)
         */
        List<Integer> desiredIndices = new List<Integer>{ 7, 8, 11, 12 };
        return desiredIndices.contains(index);
    }

    /**
     * @description Function to find links per field
     * @author Sara Mohammadi | 11. April 2023
     * @param Map<String, String> map to be checked
     * @return Map<String, List<String>> list of links per field
     */
    private static Map<String, List<String>> findLinksPerField(
        Map<String, Object> fieldsToValue,
        Pattern linksPattern
    ) {
        Map<String, List<String>> matches = new Map<String, List<String>>();
        try {
            for (String fieldName : fieldsToValue.keySet()) {
                String fieldValue = String.valueOf(fieldsToValue.get(fieldName));
                if (fieldValue != null) {
                    String fieldLabel = getFieldLabel(fieldName);
                    List<String> matchesPerField = findMatchesInField(linksPattern, fieldValue);

                    if (!matchesPerField.isEmpty()) {
                        matches.put(fieldLabel, matchesPerField);
                    }
                }
            }
        } catch (Exception ex) {
            logger.error(
                'Problem finding links per field: ' + ex.getMessage() + '\n' + ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                null
            );
        }
        return matches;
    }

    private static List<String> findMatchesInField(Pattern linksPattern, String fieldValue) {
        List<String> matchesPerField = new List<String>();
        Matcher matcher = linksPattern.matcher(normalizeFieldValue(fieldValue));

        // Loop through all matches found in the field value
        while (matcher.find()) {
            String groupValue = matcher.group(); // Get the matched value
            if (!matchesPerField.contains(groupValue) && groupValue.toLowerCase().startsWith('http')) {
                if (groupValue.endsWith('.')) {
                    groupValue = groupValue.substring(0, groupValue.length() - 1);
                }
                matchesPerField.add(groupValue);
            }
        }
        return matchesPerField;
    }

    // Normalize the field value by replacing characters
    private static String normalizeFieldValue(String fieldValue) {
        return fieldValue.replace('ø', 'o').replace('æ', 'ae').replace('å', 'a').replace('"', '');
    }

    /**
     * @description Function to find dead links
     *  @author Sara Mohammadi | 11. April 2023
     * @param Map<String, List<String>> list of links per field
     * @return Map<String, List<String>> list of dead links per field
     */
    private static Map<String, List<String>> findBrokenLinks(
        Map<String, List<String>> mapToCheck,
        List<String> linksToBeChecked
    ) {
        Map<String, List<String>> resultList = new Map<String, List<String>>();

        for (String field : mapToCheck.keySet()) {
            List<String> linksToCheck = mapToCheck.get(field);
            List<String> deadLinks = new List<String>();

            for (String str : linksToCheck) {
                // Loop through each link in the list of links to be checked
                for (String link : linksToBeChecked) {
                    if (str.contains(link) && validateMatchedUrl(str, link)) {
                        String endpoint =
                            'callout:knowledge_' +
                            link.replaceAll('[-.]', '_') +
                            str.substringAfter(link);
                        HttpRequest req = new HttpRequest();
                        req.setEndpoint(endpoint);
                        req.setMethod('GET');

                        try {
                            HttpResponse res = new Http().send(req);

                            // Found broken link
                            if (res.getStatusCode() >= 400) {
                                deadLinks.add(str);
                            }
                        } catch (Exception ex) {
                            logger.error(
                                'Problem sending HTTP-request: ' + ex.getMessage() + '\n' + ex.getStackTraceString(),
                                null,
                                CRM_ApplicationDomain.Domain.NKS,
                                null
                            );
                        } finally {
                            Integer remainingCalls = Limits.getLimitCallouts() - Limits.getCallouts(); // Check callout limits
                            if (remainingCalls <= 0) {
                                break;
                            }
                        }
                    }
                }
            }
            if (!deadLinks.isEmpty()) {
                resultList.put(field, deadLinks);
            }
        }
        return resultList;
    }

    public static void setCompiledRegexPattern() {
        String regex = '(https?://[\\w\\-._~:/?#\\[\\]@!$&\'()*+,;=%]+|www\\.[\\w\\-._~:/?#\\[\\]@!$&\'()*+,;=%]+|[\\w\\-]+\\.[a-z]{2,6}\\b[\\w\\-._~:/?#\\[\\]@!$&\'()*+,;=%]*)';
        compiledRegexPattern = Pattern.compile(regex);
    }

    public static Pattern getCompiledRegexPattern() {
        return compiledRegexPattern;
    }

    /**
     * @description Function to find dead links in a Knowledge article
     * @author Sara Mohammadi | 11. April 2023
     * @param Knowledge__kav article
     * @return Map<String, List<String>> list of dead links per field for input article
     */
    public static Map<String, List<String>> getBrokenLinks(Knowledge__kav article, Pattern linksPattern) {
        List<String> linksToBeChecked = getLinksToBeChecked();
        Map<String, List<String>> mapToReturn = new Map<String, List<String>>();
        Map<String, Object> fieldsToValue = article.getPopulatedFieldsAsMap(); // Retrieve all populated fields (which are stored in memory of the article object)
        Map<String, List<String>> matches = findLinksPerField(fieldsToValue, linksPattern);

        try {
            if (!matches.isEmpty()) {
                mapToReturn = findBrokenLinks(matches, linksToBeChecked);
            }
        } catch (Exception ex) {
            logger.error(
                'Problem getting broken links for article ' +
                    article.Id +
                    ': ' +
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
        return mapToReturn;
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
        mail.setSenderDisplayName('Døde lenker i kunnskapsbasen');
        mail.setSubject('Rapport om døde lenker');
        mail.setBccSender(false);
        mail.setUseSignature(false);

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
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

        if (results[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
            System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
        }
    }
}
