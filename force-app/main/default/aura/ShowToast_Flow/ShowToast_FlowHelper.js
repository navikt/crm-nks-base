({
	  //Standard Show Toast Event
    showToast : function(type, title, message, duration, mode, key) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": duration,
            "mode": mode,
            "key": key
        });
        toastEvent.fire();
    },


    //Show Toast Event updated to include a message that contains a link
    showToastUrl : function(type, title, messageUrl, urlLink, urlLabel, duration, mode, key) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": messageUrl,
            "messageTemplate": messageUrl,
            "messageTemplateData": ['Salesforce', {
                url: urlLink,
                label: urlLabel,
            }],
            "type": type,
            "duration": duration,
            "mode": mode,
            "key": key
        });
        toastEvent.fire();
    }
})