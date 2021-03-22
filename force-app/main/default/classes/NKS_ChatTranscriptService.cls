public class NKS_ChatTranscriptService {
    /**
     * @description: Handles storing the chat conversation directly to solve issue
     * with omni channel delayed transcript body generation
     * @author Stian Ruud Schikora | 10-27-2020
     * @param chatId
     * @param jsonConversation
     **/
    @AuraEnabled
    public static void storeConversation(String chatId, String jsonConversation) {
        String conversation = '';
        Boolean addedAuthSeparator = false;
        List<Message> messageList = (List<Message>) JSON.deserialize(
            jsonConversation,
            List<Message>.class
        );
        DateTime chatStart = DateTime.newInstance(Long.valueOf(messageList[0].timestamp));
        DateTime chatEnd = DateTime.now(); //Method is called when endChat event is received
        LiveChatTranscript chatTranscript = getChatDetails(chatId);
        DateTime authTimestamp = chatTranscript.NKS_Authentication_Timestamp__c;

        if (
            chatTranscript.NKS_Conversation_Stored__c == true ||
            chatTranscript.Case.NKS_Conversation_Stored__c == true
        ) {
            return; //Chat ended event is sent multiple times, handle not performing unnecesary DML
        }

        if (String.isNotBlank(chatTranscript.Case.Description)) {
            conversation += formatBotConversation(chatTranscript);
        }
        conversation += generateConversationHeading(chatTranscript, chatStart, chatEnd);

        for (Message msg : messageList) {
            //If the message timestamp exceeds the auth timestamp, then we add a separator to cleary separate the authenticated and unauthenticated conversation
            if (
                authTimestamp != null &&
                DateTime.newInstance(Long.valueOf(msg.timestamp)) > authTimestamp &&
                !addedAuthSeparator
            ) {
                String separatorText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US'
                    ? 'Started authenticated chat: '
                    : 'Startet innlogget chat: ';
                String counsellorText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US'
                    ? 'Counsellor'
                    : 'Veileder';

                conversation += '<div style="text-align: center">';
                conversation +=
                    '<p align="center"><b>' +
                    separatorText +
                    authTimestamp.format('dd/MM/yyyy') +
                    ' - ' +
                    authTimestamp.format('HH:mm:ss') +
                    '</b></p>';
                conversation +=
                    '<p align="center"><b>NAV-' +
                    counsellorText +
                    ': ' +
                    msg.name +
                    '</b></p><br>';
                conversation += '</div><br>';
                addedAuthSeparator = true;
            }
            conversation += msg.getFormattedMsg(chatTranscript.LiveChatButton?.WindowLanguage);
        }

        try {
            update new Case(
                Id = chatTranscript.CaseId,
                NKS_Conversation__c = conversation,
                NKS_Conversation_Stored__c = true
            );
        } catch (Exception ex) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(ex, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    /**
     * @description: Generates the heading for the human chat part of the log
     * @author Stian Ruud Schikora | 10-30-2020
     * @param chatTranscript
     * @param chatStart
     * @param chatEnd
     * @return String
     **/
    private static String generateConversationHeading(
        LiveChatTranscript chatTranscript,
        DateTime chatStart,
        DateTime chatEnd
    ) {
        String conversationText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US'
            ? 'Conversation'
            : 'Samtale';

        String heading = '<br><div style="text-align: center">';
        heading +=
            '<p align="center"><b>' +
            conversationText +
            ' - Chat: ' +
            chatStart.format('dd/MM/yyyy') +
            ', ' +
            chatStart.format('HH:mm:ss') +
            ' - ' +
            chatEnd.format('HH:mm:ss') +
            '</b></p>';
        heading += '</div><br>';
        return heading;
    }

    /**
     * @description: Appends conversation between frida ane end user to the log
     * @author Stian Ruud Schikora | 10-30-2020
     * @param botConversation
     * @return String
     **/
    private static String formatBotConversation(LiveChatTranscript chatTranscript) {
        String conversationText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US'
            ? 'Conversation'
            : 'Samtale';
        String returnText = '<div style="text-align: center">';
        returnText += '<p align="center"><b>' + conversationText + ' - Frida</b></p>';
        returnText += '</div><br>';
        String message;

        String botConversation = chatTranscript.Case.Description;

        //For long conversations string.split() has a chance to encounter regex exceptions. Using custom iterator instead
        BotConversation_Iterator conversationIterator = new BotConversation_Iterator(
            botConversation
        );
        while (conversationIterator.hasNext()) {
            message =
                '<p>' +
                conversationIterator.next().replaceAll('\r', '<br>').replaceAll('\n', '') +
                '</p>';
            if (!conversationIterator.hasNext()) {
                message = '<br>' + message;
            }
            returnText += message;
        }

        return returnText;
    }

    private static LiveChatTranscript getChatDetails(String chatId) {
        return [
            SELECT
                NKS_Agent_Greeting_Name__c,
                Body,
                NKS_Conversation__c,
                CaseId,
                Case.NKS_Conversation_Stored__c,
                Case.Description,
                NKS_Authentication_Timestamp__c,
                LiveChatButton.WindowLanguage,
                NKS_Conversation_Stored__c
            FROM LiveChatTranscript
            WHERE Id = :chatId
            FOR UPDATE
        ];
    }

    private class Message {
        private String content;
        public String name;
        private String recordId;
        private String timestamp;
        private String type;

        private boolean isAgentMessage() {
            return type.equalsIgnoreCase('agent');
        }

        private string getMessageSource(String language) {
            return isAgentMessage() ? name : language == 'en_US' ? 'You' : 'Du';
        }

        public String getFormattedMsg(String language) {
            //Log: NKS-246 Conversation store fails on contentless message i.e. on transfer
            if (String.isBlank(content)) {
                return '';
            }
            String formattedMessage;

            //Formatting a transfer message
            if (type.equalsIgnoreCase('OperatorTransferred')) {
                formattedMessage = '<div style="text-align: center">';
                DateTime convertedTimestamp = DateTime.newInstance(Long.valueOf(timestamp));
                String transferText = language == 'en_US'
                    ? 'Transferred to {to}'
                    : 'Overført til {to}';
                formattedMessage +=
                    '<p align="center"><b>' +
                    transferText.replace('{to}', name) +
                    ': ' +
                    '</b> - ' +
                    convertedTimestamp.format('HH:mm:ss') +
                    '</p>';
                formattedMessage += '</div><br>';
            } else {
                formattedMessage = '<div>';
                DateTime convertedTimestamp = DateTime.newInstance(Long.valueOf(timestamp));
                formattedMessage +=
                    '<p>' +
                    '<b>' +
                    getMessageSource(language) +
                    ': ' +
                    '</b> - ' +
                    convertedTimestamp.format('HH:mm:ss') +
                    '</p>';
                formattedMessage += '<p>' + content.escapeXml() + '</p>'; //Escaping any xml tags sent by the end user in the chat
                formattedMessage += '</div><br>';
            }

            return formattedMessage;
        }
    }

    private class BotConversation_Iterator implements Iterator<String> {
        private String conversation;
        private Integer messageIndex;
        private String message_rowDelimiter = '\r\n';

        public BotConversation_Iterator(String fileData) {
            conversation = fileData;
            messageIndex = fileData.length();
        }

        public Boolean hasNext() {
            return messageIndex >= 0;
        }

        public String next() {
            Integer key = conversation.lastIndexOf(message_rowDelimiter, messageIndex);
            if (key == -1)
                key = 0;

            String row = messageIndex == this.conversation.length()
                ? conversation.subString(key, messageIndex)
                : conversation.subString(key, messageIndex + 1);
            messageIndex = key - 1;
            return row;
        }
    }
}
