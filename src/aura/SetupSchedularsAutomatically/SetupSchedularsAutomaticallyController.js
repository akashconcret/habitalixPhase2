({
	onchange : function(component, event, helper) {
        if(component.get('v.selectedBatch')!='choose one...' && component.get('v.PrefferedTime') == 'Right Now'){
            component.set('v.Schedule',true); 
            component.set('v.PrefferedDayNotShow',true);
            component.set('v.PrefferedDay','choose one...');
        }else if(component.get('v.selectedBatch')!='choose one...' && component.get('v.PrefferedTime')!='choose one...'  && component.get('v.PrefferedDay')!='choose one...'){
            component.set('v.Schedule',true);
        }else if(component.get('v.PrefferedTime') != 'Right Now'){
            component.set('v.PrefferedDayNotShow',false);
            component.set('v.Schedule',false);
        }
	},
    schedule : function(component, event, helper) {
        helper.schedule(component, event);
    }
})