({
    searchHelper : function(component,event,filterTypeValue) {
        // call the apex class method 
        var action = component.get("c.returnRents");
        // set param to method  
        var excludeitemsList = [];
        action.setParams({
            'monthNumber': component.get('v.getMonth'),'filterType':filterTypeValue,'recordToShow':component.get('v.showEntryies')
        });
        console.log(component.get('v.getMonth'));
        // set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                console.log('storeResponse :: '+JSON.stringify(storeResponse));
                // if storeResponse size is equal 0 ,display No Records Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Rent Found...');
                    component.set('v.showMonths',false);
                } else {
                    component.set("v.Message", '');
                    component.set('v.showMonths',true);
                }
                component.set("v.showSpinner", false);
                component.set("v.rentDetails", storeResponse); 
            }else{
                console.log('error');
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    },
    showInfoToast : function(component, event,storeResponse,type,messageType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : messageType,
            message: storeResponse,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();
    },
    mapRentWithTransactions : function(component, event) {
        var rentId = event.getParam("rentId");
        var transactionDetail = event.getParam("transactionDetail");
        var removeMapKey = event.getParam("deleteKey");;
        console.log('rentId :; '+rentId+' :: '+removeMapKey+' : '+removeMapKey);
        var mappedRentWithTransaction = {};
        if(removeMapKey){
            mappedRentWithTransaction = component.get('v.mappedRentWithTransactionParent');
            delete mappedRentWithTransaction[rentId];
            component.set('v.mappedRentWithTransactionParent',mappedRentWithTransaction);
        }else{
            mappedRentWithTransaction[rentId] = transactionDetail;
            component.set('v.mappedRentWithTransactionParent',mappedRentWithTransaction);
            
        }
        component.set("v.lengthOfSelectedTransaction",Object.keys(component.get("v.mappedRentWithTransactionParent")).length);
        console.log(JSON.stringify(mappedRentWithTransaction));
    },
    showMonths : function(component, event){
        var monthNumber = new Date().getMonth();
            console.log(monthNumber);
            var monthList = ["January", "February", "March", "April", "May", "June",
                              "July", "August", "September", "October", "November", "December"
                            ];
            var count = 0;
            var months = {};
            var monthsList = [];
            component.set('v.getMonth',monthNumber+1);
            for(monthNumber;count<3;monthNumber--){
                months['monthNumber'] = monthNumber+1;
                months['monthName'] = monthList[monthNumber];
                monthsList.push(months);
                months={};
                count++;
            }
            component.set('v.months',monthsList);
    },
    createAccounting : function (component, event){
        var action = component.get("c.mapRentAndTransaction");
        var getInputkeyWord = component.get('v.mappedRentWithTransactionParent');
        if(Object.keys(getInputkeyWord).length > 0){
            action.setParams({
                'mappingJSONForRentAndTransaction': JSON.stringify(getInputkeyWord)
            });
            action.setCallback(this, function(response) {
                console.log('Came ::'+' :: '+response.getReturnValue());
                //$A.util.removeClass(component.find("mySpinner"), "slds-show");
                var state = response.getState();
                console.log('state'+' :: '+state);
                if (state === "SUCCESS") {
                    
                    component.set("v.isOpen",false);
                    var storeResponse = response.getReturnValue();
                    if(storeResponse=='Invoice Mapped Successfully.'){
                        this.showInfoToast(component, event,storeResponse,'success','Success Message');
                    }else if(storeResponse=='No Accounting records found'){
                        this.showInfoToast(component, event,storeResponse,'info','Success Message');
                    }else{
                        this.showInfoToast(component, event,storeResponse,'error','Error Message');
                    }
                    
                    console.log('storeResponse :: '+storeResponse);
                    // if storeResponse size is equal 0 ,display No Records Found... message on screen.                }
                    if (storeResponse.length == 0) {
                        //component.set("v.MessageForTransactions", 'No Transaction Found...');
                    } else {
                        //component.set("v.MessageForTransactions", '');
                    }
                }else{
                    console.log('error');
                }
            });
            // enqueue the Action  
            $A.enqueueAction(action);
        }else{
            console.log('No Mapping Found');
        }
    },
    showLinkedTransactions : function(component, event,rentId,currentMonth){
        var action = component.get("c.returnAccountingRecords");
        
        action.setParams({
                'rentId': rentId,
            	'monthNumber' : currentMonth
            });
            action.setCallback(this, function(response) {
                console.log('Came ::'+' :: '+response.getReturnValue());
                //$A.util.removeClass(component.find("mySpinner"), "slds-show");
                var state = response.getState();
                console.log('state'+' :: '+state);
                if (state === "SUCCESS") {
                    var storeResponse = response.getReturnValue();
                    
                    console.log('storeResponse :: '+storeResponse);
                    // if storeResponse size is equal 0 ,display No Records Found... message on screen.                }
                    if (storeResponse.length == 0) {
                        component.set('v.linkedTransactions',null);
                        //component.set("v.MessageForTransactions", 'No Transaction Found...');
                    } else {
                        component.set('v.linkedTransactions',storeResponse);
                        //component.set("v.MessageForTransactions", '');
                    }
                }else{
                    console.log('error');
                }
            });
        $A.enqueueAction(action);
    },
    getParticularRent : function(component,event,rentId) {
        var allRents = component.get("v.rentDetails");
        var i=0;
        if(allRents.length>0){
            for(i=0;i<allRents.length;i++){
                if(allRents[i].rent.Id==rentId){
                    component.set('v.particularRentDetail',allRents[i]);
                }
            }
        }
    }
})