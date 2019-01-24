({
    fetchRents : function(component, event, helper) {
    },
    navigateToRent : function (component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": event.target.id,
          "slideDevName": "related"
        });
        navEvt.fire();
    },
    showModal : function (component, event, helper) {
        var rentId = event.getSource().get('v.label');
        helper.getParticularRent(component, event,rentId);
        component.set("v.selectedRentId", event.getSource().get('v.label'));
        component.set("v.selectedRentBuildingBankAccount",event.getSource().get('v.name'));
        component.set("v.isOpen",true);
        component.set("v.SearchKeyWordForTransaction",'');
        component.set("v.listOfTransactions", null); 
        component.set("v.MessageForTransactions", '');
    },
    closeModal : function (component, event, helper) {
        component.set("v.isOpen",false);
        component.set("v.selectedRentId", '');
        component.set('v.particularRentDetail',null);
    },
    createAccounting : function (component, event, helper) {
    	helper.createAccounting(component, event);
    },
    showRents : function (component, event, helper) {
        component.set("v.showSpinner", true);
        helper.showMonths(component,event);
        helper.searchHelper(component,event,component.get('v.rentTypeFilter'));
    },
    onMonthChange : function (component, event, helper) {
        helper.searchHelper(component,event);
    },
    mapRentWithTransactions : function (component, event, helper) {
        helper.mapRentWithTransactions(component, event);
    },
    showLinkedTransactions : function (component, event, helper) {
        var rentId = event.target.id;
        helper.showLinkedTransactions(component, event,rentId,component.get('v.getMonth'));
        component.set('v.isOpenLinkedTransactionModal',true); //linkedTransactions
    },
    closeLinkedTransactions : function (component, event, helper) {
        component.set('v.isOpenLinkedTransactionModal',false);
        component.set('v.linkedTransactions',null);
    },
    rentTypeFilterChange : function(component,event,helper) {
        component.set("v.showSpinner", true);
        helper.searchHelper(component,event,component.get('v.rentTypeFilter'));
    },
    /*
    onSelectChange : function(component, event, helper) {
        console.log('select value',component.find("select").get("v.value"));
        var pageSize = component.find("select").get("v.value");
        var paginationList = []; 

        var oppList = component.get("v.rentDetails"); 

        for(var i=0; i< pageSize; i++) 

        { 

            paginationList.push(oppList[i]);   

        }            

        component.set('v.paginationList', paginationList); 

    },  
    }*/
})