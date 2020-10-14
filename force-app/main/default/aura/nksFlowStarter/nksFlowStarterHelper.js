({
    isLabelReference: function (component, buttonLabel) {
        let labelRef = $A.getReference("$Label.c." + buttonLabel);
        component.set("v.dynamicLabel", labelRef); //Using the dynamic label attribute to async parse label reference
        let parsedLabel = component.get("v.dynamicLabel");

        return parsedLabel.length !== 0;
    }
})
