({
	getDunningRecordsOnload : function(component, event, helper) {
		var action = component.get("c.getDunningRecords");
        
         action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.getDunningRecordsForCurrentMonth", response.getReturnValue());
                console.log(response.getReturnValue());
                //helper.getContractIdsForDunningProcess(component, event);
            }
            else {
                console.log("Failed with state: " + state);
            }
             component.set('v.showSpinner',false);
        });
        $A.enqueueAction(action);
	},
    setContractsForDunningProcess : function(component, event, helper) {
         var action = component.get("c.createTaskForDunningProcess");
         var contractIds = component.get('v.contractsIds');
         
         if(Object.keys(component.get('v.dunningDetail')).length==0){
            action.setParams({'dunningDetail':''});
         }else{
            action.setParams({'dunningDetail':JSON.stringify(component.get('v.dunningDetail'))});
         }
         //action.setParams({'dunningDetail':contractIds});
         action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                //component.set("v.getDunningRecordsForCurrentMonth", response.getReturnValue());
                if(response.getReturnValue() == 'Success'){
                    helper.showInfoToast(component, event,'Tasks Created Successfully For Dunning Process');
                }else{
                    helper.showInfoToast(component, event,'SomeThing Went Wrong');
                    console.log('SomeThing Went Wrong');
                }
                console.log(response.getReturnValue());
            }else {
                console.log("Failed with state: " + state);
            }
         });
         $A.enqueueAction(action);
    },
    navigateToRent : function (component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": event.target.id,
          "slideDevName": "related"
        });
        navEvt.fire();
    },
    selectDunningRecords : function (component, event, helper) {
        var dunningDetail = component.get('v.dunningDetail');
        if(event.getSource().get('v.checked')){// key holds balance List Id.
            dunningDetail[event.getSource().get('v.value')] = event.getSource().get('v.name');
        }else{
            delete dunningDetail[event.getSource().get('v.value')];
        }
        component.set('v.dunningrecordsLength',Object.keys(dunningDetail).length);
        component.set('v.dunningDetail',dunningDetail);
        console.log('final : '+JSON.stringify(component.get('v.dunningDetail')));
    },
    selectAll : function (component, event, helper) {
        var allCheckBoxes = component.find('actionCheckBox');
        var dunningDetail = component.get('v.dunningDetail');
        var i=0;
        if(event.getSource().get('v.checked')){
            if(allCheckBoxes.length != undefined){
                for(i=0;i<allCheckBoxes.length;i++){
                    allCheckBoxes[i].set('v.checked',true);
                    dunningDetail[allCheckBoxes[i].get('v.value')] = allCheckBoxes[i].get('v.name');
                }
            }else{
                allCheckBoxes.set('v.checked',true);
                dunningDetail[allCheckBoxes.get('v.value')] = allCheckBoxes.get('v.name');
            }
        }else{
            if(allCheckBoxes.length != undefined){
                for(i=0;i<allCheckBoxes.length;i++){
                    allCheckBoxes[i].set('v.checked',false);
                }
            }else{
                allCheckBoxes.set('v.checked',false);
            }
            dunningDetail = {};
        }
        component.set('v.dunningrecordsLength',Object.keys(dunningDetail).length);
        component.set('v.dunningDetail',dunningDetail);
        console.log('final : '+JSON.stringify(component.get('v.dunningDetail')));
    }
})