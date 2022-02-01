global class NKS_ChatTranscriptService {
    //INITIATE INTERNAL MAP OF NAV IDENT --> User ID
    @testVisible
    private static Map<String, Id> navIdentUserMap {
        get {
            if (navIdentUserMap == null) {
                navIdentUserMap = new Map<String, Id>();
                for (User usr : [
                    SELECT Id, CRM_NAV_Ident__c
                    FROM User
                    WHERE
                        Id IN (
                            SELECT AssigneeId
                            FROM PermissionSetAssignment
                            WHERE PermissionSetGroup.DeveloperName = 'Kontaktsenter'
                        )
                ]) {
                    navIdentUserMap.put(usr.CRM_NAV_Ident__c, usr.Id);
                }
            }
            return navIdentUserMap;
        }
        private set {
        }
    }

    private static LoggerUtility logger = new LoggerUtility();
    /**
     * @description: Handles storing the chat conversation directly to solve issue
     * with omni channel delayed transcript body generation
     * @author Stian Ruud Schikora | 10-27-2020
     * @param chatId
     * @param jsonConversation
     **/
    @AuraEnabled
    public static void storeConversation(String chatId, String jsonConversation) {
        List<Message> messageList = (List<Message>) JSON.deserialize(jsonConversation, List<Message>.class);
        messageList.sort();
        LiveChatTranscript chatTranscript = getChatDetails(chatId);
        if (chatTranscript.NKS_Thread__c == null)
            return; //If no thread is created the session was not authenticated and the messages cannot be related to end users
        List<Message__c> threadMessages = new List<Message__c>();

        if (
            // Compare last message timestamp from thread to handle issues with multiple EndEvents
            chatTranscript.NKS_Last_Message_Datetime__c ==
            Datetime.newInstance(Long.valueOf(messageList[messageList.size() - 1].timestamp))
        ) {
            return; //Chat ended event is sent multiple times, handle not performing unnecesary DML
        }

        try {
            threadMessages = converToThreadMessages(messageList, chatTranscript);
            insert threadMessages;
        } catch (Exception ex) {
            logger.exception(ex, CRM_ApplicationDomain.Domain.NKS);
            logger.publish();
        }
    }

    private static List<Message__c> converToThreadMessages(
        List<Message> wrapperMessages,
        LiveChatTranscript chatTrans
    ) {
        List<Message__c> returnMessages = new List<Message__c>();
        returnMessages.add(createAuthEventMessage(chatTrans));
        for (Message msg : wrapperMessages) {
            returnMessages.add(convertToThreadMessage(msg, chatTrans));
        }

        return returnMessages;
    }

    private static Message__c createAuthEventMessage(LiveChatTranscript chatTrans) {
        //How should we handle auth message with language?
        String authText = chatTrans.LiveChatButton?.WindowLanguage == 'en_US'
            ? 'Started authenticated chat: '
            : 'Startet innlogget chat: ';
        return new Message__c(
            CRM_Thread__c = chatTrans.NKS_Thread__c,
            CRM_Type__c = 'Event',
            CRM_Sent_date__c = chatTrans.NKS_Authentication_Timestamp__c,
            CRM_Message_Text__c = authText
        );
    }

    /**
     * @description: Converts a message wrapper from the LiveAgent API to a Message__c record
     * @author Stian Ruud Schikora | 01-31-2022
     * @param wrapperMessages
     * @param chatTrans
     * @return List<Message__c>
     **/
    private static Message__c convertToThreadMessage(Message wrapperMessage, LiveChatTranscript chatTrans) {
        Message__c convertedMessage = new Message__c();
        convertedMessage.CRM_Thread__c = chatTrans.NKS_Thread__c;
        convertedMessage.CRM_Message_Text__c = wrapperMessage.content;
        convertedMessage.CRM_Type__c = wrapperMessage.getThreadMessageType();
        convertedMessage.CRM_Sent_date__c = DateTime.newInstance(Long.valueOf(wrapperMessage.timestamp));
        if (wrapperMessage.isAgentMessage()) {
            //Agent name is designed to include the NAV ident in parenthesis i.e. (<NAV_IDENT>)
            String navIdent = wrapperMessage.name.substringBetween('(', ')');
            if (!navIdentUserMap.containsKey(navIdent)) {
                logger.error('Could not find user record for agent', chatTrans, CRM_ApplicationDomain.Domain.NKS);
            } else {
                convertedMessage.CRM_From_User__c = navIdentUserMap.get(navIdent);
            }
        } else {
            convertedMessage.CRM_From_Contact__c = chatTrans.ContactId;
        }

        return convertedMessage;
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
        String conversationText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US' ? 'Conversation' : 'Samtale';

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
        String conversationText = chatTranscript.LiveChatButton?.WindowLanguage == 'en_US' ? 'Conversation' : 'Samtale';
        String returnText = '<div style="text-align: center">';
        returnText += '<p align="center"><b>' + conversationText + ' - Frida</b></p>';
        returnText += '</div><br>';
        String message;

        String botConversation = chatTranscript.Case.Description;

        //For long conversations string.split() has a chance to encounter regex exceptions. Using custom iterator instead
        BotConversation_Iterator conversationIterator = new BotConversation_Iterator(botConversation);
        while (conversationIterator.hasNext()) {
            message = '<p>' + conversationIterator.next().replaceAll('\r', '<br>').replaceAll('\n', '') + '</p>';
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
                AccountId,
                ContactId,
                NKS_Last_Message_Datetime__c,
                NKS_Thread__c,
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

    global class Message implements Comparable {
        private String content;
        public String name;
        private String recordId;
        private String timestamp;
        private String type;

        global Integer compareTo(Object compareTo) {
            Message curMessage = (Message) compareTo;
            Long thisTimestamp = Long.valueOf(timestamp);
            Long curTimestamp = Long.valueOf(curMessage.timestamp);

            if (thisTimestamp < curTimestamp) {
                return -1;
            }
            if (thisTimestamp > curTimestamp) {
                return 1;
            }
            return 0;
        }

        /**
         * @description: Method to translate the live agent message type to the Message__c types
         * @author Stian Ruud Schikora | 01-31-2022
         * @return String
         **/
        public String getThreadMessageType() {
            return type.equalsIgnoreCase('OperatorTransferred') ? 'Event' : 'Message';
        }

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
                String transferText = language == 'en_US' ? 'Transferred to {to}' : 'Overført til {to}';
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
