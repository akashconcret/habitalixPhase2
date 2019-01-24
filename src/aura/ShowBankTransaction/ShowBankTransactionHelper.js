({
	displayTransactions : function(component,event) {
        var action = component.get("c.returnBankTransactions");
        var getInputkeyWord = component.get("v.SearchKeyWordForTransaction");
        var eliminateTransactions = [];
        if(getInputkeyWord!=undefined && getInputkeyWord.length > 0){
            action.setParams({
                'keyword': getInputkeyWord,
                'transactionBankAccount' : component.get("v.linkedRentBuildingBankAccoutn"), 
                //'rentAmmount' : component.get("v.relatedRent"),
                'numberOfMonthForTransaction' : component.get("v.getMonth"),
                'numberOfrecords' : component.get("v.numberOfrecords")
            });
        }else{
            action.setParams({
                'keyword': '',
                'transactionBankAccount' : component.get("v.linkedRentBuildingBankAccoutn"), 
                //'rentAmmount' : component.get("v.relatedRent"),
                'numberOfMonthForTransaction' : component.get("v.getMonth"),
                'numberOfrecords' : component.get("v.numberOfrecords")
            });
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                console.log('storeResponse :: '+storeResponse);
                // if storeResponse size is equal 0 ,display No Records Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.MessageForTransactions", 'No Transaction Found...');
                } else {
                    component.set("v.MessageForTransactions", '');
                }
                component.set('v.showSpinner',false);
                component.set("v.listOfTransactions", storeResponse); 
                //this.selectTransaction(component, event);
            }else{
                console.log('error');
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
	},
    getMonths : function(component,event) {
        component.set("v.mappedRentWithTransaction",{})
        var monthNumber = new Date().getMonth();
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
    selectTransaction : function(component,event) {
        var selectedTransactionsForRent = [];
        var currentSelectedTransactionForRent = {};
        var allTransactionCheckBoxes = component.find("actionCheckBox"); 
        var allEditedTransactionAmount = component.find("actionInput");
        var selectedTransaction = event.getSource();//event.target.id;
        var foundSelectedTransactions = false;
        var selectedAmountToLink = 0.00;
        var allTransac = component.get("v.listOfTransactions");
        var i=0;
        
        for(i=0;i<component.get("v.listOfTransactions").length;i++){
            if(allTransactionCheckBoxes.length != undefined && allEditedTransactionAmount.length != undefined && allTransactionCheckBoxes != undefined && allEditedTransactionAmount!=undefined){
                allTransactionCheckBoxes[i].set('v.disabled',false);
                if(allTransactionCheckBoxes[i].get('v.checked')==true){
                    
                    selectedAmountToLink+=parseFloat(allEditedTransactionAmount[i].get('v.value'));
                    if(this.validateEditedAmount(component,event,allEditedTransactionAmount[i],selectedAmountToLink,component.get("v.RemainingAmount")*(-1))){
                        allTransactionCheckBoxes[i].set('v.disabled',false);
                        foundSelectedTransactions = true;
                        currentSelectedTransactionForRent['Name'] = allTransac[i].transactionRecord.Name;
                        currentSelectedTransactionForRent['Id'] = allEditedTransactionAmount[i].get('v.name');//selectedTransaction.get('v.name');
                        currentSelectedTransactionForRent['Amount'] = allEditedTransactionAmount[i].get('v.value');
                        selectedTransactionsForRent.push(currentSelectedTransactionForRent);
                        currentSelectedTransactionForRent = {};
                        
                    }else{
                        allTransactionCheckBoxes[i].set('v.disabled',true);
                        allTransactionCheckBoxes[i].set('v.checked',false);
                    }
                }
            }else if(allTransactionCheckBoxes.length == undefined && allTransactionCheckBoxes.length == undefined){
                allTransactionCheckBoxes.set('v.disabled',false);
                if(allTransactionCheckBoxes.get('v.checked')==true){
                    selectedAmountToLink+=parseFloat(allEditedTransactionAmount[i].get('v.value'));
                    if(this.validateEditedAmount(component,event,allEditedTransactionAmount,selectedAmountToLink,component.get("v.RemainingAmount")*(-1))){
                        allTransactionCheckBoxes.set('v.disabled',false);
                        foundSelectedTransactions = true;
                        currentSelectedTransactionForRent['Name'] = allTransac[i].transactionRecord.Name;
                        currentSelectedTransactionForRent['Id'] = allEditedTransactionAmount.get('v.name');//selectedTransaction.get('v.name');
                        currentSelectedTransactionForRent['Amount'] = allEditedTransactionAmount.get('v.value');
                        selectedTransactionsForRent.push(currentSelectedTransactionForRent);
                        currentSelectedTransactionForRent = {};
                    }else{
                        allTransactionCheckBoxes.set('v.disabled',true);
                        allTransactionCheckBoxes.set('v.checked',false);
                    }
                }
            }
            console.log('selectedAmountToLink :: '+selectedAmountToLink);
            /*if(selectedAmountToLink>0 && selectedAmountToLink>component.get("v.RemainingAmount")*(-1)){
                	allTransactionCheckBoxes[i].set('v.disabled',true);
                    allTransactionCheckBoxes[i].set('v.checked',false);
                	selectedTransactionsForRent = [];
                	foundSelectedTransactions = false;
                	selectedAmountToLink-=allEditedTransactionAmount[i].get('v.value');
                	this.showInfoToast(component,event);
                	break;
            }*/
        }
        i=0;
        
        var transactionsGroupByRentId = component.getEvent("transactionsForManualMapping");
        if(foundSelectedTransactions){
            transactionsGroupByRentId.setParams({
                "rentId" : component.get("v.relatedRentId"),"transactionDetail":selectedTransactionsForRent,"deleteKey":false});
        }else{
            transactionsGroupByRentId.setParams({
                "rentId" : component.get("v.relatedRentId"),"transactionDetail":selectedTransactionsForRent,"deleteKey":true});
        }
        transactionsGroupByRentId.fire();
    },
    validateEditedAmount : function(component,event,transactionEditedAmount,selectedAmountToLink,remainingAmount) {
        console.log('RemainingAmount :: '+remainingAmount);
        console.log('test :: '+selectedAmountToLink>remainingAmount);
        var maxAmount = transactionEditedAmount.get('v.max');
        var givenAmount = transactionEditedAmount.get('v.value');
        console.log('maxAmount . '+maxAmount+' .givenAmount '+givenAmount);
        if(selectedAmountToLink>0 && selectedAmountToLink>remainingAmount){
            component.set('v.isTransactionAmountValidated',false);
            this.showInfoToast(component,event);
            return false;
        }
        if(givenAmount==0){
            component.set('v.isTransactionAmountValidated',true);
            return true;
        }else if(givenAmount=='' ){ // || givenAmount == 0
            component.set('v.isTransactionAmountValidated',false);
            return false;
        }
        if(givenAmount>maxAmount){
            component.set('v.isTransactionAmountValidated',false);
            return false;
        }else{
            component.set('v.isTransactionAmountValidated',true);
            return true;
        }
    },
    showInfoToast : function(component, event) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error Message',
            message: 'You Have Selected More Than Invoive/Invoice Remaining Amount',
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    }
})