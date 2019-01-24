({
	getAllFields : function(component){
        //debugger;
        var action = component.get("c.getRentTransactionFields");
        action.setCallback(this, function(data) {
            if(data.getState()=='SUCCESS') {
                var showAllFields = data.getReturnValue();
                //this.fillFilterVlaueOnLoad(component);
                console.log(showAllFields);
                component.set('v.showAllFields',showAllFields); 
                if(!(showAllFields.savedFilters == 'No Filter found')){
                 	component.set('v.AllFilters',JSON.parse(showAllFields.savedFilters));
                    component.set('v.filterLogic',JSON.parse(showAllFields.savedFilters)[0].filterLogic);
                }
            }
        });
        $A.enqueueAction(action);
    },
    save : function(component, event,helper){
        var action = component.get("c.saveFilters");
        action.setParams({'filters':JSON.stringify(component.get('v.AllFilters')),'filterLogic':component.get('v.filterLogic')});
        action.setCallback(this, function(data) {
            if(data.getState()=='SUCCESS') {
                helper.showInfoToast(component, event,data.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})