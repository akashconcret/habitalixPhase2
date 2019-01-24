({
    onfocus : function (component, event, helper){
    },
    doInit : function (component, event, helper){
        helper.getMonths(component, event);
        helper.displayTransactions(component, event);
    },
    onblur : function (component, event, helper) {
        	component.set("v.listOfTransactions", null); 
            component.set("v.MessageForTransactions", '');
    },
    onMonthChange : function (component, event, helper) { 
        //helper.displayTransactions(component, event);
    },  
    OnNumberOfRecordsChange : function (component, event, helper) {
        component.set('v.showSpinner',true);
        helper.displayTransactions(component, event);
    },
	transactionsBySearch : function (component, event, helper) {
        helper.displayTransactions(component, event);
    },
    selectTransaction : function (component, event, helper) {
        helper.selectTransaction(component, event);
    },
    navigateToTransaction : function (component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": event.target.id,
          "slideDevName": "related"
        });
        navEvt.fire();
    },
})