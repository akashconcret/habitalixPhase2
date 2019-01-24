({
	showInfoToast : function(component, event,response) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success Message',
            message: response,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    schedule : function(component, event) {
        var action = component.get("c.scheduleBatch");
        action.setParams({'batchName':component.get('v.selectedBatch'),'prefferedTime':component.get('v.PrefferedTime'),'prefferedDay':component.get('v.PrefferedDay')});
        action.setCallback(this, function(data) {
            console.log(data.getState());
            if(data.getState()=='SUCCESS') {
                this.showInfoToast(component, event,data.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})