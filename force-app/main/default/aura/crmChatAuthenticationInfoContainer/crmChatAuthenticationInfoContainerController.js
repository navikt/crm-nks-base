({
    //Handles event from LWC to init the auth process using the conversation toolkit API
    requestAuthentication: function (component, event, helper) {
        const chatToolkit = component.find("chatToolkit");
        const recordId = component.get("v.recordId");

        chatToolkit.sendMessage({
            recordId: recordId,
            message: {
                text: "Init:Auth:" + recordId
            }
        })
            .then(function (result) {
                if (result) {
                    console.log("Successfully sent message");
                } else {
                    console.log("Failed to send message");
                }
            });
    },

    //Triggers a view refresh when receiving event from LWC
    triggerRefresh: function () {
        $A.get('e.force:refreshView').fire();
    }
})
