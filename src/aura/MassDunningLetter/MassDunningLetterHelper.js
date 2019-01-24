({
	getContractIdsForDunningProcess : function(component,event) {
		var allDunningRecords = component.get('v.getDunningRecordsForCurrentMonth');
        var i=0;
        var contactIds = [];
        for(i=0;i<allDunningRecords.length;i++){
            contactIds.push(allDunningRecords[i].contractId);
        }
        if(contactIds.length>0){
            component.set('v.contractsIds',contactIds);
        }
	},
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
    }
})