({
    callStoreConversation: function (component, conversation, recordId) {
        let storeAction = component.get("c.storeConversation");

        storeAction.setParams({
            chatId: recordId,
            jsonConversation: JSON.stringify(conversation)
        });

        storeAction.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                //Conversation stored successfully
            }
            else {
                //Error handling
            }
        });

        $A.enqueueAction(storeAction);
    }
})
