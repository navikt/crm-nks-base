({
    handleChatEnded: function (component, event, helper) {
        const chatToolkit = component.find("chatToolkit");
        const recordId = component.get("v.recordId");
        const eventRecordId = event.getParam('recordId');

        //Record if from chatEnded event is 15 chars
        let thisChatEnded = recordId.substring(0, 15).localeCompare(eventRecordId.substring(0, 15)) === 0 ? true : false;
        if (thisChatEnded === true) {
            chatToolkit.getChatLog({
                recordId: recordId
            })
                .then(result => {
                    let conversation = result.messages;
                    let filteredConversation = conversation.filter(function (message, index, arr) {
                        //Filtering out all messages of type supervisor as these are "whispers" and should not be added to the journal
                        return message.type !== 'Supervisor';
                    });

                    helper.callStoreConversation(component, filteredConversation);
                })
                .catch(error => {
                    //Errors require manual handling.
                });
        }
    }
})
