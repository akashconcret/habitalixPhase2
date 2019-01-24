@isTest 
private class ShowPropertyRentsControllerTest {
    //static List<RentDetailsWrapper> listOfRentDetailsWrapper = new List<RentDetailsWrapper>();
    @testSetup static void showPropertyRentsControllerMethod(){
        List<String> lstIdAccounting = new List<String>();
        String mappingJSONForRentAndTransaction;
        String rentId = 'a0E1q0000009VtgEAE';
        
        HBX_HabitalixCreditDebitAccount__c habitalixCreditDebitAccount = new HBX_HabitalixCreditDebitAccount__c();
        habitalixCreditDebitAccount.Name = 'habitalixCreditDebitAccount';
        insert habitalixCreditDebitAccount;
        
        Account acc = new Account();
        acc.Name= 'Test Account';
        insert acc;
        
        HBX_Portfolio__c objPortfolio = new HBX_Portfolio__c();
        objPortfolio.Name = 'Test Portfolio';
        insert objPortfolio;
        
        HBX_BankAccount__c  ba = new HBX_BankAccount__c ();
        ba.Name = 'test';
        ba.HBX_IBAN__c  = '12345';
        insert ba;
        
        HBX_Building__c objBuilding = new HBX_Building__c();
        objBuilding.Name = 'Test Building';
        objBuilding.HBX_Portfolio__c = objPortfolio.Id;
        objBuilding.HBX_ManagementStartDate__c = System.today();
        objBuilding.HBX_NrFloors__c = 2;
        objBuilding.HBX_BankAccount__c = ba.Id;
        objBuilding.HBX_BuildingAreaGroundPlanSQM__c = 2;
        insert objBuilding;
        
        HBX_PropertyOwnership__c objOfProp = new HBX_PropertyOwnership__c(); 
        objOfProp.Account__c = acc.Id;
        objOfProp.Building__c = objBuilding.Id;
        objOfProp.HBX_Share__c = 100;
        insert objOfProp;
        
        HBX_Contract__c objContract = new HBX_Contract__c();
        objContract.HBX_Building__c =  objBuilding.Id;
        objContract.HBX_UsageType__c = 'Commercial';
        objContract.HBX_Status__c = 'Active';
        objContract.HBX_StartDate__c = System.today();
        insert objContract;
        
        RecordType rtCreditor = [select id from RecordType where developerName = 'Creditor'];
        RecordType rtDebitor = [select id from RecordType where developerName = 'Debitor'];
        RecordType OutGoingInvoice = [select id from RecordType where developerName = 'OutGoingInvoice'];
        
        // Related to CreditorDebitorNumber trigger. 
        HBX_Payer__c objOfPayer = new HBX_Payer__c();
        objOfPayer.Name = 'Test Payer';
        objOfPayer.HBX_Account__c = acc.Id;
        objOfPayer.HBX_Contract__c = objContract.Id;
        objOfPayer.HBX_Building__c = objBuilding.Id;
        objOfPayer.HBX_MainPayer__c = true;
        objOfPayer.RecordTypeId = rtCreditor.Id;
        insert objOfPayer;
        
        system.assertEquals(70000,[select id,HBX_CreditorDebitorNumber__c from HBX_Payer__c where Name = 'Test Payer'].HBX_CreditorDebitorNumber__c);
        
        HBX_Payer__c objOfPayer1 = new HBX_Payer__c();
        objOfPayer1.Name = 'Test Payer1';
        objOfPayer1.HBX_Account__c = acc.Id;
        objOfPayer1.HBX_Contract__c = objContract.Id;
        objOfPayer1.HBX_MainPayer__c = true;
        objOfPayer1.RecordTypeId = rtDebitor.Id;
        insert objOfPayer1;
        system.assertEquals(10000,[select id,HBX_CreditorDebitorNumber__c from HBX_Payer__c where Name = 'Test Payer1'].HBX_CreditorDebitorNumber__c);
        
        
        
        HBX_Invoice__c objRent = new HBX_Invoice__c();
        objRent.HBX_Status__c = 'Open';
        objRent.HBX_DueDate__c = system.today();
        objRent.Name = 'test 2';
        objRent.HBX_ContractName__c = objContract.id;
        objRent.HBX_CreditorDebitor__c = objOfPayer.Id;
        // objRent.HBX_InvoiceAmountNet__c = 100;
        objRent.RecordTypeId = OutGoingInvoice.Id;
        objRent.HBX_TaxRate__c = 19;
        
        insert objRent;
        
        HBX_InvoiceLineItem__c invLineItem = new HBX_InvoiceLineItem__c();
        invLineItem.Name = 'test';
        invLineItem.HBX_Quantity__c = 1;
        invLineItem.HBX_UnitPrice__c = 100;
        invLineItem.HBX_Invoice__c = objRent.Id;
        insert invLineItem;
        
        
        HBX_Accounting__c objAccounting = new HBX_Accounting__c();
        // objAccounting.Name = 'Test Accounting';
        objAccounting.HBX_Invoice__c = objRent.Id;
        objAccounting.HBX_Status__c = 'Open';
        objAccounting.HBX_AccountingType__c = 'Booking';
        objAccounting.HBX_AmountDebit__c = 80;
        objAccounting.HBX_AmountCredit__c = 80;
        insert objAccounting;
        
        HBX_Accounting__c objAccounting1 = new HBX_Accounting__c();
        // objAccounting.Name = 'Test Accounting';
        objAccounting1.HBX_Invoice__c = objRent.Id;
        objAccounting1.HBX_Status__c = 'Open';
        objAccounting1.HBX_AccountingType__c = 'Booking';
        objAccounting1.HBX_AmountDebit__c = 20;
        objAccounting1.HBX_AmountCredit__c = 20;
        insert objAccounting1;
        
        HBX_Accounting__c objAccounting2 = new HBX_Accounting__c();
        // objAccounting.Name = 'Test Accounting';
        objAccounting2.HBX_Invoice__c = objRent.Id;
        objAccounting2.HBX_Status__c = 'Open';
        objAccounting2.HBX_AccountingType__c = 'Booking - Tax';
        objAccounting2.HBX_AmountDebit__c = 19;
        objAccounting2.HBX_AmountCredit__c = 19;
        insert objAccounting2;
        
        
        HBX_TransactionType__c objOfTransactionType = new HBX_TransactionType__c();
        objOfTransactionType.Name = 'Test Transaction Type';
        insert objOfTransactionType;
        
        HBX_BankTransaction__c objOfBankTransaction = new HBX_BankTransaction__c();
        objOfBankTransaction.Name = 'Test Bank Transcation';
        objOfBankTransaction.HBX_InvoiceDate__c = System.today();
        objOfBankTransaction.HBX_TransactionType__c = objOfTransactionType.Id;
        objOfBankTransaction.HBX_BankAccount__c = ba.Id;
        objOfBankTransaction.HBX_Amount__c = 2000;
        insert objOfBankTransaction;
        
        
        HBX_BankTransaction__c objOfBankTransaction1 = new HBX_BankTransaction__c();
        objOfBankTransaction1.Name = 'Test Bank Transcation1';
        objOfBankTransaction1.HBX_InvoiceDate__c = System.today();
        objOfBankTransaction1.HBX_TransactionType__c = objOfTransactionType.Id;
        objOfBankTransaction1.HBX_BankAccount__c = ba.Id;
        objOfBankTransaction1.HBX_Amount__c = 2000;
        insert objOfBankTransaction1;
        
        
        mappingJSONForRentAndTransaction='{"'+objRent.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"a041q000000SWh2AAG","Amount":1300}]}';
        
        
        Test.startTest();
        List<RentDetailsWrapper> listOfWrapper = ShowPropertyRentsController.returnRents(08,'Partial matched Rents',5);
        System.assertEquals(0, listOfWrapper.size());
        ShowPropertyRentsController.returnAccountingRecords(rentId, 08);
        ShowPropertyRentsController.returnRents(08,'Not matched Rents',5);
        ShowPropertyRentsController.returnRents(08,'Total matched Rents',5);
        ShowPropertyRentsController.returnRents(08,'All',5);
        ShowPropertyRentsController.returnBankTransactions(' ', ba.Id, 2, 2);
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        Test.stopTest();
      
        
    }
    
    @isTest static void manualMatchCase1(){
        HBX_Invoice__c inv = [select id from HBX_Invoice__c limit 1];
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":119}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(119, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase2AndTaxToPay(){
        HBX_Invoice__c inv = [select id,HBX_TaxRate__c from HBX_Invoice__c limit 1];
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":117}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(117, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase2AndTaxNotToPay(){
        HBX_Invoice__c inv = [select id,HBX_TaxRate__c from HBX_Invoice__c limit 1];
        inv.HBX_TaxRate__c = 0;
        update inv;
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":90}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(90, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase3(){
        HBX_Invoice__c inv = [select id from HBX_Invoice__c limit 1];
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":121}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        
        
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(119, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase4(){
        HBX_Invoice__c inv = [select id,HBX_InvoiceAmountGross__c from HBX_Invoice__c limit 1];
        system.debug('inv :: '+inv);
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        HBX_BankTransaction__c bankTransaction2 = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation1' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":117},{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction2.Id+'","Amount":2}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(119, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase5(){
        HBX_Invoice__c inv = [select id from HBX_Invoice__c limit 1];
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        HBX_BankTransaction__c bankTransaction2 = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation1' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":117},{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction2.Id+'","Amount":5}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(119, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase6TaxToPay(){
        HBX_Invoice__c inv = [select id from HBX_Invoice__c limit 1];
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        HBX_BankTransaction__c bankTransaction2 = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation1' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":100},{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction2.Id+'","Amount":17}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(117, mapOfRentPaidAmount.get(inv.Id));
    }
    @isTest static void manualMatchCase6TaxNotToPay(){
        HBX_Invoice__c inv = [select id from HBX_Invoice__c limit 1];
        inv.HBX_TaxRate__c = 0;
        update inv;
        HBX_BankTransaction__c bankTransaction = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation' limit 1];
        HBX_BankTransaction__c bankTransaction2 = [select id,Name,HBX_Amount__c from HBX_BankTransaction__c where Name = 'Test Bank Transcation1' limit 1];
        String mappingJSONForRentAndTransaction='{"'+inv.Id+'"'+':[{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction.Id+'","Amount":80},{"Name":"Test Bank Transaction 2","Id":"'+bankTransaction2.Id+'","Amount":15}]}';
        ShowPropertyRentsController.mapRentAndTransaction(mappingJSONForRentAndTransaction);
        
        Map<Id,Decimal> mapOfRentPaidAmount = DMLHandler.retrievePaidRentAmountForRentInCurrentMonth(new List<HBX_Invoice__c>{inv});
        System.assertEquals(95, mapOfRentPaidAmount.get(inv.Id));
    }
    
}