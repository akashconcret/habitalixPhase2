trigger CreditorDebitorNumber on HBX_Payer__c (before insert) {
    Map<id,Integer> mapForMaxAutoNumberForCreditor = new  Map<id,Integer>();
    Map<id,Integer> mapForMaxAutoNumberForDebitor = new  Map<id,Integer>();
    Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.HBX_Payer__c.getRecordTypeInfosById();
    Set<Id> creditors = new Set<Id>();
    Set<Id> debitors = new Set<Id>();
    
    for(HBX_Payer__c payer : trigger.new){
        if(rtMap.get(payer.RecordTypeId).getName() == 'Creditor'){
            creditors.add(payer.HBX_Building__c);
        }else if(rtMap.get(payer.RecordTypeId).getName() == 'Debitor'){
            debitors.add(payer.HBX_Building__c);
        }
    }
    
    List<AggregateResult> lstOfCreditor = [select MAX(HBX_CreditorDebitorNumber__c) maxNumber,HBX_Building__c from HBX_Payer__c where (RecordType.DeveloperName='Creditor' AND HBX_Building__c IN:creditors) GROUP BY HBX_Building__c];
    for(AggregateResult aggrResult : lstOfCreditor){
        mapForMaxAutoNumberForCreditor.put(String.valueof(aggrResult.get('HBX_Building__c')),String.valueof(aggrResult.get('maxNumber'))==null?70000:Integer.valueof(String.valueof(aggrResult.get('maxNumber'))));
    }
    
    List<AggregateResult> lstOfDebitor = [select MAX(HBX_CreditorDebitorNumber__c) maxNumber,HBX_Building__c from HBX_Payer__c where (RecordType.DeveloperName='Debitor' AND HBX_Building__c IN:debitors) GROUP BY HBX_Building__c];
    for(AggregateResult aggrResult : lstOfDebitor){
        mapForMaxAutoNumberForDebitor.put(String.valueof(aggrResult.get('HBX_Building__c')),String.valueof(aggrResult.get('maxNumber'))==null?10000:Integer.valueof(String.valueof(aggrResult.get('maxNumber'))));
    }
    
    for(HBX_Payer__c payer : trigger.new){
        if(rtMap.get(payer.RecordTypeId).getName() == 'Creditor'){
            payer.HBX_CreditorDebitorNumber__c = (mapForMaxAutoNumberForCreditor.containsKey(payer.HBX_Building__c)?mapForMaxAutoNumberForCreditor.get(payer.HBX_Building__c)+1:70000);
            if(mapForMaxAutoNumberForCreditor.containsKey(payer.HBX_Building__c)){
                mapForMaxAutoNumberForCreditor.put(payer.HBX_Building__c,Integer.valueOf(payer.HBX_CreditorDebitorNumber__c));// to maintain max invoice number as per RT of Particular Company.
            }
        }else if(rtMap.get(payer.RecordTypeId).getName() == 'Debitor'){
            payer.HBX_CreditorDebitorNumber__c = (mapForMaxAutoNumberForDebitor.containsKey(payer.HBX_Building__c)?mapForMaxAutoNumberForDebitor.get(payer.HBX_Building__c)+1:10000);
            if(mapForMaxAutoNumberForDebitor.containsKey(payer.HBX_Building__c)){
                mapForMaxAutoNumberForDebitor.put(payer.HBX_Building__c,Integer.valueOf(payer.HBX_CreditorDebitorNumber__c));// to maintain max invoice number as per RT of Particular Company.
            }
        }
    }
}