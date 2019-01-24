({
	doInit : function(component, event, helper) {
        helper.setOperatorAsPerTransactionField(component, event);
        
        helper.validateAddButton(component, event);
        helper.fillFilterVlaueOnLoad(component);
    },
    AddFilterRow : function(component, event, helper){
        var allFilters = component.get('v.filtersInOBJECT');
        allFilters.push({});
        component.set('v.filtersInOBJECT',allFilters);
    },
    onchange : function(component, event,helper){
        helper.onchange(component, event);
    },
    removeFilter : function(component, event,helper){
        helper.removeFilter(component, event);
	},
    save : function(component, event,helper){
        var callSave = component.getEvent('callSave');
        callSave.fire();
    }
})