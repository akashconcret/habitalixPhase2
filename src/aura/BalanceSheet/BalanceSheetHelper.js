({
	doInit : function(component, event, sizeOfRecords) {
        var action = component.get("c.getRecords");
        console.log('sizeOfRecords::'+sizeOfRecords);
        console.log(component.get('v.getMonth'));
        action.setParams({ 'sizeOfRecords' : sizeOfRecords,'monthNumber' : component.get('v.getMonth')});
         action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Accounting", response.getReturnValue());
                console.log(response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
       // this.showMonths(component, event);
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
    }
})