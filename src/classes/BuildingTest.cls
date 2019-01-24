@isTest
public class BuildingTest {
    public static testmethod void test(){
        Account testAcc = new Account(
            name = 'test'
        );
        insert testAcc;
        
        HBX_Portfolio__c testPortfolio = new HBX_Portfolio__c();
        insert testPortfolio;
        
        HBX_Building__c testBuilding = new HBX_Building__c(
        	HBX_Portfolio__c = testPortfolio.Id,
            HBX_NrFloors__c = 2,            
            HBX_BuildingAreaGroundPlanSQM__c = 288,
            HBX_ManagementStartDate__c = system.today()
        );
        
        test.startTest();
        
        insert testBuilding;
        update testBuilding;
        delete testBuilding;
        undelete testBuilding;
        
        test.stopTest();
    }
}