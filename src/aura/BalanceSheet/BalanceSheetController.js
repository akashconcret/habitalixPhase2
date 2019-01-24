({
    doInit : function(component, event, helper) {
        helper.showMonths(component,event);
        
        console.log(component.get('v.showEntry'));
        helper.doInit(component, event,component.get('v.showEntry'));
        
    },
    
    recordSize: function(component, event, helper){
        var sizeOfRecords = component.find("select").get("v.value");
        helper.doInit(component, event,sizeOfRecords);	
    },
    
    onMonthChange : function (component, event, helper) {
        //helper.showMonths(component,event);
    }
})