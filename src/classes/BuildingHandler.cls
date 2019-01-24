public without sharing class BuildingHandler{
    private static Set<Id> processedIds;  
    private Boolean isExecuting; 
    
    /*
	* Constructor 
	*/
    public BuildingHandler(Boolean isExecuting){
        this.isExecuting = isExecuting; 
        if(processedIds == null) processedIds = new Set<Id>();  
    }
    
    public void onAfterInsert(List<HBX_Building__c> triggerOld, Map<Id,HBX_Building__c> triggerOldMap, List<HBX_Building__c> triggerNew, Map<Id,HBX_Building__c> triggerNewMap){
        RollupUtils.CalculateAllRollupsForChildren(triggerNew);
    }
    
    public void onAfterUpdate(List<HBX_Building__c> triggerOld, Map<Id,HBX_Building__c> triggerOldMap, List<HBX_Building__c> triggerNew, Map<Id,HBX_Building__c> triggerNewMap){
        RollupUtils.CalculateAllRollupsForChildren(triggerNew);
    }
    
    public void onAfterDelete(List<HBX_Building__c> triggerOld, Map<Id,HBX_Building__c> triggerOldMap, List<HBX_Building__c> triggerNew, Map<Id,HBX_Building__c> triggerNewMap){
        RollupUtils.CalculateAllRollupsForChildren(triggerOld);
    }
    
    public void onAfterUndelete(List<HBX_Building__c> triggerOld, Map<Id,HBX_Building__c> triggerOldMap, List<HBX_Building__c> triggerNew, Map<Id,HBX_Building__c> triggerNewMap){
        RollupUtils.CalculateAllRollupsForChildren(triggerNew);
    }
    
    
}