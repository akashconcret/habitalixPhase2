({
    fillFilterVlaueOnLoad : function(component){
		var allFilters = component.get('v.filtersInOBJECT');
        var rowNumber = component.get('v.rowNumber');
        var currentFilter = {};
        if(allFilters!=undefined && !(allFilters.length>0 && JSON.stringify(allFilters[rowNumber-1]) === JSON.stringify({}))){//rowNumber>component.get('v.TotlFilterRows').length
            var selectedFieldDataType = this.getOperatorAndRentFieldPerTransactionFields(component, event,allFilters[rowNumber-1].transactionField);
            console.log('datatypeValue :: '+component.get('v.operatorPerDataType'));
            component.set('v.transactionField',allFilters[rowNumber-1].transactionField);
            
            component.set('v.Operator',allFilters[rowNumber-1].operator);
			component.set('v.RentField',allFilters[rowNumber-1].rentField);
            
            currentFilter['operator'] = component.get('v.Operator');
            currentFilter['rentField'] = component.get('v.RentField');
            currentFilter['transactionField'] = component.get('v.transactionField');
            currentFilter['dataType'] = selectedFieldDataType;
            allFilters.splice(rowNumber-1,1,currentFilter);
        }else if(allFilters!=undefined && allFilters.length>0 && JSON.stringify(allFilters[rowNumber-1])==JSON.stringify({})){
            //choose one...
            component.set('v.transactionField','choose one...');
            component.set('v.Operator','choose one...');
			component.set('v.RentField','choose one...');
        }
	},
    validateAddButton : function(component, event){
        var rowNUmber = component.get('v.rowNumber');
        var allFilters = component.get('v.filtersInOBJECT');
        if(allFilters.length==1 && JSON.stringify(allFilters[rowNUmber-1]) === JSON.stringify({})){
            component.set('v.disabledRemoveButton',true);
            component.find('AddButton').set('v.disabled',true);
            //component.set('v.AllSetToSave',true);
        }else if(allFilters.length==1 && JSON.stringify(allFilters[rowNUmber-1]) != JSON.stringify({})){
            component.set('v.disabledRemoveButton',false);
            component.set('v.AllSetToSave',false);
            component.find('AddButton').set('v.disabled',false);
        }
        if(allFilters.length!=1 && JSON.stringify(allFilters[rowNUmber-1]) === JSON.stringify({})){
            component.find('AddButton').set('v.disabled',true);
            component.set('v.AllSetToSave',true);
        }else if(allFilters.length!=1 && rowNUmber==allFilters.length && JSON.stringify(allFilters[rowNUmber-1]) != JSON.stringify({})){
            component.find('AddButton').set('v.disabled',false);
            component.set('v.AllSetToSave',false);
            component.set('v.disabledRemoveButton',false);
        }
    },
    onchange : function(component, event){
        var transactionField = component.get('v.transactionField');
        var operator = component.get('v.Operator');
        var rentField = component.get('v.RentField');
        var rowNUmber = component.get('v.rowNumber');
        //var fieldType = component.get('v.filtersInOBJECT')[rowNUmber-1]['transactionFields'].dataType;
        var currentFilter = {};
        var allFilters = component.get('v.filtersInOBJECT');
        var selectedFieldDataType = this.getOperatorAndRentFieldPerTransactionFields(component, event,transactionField);
        console.log('dataType : '+selectedFieldDataType);
        if(!(transactionField=='choose one...' || operator=='choose one...' || rentField=='choose one...')){
            currentFilter['operator'] = operator;
            currentFilter['rentField'] = rentField;
            currentFilter['transactionField'] = transactionField;
            currentFilter['dataType'] = selectedFieldDataType;
            
            console.log(JSON.stringify(currentFilter));
            allFilters.splice(rowNUmber-1,1,currentFilter);
            component.set('v.filtersInOBJECT',allFilters);
            component.set('v.disabledAddButton',false);
        }
        console.log('log :: '+JSON.stringify(component.get('v.filtersInOBJECT')));
    },
    removeFilter : function(component, event){
        var rowNUmber = component.get('v.rowNumber');
        var allFilters = component.get('v.filtersInOBJECT');
        if(allFilters.length == 1){
            allFilters.splice(rowNUmber-1,1);
            allFilters.push({});
        }else{
            allFilters.splice(rowNUmber-1,1);
        }
        component.set('v.filtersInOBJECT',allFilters);
    },
    getOperatorAndRentFieldPerTransactionFields : function(component, event,transactionField){
        var allFields  = component.get('v.showAllFields');
        var rentFields  = [];
        var i=0;
        var datatype  = '';
        for(i=0;i<allFields.transactionFields.length;i++){
            if(allFields.transactionFields[i].field == transactionField){
                datatype = allFields.transactionFields[i].dataType;
                //console.log('dataType :: '+datatype);
                component.set('v.operatorPerDataType',component.get('v.OperatorAsPerFieldType')[datatype]);
                break;
            }
        }
        for(i=0;i<allFields.rentFields.length;i++){
            //console.log('dataType1 :: '+allFields.rentFields[i].dataType);
            if(allFields.rentFields[i].dataType == datatype){
                rentFields.push({'label':allFields.rentFields[i].label,'field':allFields.rentFields[i].field});
            }
        }
        component.set('v.rentFieldAsPerTransaction',rentFields);
        return datatype;
    },
    setOperatorAsPerTransactionField : function(component, event){
        var operatorAsPerFieldType ={};
        operatorAsPerFieldType['STRING'] = ['equals','not equals to','contains'];
        operatorAsPerFieldType['DATE'] = ['equals','not equals to','less than','greater than','less than equal to','greater than equal to'];
        operatorAsPerFieldType['DATETIME'] = ['equals','not equals to','less than','greater than','less than equal to','greater than equal to'];
        operatorAsPerFieldType['CURRENCY'] = ['equals','not equals to','less than','greater than','less than equal to','greater than equal to'];
        operatorAsPerFieldType['REFERENCE'] = ['equals','not equals to'];
        operatorAsPerFieldType['Id'] = ['equals','not equals to'];  
        operatorAsPerFieldType['DOUBLE'] = ['equals','not equals to','less than','greater than','less than equal to','greater than equal to'];
        operatorAsPerFieldType['PERCENT'] = ['equals','not equals to','less than','greater than','less than equal to','greater than equal to'];
        operatorAsPerFieldType['PICKLIST'] = ['equals','not equals to'];
        operatorAsPerFieldType['BOOLEAN'] = ['equals','not equals to'];
        
        component.set('v.OperatorAsPerFieldType',operatorAsPerFieldType);
    }
})