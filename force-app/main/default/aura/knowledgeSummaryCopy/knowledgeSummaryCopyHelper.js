({
    addToClipBoard: function (component, text) {
        var hiddenInput = document.createElement('input');
        hiddenInput.value = text;
        document.body.appendChild(hiddenInput);
        hiddenInput.focus();
        hiddenInput.select();

        try {
            document.execCommand('copy');
            this.displayToast('Success', 'success', 'Sammendraget er kopiert til utklippstavle');
        } catch (error) {
            this.displayToast('Error', 'error', 'Kunne ikke kopiere sammendrag');
            console.log('Copy failed: ' + JSON.stringify(error));
        } finally {
            document.body.removeChild(hiddenInput);
            this.closeQuickActionPanel();
        }
    },

    displayToast: function (title, type, message) {
        // Display a toast message
        var resultsToast = $A.get('e.force:showToast');
        resultsToast.setParams({
            type: type,
            title: title,
            message: message
        });
        resultsToast.fire();
    },

    closeQuickActionPanel: function () {
        var dismissActionPanel = $A.get('e.force:closeQuickAction');
        dismissActionPanel.fire();
    }
});
