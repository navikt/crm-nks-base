public class NKS_ChatTranscriptService {

    /**
    * @description: Handles storing the chat conversation directly to solve issue
    * with omni channel delayed transcript boyd generation
    * @author Stian Ruud Schikora | 10-27-2020 
    * @param chatId 
    * @param jsonConversation 
    **/
    @AuraEnabled
    public static void storeConversation(String chatId, String jsonConversation) {
        String conversation = '';
        List<Message> messageList = (List<Message>) JSON.deserialize(jsonConversation, List<Message>.class);
        DateTime chatStart = DateTime.newInstance(Long.valueOf(messageList[0].timestamp));
        DateTime chatEnd = DateTime.now(); //Method is called when endChat event is received
        LiveChatTranscript chatTranscript = getChatDetails(chatId);
        
        if(String.isNotBlank(chatTranscript.Case.Description)) { 
            conversation += formatBotConversation(chatTranscript.Case.Description);
        }
        conversation += generateConversationHeading(chatTranscript, chatStart, chatEnd);

        for (Message msg : messageList) {
            conversation += msg.getFormattedMsg();
        }

        update new LiveChatTranscript(Id = chatId, 	NKS_Conversation__c = conversation);
    }

    /**
    * @description: Generates the heading for the human chat part of the log
    * @author Stian Ruud Schikora | 10-30-2020 
    * @param chatTranscript 
    * @param chatStart 
    * @param chatEnd 
    * @return String 
    **/
    private static String generateConversationHeading(LiveChatTranscript chatTranscript, DateTime chatStart, DateTime chatEnd) {
        String heading = '<div style="text-align: center">';
        heading += '<p align="center">Samtale - Chat: ' + chatStart.format('dd/mm/yyyy') + ', ' + chatStart.format('hh:mm:ss') + ' - ' + chatEnd.format('hh:mm:ss') + '</p>';
        heading += '<p align="center">NAV-Veileder: ' + chatTranscript.Owner.Name + '</p><br>';
        heading += '</div>';
        return heading;
    }

    /**
    * @description: Appends conversation between frida ane end user to the log
    * @author Stian Ruud Schikora | 10-30-2020 
    * @param botConversation 
    * @return String 
    **/
    private static String formatBotConversation(String botConversation) {
        String returnText = '<div style="text-align: center">';
        returnText += '<p align="center">Samtale - Frida</p>';
        returnText += '</div><br>';

        //For long conversations string.split() has a chance to encounter regex exceptions. Using custom iterator instead
        BotConversation_Iterator conversationIterator = new BotConversation_Iterator(botConversation);
        while(conversationIterator.hasNext()) {
            returnText += '<p>' + conversationIterator.next() + '</p>';
        }

        returnText += '<br>';

        return returnText;
    }

    private static LiveChatTranscript getChatDetails(String chatId) {
        return [SELECT Owner.Name, Body, NKS_Conversation__c, Case.Description FROM LiveChatTranscript WHERE Id =: chatId];
    }

    private class Message{
        private String content;
        private String name;
        private String recordId;
        private String timestamp;
        private String type;

        private boolean isAgentMessage() {
            return type.equalsIgnoreCase('agent');
        }

        private string getMessageSource() {
            return isAgentMessage() ? 'Veileder' : 'Bruker';
        }
    
        public String getFormattedMsg() {
            String formattedMessage = '<div>';
            DateTime convertedTimestamp = DateTime.newInstance(Long.valueOf(timestamp));
            formattedMessage += '<p>' + '<b>' + getMessageSource() + ': ' +  '</b> - ' + convertedTimestamp.format('hh:mm:ss') + '</p>';
            formattedMessage += '<p>' + content.escapeXml() + '</p>'; //Escaping any xml tags sent by the end user in the chat
            formattedMessage += '</div><br>';

            return formattedMessage;
        }
    }

    private class BotConversation_Iterator implements Iterator<String> {
        
        private String conversation;
        private Integer messageIndex;
        private String message_rowDelimiter = '\n';
         
        public BotConversation_Iterator(String fileData){
           conversation = fileData;
           messageIndex = fileData.length(); 
        }
         
        public Boolean hasNext(){
           return messageIndex >= 0;
        }

        public String next(){     
           Integer key = conversation.lastIndexOf(message_rowDelimiter, messageIndex);
           if (key == -1)
             key = 0;
                  
           String row = conversation.subString(key, messageIndex);
           messageIndex = key - 1;
           return row;
        }
     
    }

}