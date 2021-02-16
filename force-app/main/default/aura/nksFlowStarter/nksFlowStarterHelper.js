({
    isLabelReference: function (component, buttonLabel) {
        const refString = '$Label.c.' + buttonLabel;
        let labelRef = $A.getReference(refString);
        component.set('v.dynamicLabel', labelRef); //Using the dynamic label attribute to async parse label reference
        let parsedLabel = component.get('v.dynamicLabel');

        //Handles rendering in several tabs getReference() can return an empty string error for reference
        return parsedLabel.length !== 0 && !parsedLabel.includes(refString);
    }
});
