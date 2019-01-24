@isTest
public class PortfolioTest {
    public static testmethod void test(){
        HBX_Portfolio__c testPortfolio = new HBX_Portfolio__c();
    
        test.startTest();
        
        insert testPortfolio;
        update testPortfolio;
        delete testPortfolio;
        undelete testPortfolio;
        
        test.stopTest();
    }
}