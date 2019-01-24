trigger OutGoingInvoiceNumber on HBX_Invoice__c (before insert) {
    Map<id,Integer> mapForMaxAutoNumberForInvoiceNumber = new  Map<id,Integer>();
    
    Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.HBX_Invoice__c.getRecordTypeInfosById();
    Set<Id> invoicePayer = new Set<Id>();
    Set<Id> invoiceBuilding = new Set<Id>();
    Map<Id,Id> invoiceBuildingMap = new Map<Id,Id>();
    
    for(HBX_Invoice__c invoice : trigger.new){
        system.debug('rtMap.get(invoice.RecordTypeId).getName() :: '+rtMap.get(invoice.RecordTypeId).getName());
        if(rtMap.get(invoice.RecordTypeId).getName() == 'Outgoing Invoice'){
            invoicePayer.add(invoice.HBX_CreditorDebitor__c);
        }
    }
    
    for(HBX_Payer__c invPayer : [select id,HBX_Building__c from HBX_Payer__c where Id IN : invoicePayer]){
        invoiceBuilding.add(invPayer.HBX_Building__c);
        invoiceBuildingMap.put(invPayer.Id,invPayer.HBX_Building__c);
    }
    system.debug('invoiceBuildingMap :: '+invoiceBuildingMap);
    List<AggregateResult> lstOfCreditor = [select MAX(HBX_InvoiceNumber__c) maxNumber,HBX_CreditorDebitor__r.HBX_Building__c creditorBuilding from HBX_Invoice__c where (RecordType.DeveloperName='OutgoingInvoice' AND HBX_Status__c!='Paid' AND HBX_CreditorDebitor__r.HBX_Building__c IN:invoiceBuilding) GROUP BY HBX_CreditorDebitor__r.HBX_Building__c];
    for(AggregateResult aggrResult : lstOfCreditor){
        mapForMaxAutoNumberForInvoiceNumber.put(String.valueof(aggrResult.get('creditorBuilding')),String.valueof(aggrResult.get('maxNumber'))==null?1000:Integer.valueof(String.valueof(aggrResult.get('maxNumber')))+1);
    }
    system.debug('mapForMaxAutoNumberForInvoiceNumber :: '+mapForMaxAutoNumberForInvoiceNumber);
    for(HBX_Invoice__c invoice : trigger.new){
        if(rtMap.get(invoice.RecordTypeId).getName() == 'Outgoing Invoice'){
            Integer i=0;
            String prefixZeros='';
            Integer invoiceNumberStringLength = String.valueof((mapForMaxAutoNumberForInvoiceNumber.containsKey(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))?(mapForMaxAutoNumberForInvoiceNumber.get(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))==1000?1000:mapForMaxAutoNumberForInvoiceNumber.get(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))):1000)).length();
            for(i=0;i<(12-invoiceNumberStringLength);i++){
                prefixZeros+='0';
            }
            invoice.HBX_InvoiceNumber__c = prefixZeros+String.valueof((mapForMaxAutoNumberForInvoiceNumber.containsKey(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))?(mapForMaxAutoNumberForInvoiceNumber.get(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))==1000?1000:mapForMaxAutoNumberForInvoiceNumber.get(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))):1000));
            if(mapForMaxAutoNumberForInvoiceNumber.containsKey(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c))){
                mapForMaxAutoNumberForInvoiceNumber.put(invoiceBuildingMap.get(invoice.HBX_CreditorDebitor__c),Integer.valueof(invoice.HBX_InvoiceNumber__c)+1);
            }
        }
    }
}