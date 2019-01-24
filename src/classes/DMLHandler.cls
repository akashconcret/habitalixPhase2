public class DMLHandler {  
    public static String mapRentAndTransaction(string mappingJSONForRentAndTransaction) {
        Boolean case1 = true;
        Boolean case2 = true;
        Boolean allDmlSet;
        System.debug('mappingJSONForRentAndTransaction::'+mappingJSONForRentAndTransaction);
        
        Map<String, Object> mapForRentIdAndTransactions = (Map<String, Object>)JSON.deserializeUntyped(mappingJSONForRentAndTransaction);
        List<HBX_Accounting__c> lstOfAcoounting = new List<HBX_Accounting__c>();
        String rentIdValue = '';
        Decimal selectedTransactionsPaidAmount = 0;
        Map<String,Sobject> mapDebitCredit = HBX_HabitalixCreditDebitAccount__c.getAll();
        
        Savepoint sp = Database.setSavepoint();
        HBX_Invoice__c invoice;
        
        for(string rentId :mapForRentIdAndTransactions.keySet()){
            rentIdValue = rentId;
            string serilizedListOfTransactions = JSON.serialize(mapForRentIdAndTransactions.get(rentId));
            List<Object> lstObj = (List<Object> ) JSON.deserializeUntyped(serilizedListOfTransactions);
            Map<Id,String> mapBankTransactionIdsToUpdateStatus = new Map<Id,String>();
            List<HBX_BankTransaction__c> lstTransaction = new List<HBX_BankTransaction__c>();
            
            for(object transactionasObject :lstObj){
                case1 = true;
                case2 = true;
                
                invoice = [select id,Name,recordtype.DeveloperName,(select id from InvoiceSAccountings__r limit 1),HBX_InvoiceAmountGross__c,HBX_TaxAmount__c,HBX_TaxRate__c,HBX_OpenDeptAccountings__c,HBX_OpenReceivableAccountings__c from HBX_Invoice__c where id =: rentIdValue];
                if(invoice.InvoiceSAccountings__r.size()==0){
                    return 'No Accounting records found';
                }
                Map<String, Object> mapForTransactionFields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(transactionasObject));
                String tansactionId = string.valueof(mapForTransactionFields.get('Id')).split(':')[0];
                Decimal remainingTransactionAmount = Decimal.valueof(string.valueof(mapForTransactionFields.get('Id')).split(':')[1]);
                selectedTransactionsPaidAmount = Decimal.valueof(String.valueof(mapForTransactionFields.get('Amount')));
                system.debug('remainingTransactionAmount :: '+remainingTransactionAmount);
                
                if((remainingTransactionAmount-selectedTransactionsPaidAmount)==0.00){
                    mapBankTransactionIdsToUpdateStatus.put(tansactionId,'Matched');
                }else if(remainingTransactionAmount > selectedTransactionsPaidAmount){
                    mapBankTransactionIdsToUpdateStatus.put(tansactionId,'Partially Matched');// Partially Matched
                }
                
                system.debug('mapBankTransactionIdsToUpdateStatus :: '+mapBankTransactionIdsToUpdateStatus);
                
                if(case1 && (invoice.recordtype.DeveloperName == 'IncomingInvoice' && invoice.HBX_OpenDeptAccountings__c == 0 && invoice.HBX_InvoiceAmountGross__c == selectedTransactionsPaidAmount) || (invoice.recordtype.DeveloperName == 'OutgoingInvoice' && invoice.HBX_OpenReceivableAccountings__c == 0 && invoice.HBX_InvoiceAmountGross__c == selectedTransactionsPaidAmount)){
                   system.debug('eneterd1 ');
                   case1 = false;
                   allDmlSet =  whenExactAmountMapping(invoice,tansactionId);// TransactionId replaced for  string.valueof(mapForTransactionFields.get('Id')) 22 NOV 18 .
                }
                if(case1 && ((invoice.recordtype.DeveloperName == 'IncomingInvoice' && invoice.HBX_OpenDeptAccountings__c == 0 && invoice.HBX_InvoiceAmountGross__c > selectedTransactionsPaidAmount) || (invoice.recordtype.DeveloperName == 'OutgoingInvoice' && invoice.HBX_OpenReceivableAccountings__c == 0 && invoice.HBX_InvoiceAmountGross__c > selectedTransactionsPaidAmount))){
                    system.debug('eneterd2 ');
                    case1 = false;
                    allDmlSet = whenInvoiceAmountIsGreaterThanTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,mapDebitCredit); // Decimal.valueof(String.valueof(mapForTransactionFields.get('Amount'))) replace with selectedTransactionsPaidAmount becoz both were same.
                }
                if(case1 && ((invoice.recordtype.DeveloperName == 'IncomingInvoice' && invoice.HBX_OpenDeptAccountings__c == 0 && invoice.HBX_InvoiceAmountGross__c < selectedTransactionsPaidAmount) || (invoice.recordtype.DeveloperName == 'OutgoingInvoice' && invoice.HBX_OpenReceivableAccountings__c == 0 && invoice.HBX_InvoiceAmountGross__c < selectedTransactionsPaidAmount))){
                    system.debug('eneterd3 ');
                    case1 = false;
                    allDmlSet = whenInvoiceAmountIsLessThanTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,mapDebitCredit);
                }
                
                AggregateResult aggr;
                if(case1){
                     aggr = [select SUM(HBX_PaidAmount__c) paidAmount,HBX_Invoice__c from HBX_Accounting__c where HBX_Invoice__c=:rentIdValue AND (HBX_AccountingType__c = 'Booking - Tax' OR HBX_AccountingType__c = 'Booking') AND HBX_Status__c='Matched' GROUP BY HBX_Invoice__c ];
                }
                
                //Case 4 : Manul Match
                if(case1 && case2 && ((invoice.recordtype.DeveloperName == 'IncomingInvoice' && invoice.HBX_OpenDeptAccountings__c > 0 ) || (invoice.recordtype.DeveloperName == 'OutgoingInvoice' && invoice.HBX_OpenReceivableAccountings__c > 0 )) && (invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount'))))==selectedTransactionsPaidAmount){
                   system.debug('eneterd4 ');
                    //AggregateResult aggr = [select SUM(HBX_PaidAmount__c) paidAmount,HBX_Invoice__c from HBX_Accounting__c where HBX_Invoice__c=:rentIdValue AND (HBX_AccountingType__c = 'Booking - Tax' OR HBX_AccountingType__c = 'Booking') AND HBX_Status__c='Matched' GROUP BY HBX_Invoice__c ];
                    if(invoice.recordtype.DeveloperName == 'IncomingInvoice'){
                        case2 = false;
                        allDmlSet = whenORAGreaterThanZeroAndInvAmountequalsTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,new List<String>{'Dept - Tax','Dept'},mapDebitCredit);
                    }else if(invoice.recordtype.DeveloperName == 'OutgoingInvoice'){
                        case2 = false;
                        allDmlSet = whenORAGreaterThanZeroAndInvAmountequalsTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,new List<String>{'Receivable','Receivable - Tax'},mapDebitCredit);
                    }
                }
                
                //Case 5 : Manul Match
                if(case1 && case2 && ((invoice.recordtype.DeveloperName == 'IncomingInvoice' && invoice.HBX_OpenDeptAccountings__c > 0 ) || (invoice.recordtype.DeveloperName == 'OutgoingInvoice' && invoice.HBX_OpenReceivableAccountings__c > 0 )) && (invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount')))) < selectedTransactionsPaidAmount){
                   system.debug('eneterd5 ');
                   //AggregateResult aggr = [select SUM(HBX_PaidAmount__c) paidAmount,HBX_Invoice__c from HBX_Accounting__c where HBX_Invoice__c=:rentIdValue AND (HBX_AccountingType__c = 'Booking - Tax' OR HBX_AccountingType__c = 'Booking') AND HBX_Status__c='Matched' GROUP BY HBX_Invoice__c ];
                   if(invoice.recordtype.DeveloperName == 'IncomingInvoice'){
                       case2 = false;
                        allDmlSet = whenORAGreaterThanZeroAndInvAmountIsLessTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,new List<String>{'Dept - Tax','Dept'},invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount'))),mapDebitCredit);
                    }else if(invoice.recordtype.DeveloperName == 'OutgoingInvoice'){
                        case2 = false;
                        allDmlSet = whenORAGreaterThanZeroAndInvAmountIsLessTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,new List<String>{'Receivable','Receivable - Tax'},invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount'))),mapDebitCredit);
                    }
                }
                
                // Case 6 : 
                if(case1 && case2 && ((invoice.recordtype.DeveloperName == 'IncomingInvoice' && invoice.HBX_OpenDeptAccountings__c > 0 ) || (invoice.recordtype.DeveloperName == 'OutgoingInvoice' && invoice.HBX_OpenReceivableAccountings__c > 0 )) && (invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount')))) > selectedTransactionsPaidAmount){
                   system.debug('eneterd6 ');
                   //AggregateResult aggr = [select SUM(HBX_PaidAmount__c) paidAmount,HBX_Invoice__c from HBX_Accounting__c where HBX_Invoice__c=:rentIdValue AND (HBX_AccountingType__c = 'Booking - Tax' OR HBX_AccountingType__c = 'Booking') AND HBX_Status__c='Matched' GROUP BY HBX_Invoice__c ];
                   if(invoice.recordtype.DeveloperName == 'IncomingInvoice'){
                       system.debug('eneterd 1');
                       case2 = false;
                        allDmlSet = whenORAGreaterThanZeroAndInvAmountIsGreaterThanTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,new List<String>{'Dept - Tax','Dept'},invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount'))),mapDebitCredit);
                    }else if(invoice.recordtype.DeveloperName == 'OutgoingInvoice'){
                        case2 = false;
                        allDmlSet = whenORAGreaterThanZeroAndInvAmountIsGreaterThanTransactionAmount(invoice,tansactionId,selectedTransactionsPaidAmount,invoice.recordtype.DeveloperName,new List<String>{'Receivable','Receivable - Tax'},invoice.HBX_InvoiceAmountGross__c-Decimal.valueOf(String.valueOf(aggr.get('paidAmount')==null?'0':aggr.get('paidAmount'))),mapDebitCredit);
                    }
                }
            }
            
            try{
                if(allDmlSet && invoice!=null){
                    update invoice;
                }
            }catch(exception ee){
                allDmlSet = false;
                system.debug('error while updating invoice ::  '+ee.getMessage());
            }
            
            try{
                lstTransaction = [select id,HBX_Status__c from HBX_BankTransaction__c where Id IN: mapBankTransactionIdsToUpdateStatus.keyset()];
                for(HBX_BankTransaction__c transac : lstTransaction){
                    transac.HBX_Status__c = mapBankTransactionIdsToUpdateStatus.get(transac.Id);
                }
                system.debug('lstTransaction :: '+lstTransaction);
                if(lstTransaction.size()>0){
                    update lstTransaction;
                }
            }catch(exception ee){
                allDmlSet = false;
                system.debug('error while updating transaction status  ::  '+ee.getMessage());
            }
            
        }
        if(!allDmlSet){
            system.debug('Rolled Back');
            Database.rollback(sp);
        }
        return (allDmlSet!=null && allDmlSet)?'Invoice Mapped Successfully.':'SomeThing Went Wrong . All Changes have been rolled back.';
    } 
    
    //case 1 manual matching 
    public static Boolean whenExactAmountMapping(HBX_Invoice__c invoice,String transId){
        Boolean allDmlSet = true;
        List<HBX_Accounting__c> lstAccountings = [select id,HBX_Status__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id];
        for(HBX_Accounting__c accounting :lstAccountings){
            accounting.HBX_Status__c = 'Matched';
            accounting.HBX_BankTransaction__c = transId;
            accounting.HBX_PaidAmount__c = accounting.HBX_AmountDebit__c;
        }
        try{
            update lstAccountings;
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating invoice Accountings for case 1 ::  '+ee.getMessage());
        }
        
        try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Paid';
                // update invoice;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating invoice case 1::  '+ee.getMessage());
        }
        
        return allDmlSet;
    }
    
    // case 2 manual matching 
    public static Boolean whenInvoiceAmountIsGreaterThanTransactionAmount(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,Map<String,Sobject> mapDebitCredit){
        if(invoice.HBX_TaxRate__c!=null && invoice.HBX_TaxRate__c>0){
            return whenInvoiceAmountIsGreaterThanTransactionAmountAndTaxToPay(invoice,transId,transactionAmount,rcName,mapDebitCredit);
        }else{
            return whenInvoiceAmountIsGreaterThanTransactionAmountAndTaxNotToPay(invoice,transId,transactionAmount,rcName,mapDebitCredit);
        }
    }
    
    public static Boolean whenInvoiceAmountIsGreaterThanTransactionAmountAndTaxToPay(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,Map<String,Sobject> mapDebitCredit){
       Boolean allDmlSet = true;
        Decimal additionalPaymentToBookingTypeAccounting = 0.00;
        List<HBX_Accounting__c> oldAccountings = new List<HBX_Accounting__c>();
        List<HBX_Accounting__c> newAccountings = new List<HBX_Accounting__c>();
        
        List<HBX_Accounting__c> lstAccountings = [select id,HBX_Status__c,HBX_BankTransaction__c,HBX_DebitAccount__c,HBX_CreditAccount__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_AccountingType__c = 'Booking - Tax'];
        for(HBX_Accounting__c accounting :lstAccountings){
            accounting.HBX_Status__c = 'Matched';
            accounting.HBX_ParentAccounting__c = null; //if HBX_Status__c = 'Matched'
            accounting.HBX_BankTransaction__c = transId;
            if(invoice.HBX_TaxAmount__c != null && transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c)>accounting.HBX_AmountDebit__c){
                accounting.HBX_PaidAmount__c = invoice.HBX_TaxAmount__c;
                additionalPaymentToBookingTypeAccounting = transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c) - invoice.HBX_TaxAmount__c;
            }else{
                accounting.HBX_PaidAmount__c = transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c);
            }
            
            accounting.HBX_AmountDebit__c = accounting.HBX_PaidAmount__c;
            accounting.HBX_AmountCredit__c = accounting.HBX_PaidAmount__c;
            oldAccountings.add(accounting);
        }
        
        if(additionalPaymentToBookingTypeAccounting == 0.00 && (invoice.HBX_TaxAmount__c-lstAccountings[0].HBX_PaidAmount__c)>0){
            HBX_Accounting__c accounting = new HBX_Accounting__c();
            accounting.HBX_AccountingType__c = (rcName!=null && rcName == 'IncomingInvoice')?'Dept - Tax':'Receivable - Tax';
            accounting.HBX_Status__c = 'Open';
            accounting.HBX_ParentAccounting__c = lstAccountings[0].Id;
            accounting.HBX_Invoice__c  = invoice.Id;
            accounting.HBX_AmountCredit__c = invoice.HBX_TaxAmount__c - lstAccountings[0].HBX_PaidAmount__c;
            accounting.HBX_AmountDebit__c = invoice.HBX_TaxAmount__c - lstAccountings[0].HBX_PaidAmount__c;
            if(accounting.HBX_AccountingType__c == 'Receivable - Tax'){
                accounting.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(accounting.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null;
                accounting.HBX_CreditAccount__c = lstAccountings[0].HBX_CreditAccount__c;
            }else if(accounting.HBX_AccountingType__c == 'Dept - Tax'){
                accounting.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(accounting.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
                accounting.HBX_DebitAccount__c = lstAccountings[0].HBX_DebitAccount__c;
            }
            
            newAccountings.add(accounting);
        }
        
        List<HBX_Accounting__c> lstAccountingsTypeBooking = [select id,HBX_DebitAccount__c,HBX_CreditAccount__c,HBX_Status__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c,HBX_AccountingType__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_AccountingType__c = 'Booking'];
        Decimal totalDueAmountForInvoicefromAccountings = 0.00; 
       
        for(HBX_Accounting__c accCloned : lstAccountingsTypeBooking){
            totalDueAmountForInvoicefromAccountings +=(accCloned.HBX_AmountDebit__c!=null?accCloned.HBX_AmountDebit__c:0.00);
        }
        if(invoice.HBX_TaxAmount__c!=null){
            totalDueAmountForInvoicefromAccountings +=(invoice.HBX_TaxAmount__c);
        }
        
        system.debug('totalDueAmountForInvoicefromAccountings 1:: '+totalDueAmountForInvoicefromAccountings);
        for(HBX_Accounting__c accountingBooking :lstAccountingsTypeBooking){
            if(additionalPaymentToBookingTypeAccounting!=0.00){
                accountingBooking.HBX_PaidAmount__c = (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings)+additionalPaymentToBookingTypeAccounting*(accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings;
            }else{
                accountingBooking.HBX_PaidAmount__c = (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            }
            
            accountingBooking.HBX_BankTransaction__c = transId;
            accountingBooking.HBX_Status__c = 'Matched';
            // system.debug('Booking ccount :: '+mapForBookingAccount!=null && mapForBookingAccount.containsKey('Booking') ? mapForBookingAccount.get('Booking').split(':')[0]:NULL);
            accountingBooking.HBX_ParentAccounting__c = null; //if HBX_Status__c = 'Matched'
            oldAccountings.add(accountingBooking);
            
            HBX_Accounting__c newAccountingBooking = new HBX_Accounting__c();
            newAccountingBooking.HBX_AccountingType__c = (rcName!=null && rcName == 'IncomingInvoice')?'Dept':'Receivable';
            newAccountingBooking.HBX_Status__c = 'Open';
            newAccountingBooking.HBX_ParentAccounting__c = accountingBooking.Id;
            newAccountingBooking.HBX_Invoice__c  = invoice.Id;
            newAccountingBooking.HBX_AmountCredit__c = accountingBooking.HBX_AmountDebit__c - accountingBooking.HBX_PaidAmount__c;
            newAccountingBooking.HBX_AmountDebit__c = accountingBooking.HBX_AmountDebit__c - accountingBooking.HBX_PaidAmount__c;
            
            if(newAccountingBooking.HBX_AccountingType__c == 'Receivable'){
                newAccountingBooking.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null;
                newAccountingBooking.HBX_CreditAccount__c = accountingBooking.HBX_CreditAccount__c;
            }else if(newAccountingBooking.HBX_AccountingType__c == 'Dept'){
                newAccountingBooking.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
                newAccountingBooking.HBX_DebitAccount__c = accountingBooking.HBX_DebitAccount__c;
            }
            accountingBooking.HBX_AmountDebit__c = accountingBooking.HBX_PaidAmount__c;
            accountingBooking.HBX_AmountCredit__c = accountingBooking.HBX_PaidAmount__c;
            newAccountings.add(newAccountingBooking);
        }
       
        try{
            update oldAccountings;
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating accountings  :: case 2 (inv > tra) manual :: '+ee.getMessage());
        }
        try{
            if(allDmlSet){
                Insert newAccountings;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while inserting accountings  :: case 2 (inv > tra) manual :: '+ee.getMessage());
        }
        try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Partially Paid	';
                // update invoice;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating invoice ::  '+ee.getMessage());
        }
        return allDmlSet;
    }
    
    public static Boolean whenInvoiceAmountIsGreaterThanTransactionAmountAndTaxNotToPay(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,Map<String,Sobject> mapDebitCredit){
        Boolean allDmlSet = true;
        List<HBX_Accounting__c> lstAccountingsTypeBooking = [select id,HBX_DebitAccount__c,HBX_AccountingType__c,HBX_ParentAccounting__r.HBX_DebitAccount__c,HBX_ParentAccounting__r.HBX_CreditAccount__c,HBX_Status__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_CreditAccount__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_Status__c = 'Open' AND (HBX_AccountingType__c = 'Booking') ];// OR HBX_AccountingType__c='Booking - Tax')
        List<HBX_Accounting__c> newAccountings = new List<HBX_Accounting__c>();
        Decimal totalDueAmountForInvoicefromAccountings = 0.00; 
       
        for(HBX_Accounting__c accCloned : lstAccountingsTypeBooking){
           if(accCloned.HBX_AccountingType__c!='Booking - Tax'){
               totalDueAmountForInvoicefromAccountings +=(accCloned.HBX_AmountDebit__c!=null?accCloned.HBX_AmountDebit__c:0.00);
           }
        }
        
        for(HBX_Accounting__c accountingBooking :lstAccountingsTypeBooking){
           HBX_Accounting__c newAccountingBooking = new HBX_Accounting__c();
            newAccountingBooking.HBX_AccountingType__c = (rcName!=null && rcName == 'IncomingInvoice')?'Dept':'Receivable';
            newAccountingBooking.HBX_Status__c = 'Open';
            newAccountingBooking.HBX_ParentAccounting__c = accountingBooking.Id;
            newAccountingBooking.HBX_Invoice__c  = invoice.Id;
            newAccountingBooking.HBX_AmountCredit__c = accountingBooking.HBX_AmountDebit__c - (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            newAccountingBooking.HBX_AmountDebit__c = accountingBooking.HBX_AmountDebit__c - (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            
            if(newAccountingBooking.HBX_AccountingType__c=='Receivable'){
                newAccountingBooking.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null; 
                newAccountingBooking.HBX_CreditAccount__c = accountingBooking.HBX_CreditAccount__c;
            }else if(newAccountingBooking.HBX_AccountingType__c=='Dept'){
                newAccountingBooking.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
                newAccountingBooking.HBX_DebitAccount__c = accountingBooking.HBX_DebitAccount__c;
            }
            newAccountings.add(newAccountingBooking);
            accountingBooking.HBX_PaidAmount__c = (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            accountingBooking.HBX_BankTransaction__c = transId;
            accountingBooking.HBX_AmountDebit__c = (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            accountingBooking.HBX_AmountCredit__c = (transactionAmount)*((accountingBooking.HBX_AmountDebit__c!=null?accountingBooking.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            accountingBooking.HBX_Status__c = 'Matched';
            accountingBooking.HBX_ParentAccounting__c = null; //if HBX_Status__c = 'Matched'
        }
        
        
        
        try{
            update lstAccountingsTypeBooking;
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating accountings  :: case 2 (inv > tra) manual no tax:: '+ee.getMessage());
        }
        try{
            if(allDmlSet){
                insert newAccountings;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while inserting accountings  :: case 2 (inv > tra) manual no tax:: '+ee.getMessage());
        }
        try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Partially Paid	';
                // update invoice;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating invoice ::  '+ee.getMessage());
        }
        return allDmlSet;
    }
    
    //case 3
    public static Boolean whenInvoiceAmountIsLessThanTransactionAmount(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,Map<String,Sobject> mapDebitCredit){
        Boolean allDmlSet = true;
        List<HBX_Accounting__c> lstAccountingsTypeBooking = [select id,HBX_Status__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_Status__c = 'Open' AND (HBX_AccountingType__c = 'Booking' OR HBX_AccountingType__c='Booking - Tax')];
        List<HBX_Accounting__c> newAccountings = new List<HBX_Accounting__c>();
        for(HBX_Accounting__c accountingBooking :lstAccountingsTypeBooking){
            accountingBooking.HBX_PaidAmount__c = accountingBooking.HBX_AmountDebit__c;
            accountingBooking.HBX_BankTransaction__c = transId;
            accountingBooking.HBX_Status__c = 'Matched';
            accountingBooking.HBX_ParentAccounting__c = null; //if HBX_Status__c = 'Matched'
        }
        
        HBX_Accounting__c newAccountingBooking = new HBX_Accounting__c();
            newAccountingBooking.HBX_AccountingType__c = (rcName!=null && rcName == 'IncomingInvoice')?'Receivable':'Dept';
            newAccountingBooking.HBX_Status__c = 'Open';
            newAccountingBooking.HBX_Invoice__c  = invoice.Id;
            newAccountingBooking.HBX_AmountCredit__c = transactionAmount - invoice.HBX_InvoiceAmountGross__c;
            newAccountingBooking.HBX_AmountDebit__c = transactionAmount - invoice.HBX_InvoiceAmountGross__c;
            newAccountingBooking.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null;
            newAccountingBooking.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
        try{
            update lstAccountingsTypeBooking;
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating accountings  :: case 3 (inv < tra) manual  '+ee.getMessage());
        }
        try{
            if(allDmlSet){
                insert newAccountingBooking;//newAccountingBooking;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while inserting accountings  :: case 3 (inv < tra) manual'+ee.getMessage());
        }
        try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Paid';
                // update invoice;
            }
        }catch(exception ee){
            allDmlSet = false;
            system.debug('error while updating invoice ::  '+ee.getMessage());
        }
        return allDmlSet;
    }
    
    //ORA --> OpenReceivableAccounting
    //case 4
    public static Boolean whenORAGreaterThanZeroAndInvAmountequalsTransactionAmount(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,List<String> lstOdAccountingTypes,Map<String,Sobject> mapDebitCredit){
        Boolean allDmlSet = true;
        List<HBX_Accounting__c> lstAccountingsType= [select id,HBX_Status__c,HBX_DebitAccount__c,HBX_ParentAccounting__c,HBX_ParentAccounting__r.HBX_AccountingType__c,HBX_ParentAccounting__r.HBX_DebitAccount__c,HBX_ParentAccounting__r.HBX_CreditAccount__c,HBX_CreditAccount__c,HBX_AmountCredit__c,HBX_AccountingType__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_Status__c = 'Open' AND HBX_AccountingType__c IN : lstOdAccountingTypes]; 
        List<HBX_Accounting__c> lstAccountingsTypeCloned = new List<HBX_Accounting__c>();
        if(lstAccountingsType.size()>0){
            lstAccountingsTypeCloned.addAll(lstAccountingsType);
            for(HBX_Accounting__c accountingsOld : lstAccountingsType){
                accountingsOld.HBX_Status__c = 'Debt Paid';
            }
        }
        if(lstAccountingsType.size()>0){
            update lstAccountingsType;
        }
        for(HBX_Accounting__c accountingsCloned : lstAccountingsTypeCloned){
            accountingsCloned.Id = null;
            accountingsCloned.HBX_Status__c = 'Matched';
            if(accountingsCloned.HBX_AccountingType__c.contains('Tax')){
                accountingsCloned.HBX_AccountingType__c = 'Booking - Tax';
            }else{
                accountingsCloned.HBX_AccountingType__c = 'Booking';
            }
            accountingsCloned.HBX_CreditAccount__c = accountingsCloned.HBX_ParentAccounting__r.HBX_CreditAccount__c;
            accountingsCloned.HBX_DebitAccount__c = accountingsCloned.HBX_ParentAccounting__r.HBX_DebitAccount__c;
            accountingsCloned.HBX_ParentAccounting__c = null; //if HBX_Status__c = 'Matched'
            accountingsCloned.HBX_BankTransaction__c = transId;
            accountingsCloned.HBX_PaidAmount__c = accountingsCloned.HBX_AmountDebit__c;
        }
        try{
            System.debug('doing insert  :: ');
            insert lstAccountingsTypeCloned;
        }catch(Exception ee){
            allDmlSet = false;
        }
        
        try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Paid';
                // update invoice;
            }
        }catch(Exception ee){
            allDmlSet = false;
        }
        return allDmlSet;
    } 
    //case 5
    public static Boolean whenORAGreaterThanZeroAndInvAmountIsLessTransactionAmount(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,List<String> lstOdAccountingTypes,Decimal allocatedAmount,Map<String,Sobject> mapDebitCredit){
        Boolean allDmlSet = true;
        List<HBX_Accounting__c> lstAccountingsType= [select id,HBX_Status__c,HBX_DebitAccount__c,HBX_ParentAccounting__c,HBX_ParentAccounting__r.HBX_AccountingType__c,HBX_ParentAccounting__r.HBX_DebitAccount__c,HBX_ParentAccounting__r.HBX_CreditAccount__c,HBX_CreditAccount__c,HBX_AmountCredit__c,HBX_AccountingType__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_Status__c = 'Open' AND HBX_AccountingType__c IN : lstOdAccountingTypes]; 
        List<HBX_Accounting__c> lstAccountingsTypeCloned = new List<HBX_Accounting__c>();
        if(lstAccountingsType.size()>0){
            lstAccountingsTypeCloned.addAll(lstAccountingsType);
            for(HBX_Accounting__c accountingsOld : lstAccountingsType){
                accountingsOld.HBX_Status__c = 'Debt Paid';
            }
        }
        if(lstAccountingsType.size()>0){
            System.debug('doing update  :: ');
            update lstAccountingsType;
        }
        for(HBX_Accounting__c accountingsCloned : lstAccountingsTypeCloned){
            accountingsCloned.Id = null;
            accountingsCloned.HBX_Status__c = 'Matched';
            if(accountingsCloned.HBX_AccountingType__c.contains('Tax')){
                accountingsCloned.HBX_AccountingType__c = 'Booking - Tax';
            }else{
                accountingsCloned.HBX_AccountingType__c = 'Booking';
            }
            accountingsCloned.HBX_CreditAccount__c = accountingsCloned.HBX_ParentAccounting__r.HBX_CreditAccount__c;
            accountingsCloned.HBX_DebitAccount__c =  accountingsCloned.HBX_ParentAccounting__r.HBX_DebitAccount__c;
            accountingsCloned.HBX_BankTransaction__c = transId;
            accountingsCloned.HBX_PaidAmount__c = accountingsCloned.HBX_AmountDebit__c;
            accountingsCloned.HBX_ParentAccounting__c = null; //if HBX_Status__c = 'Matched'
        }
        
        if(allDmlSet){
            HBX_Accounting__c newAcc = new HBX_Accounting__c();
            newAcc.HBX_AmountCredit__c = transactionAmount-allocatedAmount;
            newAcc.HBX_AmountDebit__c = transactionAmount-allocatedAmount;
            newAcc.HBX_Invoice__c = invoice.Id;
            newAcc.HBX_Status__c  = 'Open';
            newAcc.HBX_AccountingType__c = (rcName!=null && rcName=='IncomingInvoice')?'Receivable':'Dept';
            newAcc.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAcc.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAcc.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAcc.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null;
            newAcc.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAcc.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAcc.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAcc.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
            lstAccountingsTypeCloned.add(newAcc);
        }
        try{
            insert lstAccountingsTypeCloned;
        }catch(Exception ee){
            allDmlSet = false;
        }
        try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Paid';
                // update invoice;
            }
        }catch(Exception ee){
            allDmlSet = false;
        }
        return allDmlSet;
    }
    //case 6
    public static Boolean whenORAGreaterThanZeroAndInvAmountIsGreaterThanTransactionAmount(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,List<String> lstOdAccountingTypes,Decimal allocatedAmount,Map<String,Sobject> mapDebitCredit){
        Boolean allDmlSet = true;
        List<HBX_Accounting__c> lstAccountingsType= [select id,HBX_Status__c,HBX_DebitAccount__c,HBX_ParentAccounting__c,HBX_ParentAccounting__r.HBX_AccountingType__c,HBX_ParentAccounting__r.HBX_DebitAccount__c,HBX_ParentAccounting__r.HBX_CreditAccount__c,HBX_CreditAccount__c,HBX_AmountCredit__c,HBX_AccountingType__c,HBX_BankTransaction__c,HBX_AmountDebit__c,HBX_Invoice__c,HBX_PaidAmount__c from HBX_Accounting__c where HBX_Invoice__c=:invoice.Id AND HBX_Status__c = 'Open' AND HBX_AccountingType__c IN : lstOdAccountingTypes]; 
        List<HBX_Accounting__c> lstAccountingsTypeCloned = new List<HBX_Accounting__c>();
        
        system.debug('whenORAGreaterThanZeroAndInvAmountIsGreaterThanTransactionAmount 2:: 508 '+lstAccountingsType);
        
        if(lstAccountingsType.size()>0){
            lstAccountingsTypeCloned.addAll(lstAccountingsType);
            for(HBX_Accounting__c accountingsOld : lstAccountingsType){
                accountingsOld.HBX_Status__c = 'Debt Paid';
            }
        }
        if(lstAccountingsType.size()>0){
            update lstAccountingsType;
        }
        if(invoice.HBX_TaxRate__c!=null && invoice.HBX_TaxRate__c>0){
           allDmlSet = whenORAGreaterThanZeroAndInvAmountIsGreaterTransactionAmountAndTaxToPay(invoice,transId,transactionAmount,rcName,lstOdAccountingTypes,allocatedAmount,lstAccountingsTypeCloned,true,mapDebitCredit);
        }else{
            allDmlSet = whenORAGreaterThanZeroAndInvAmountIsGreaterTransactionAmountAndTaxToPay(invoice,transId,transactionAmount,rcName,lstOdAccountingTypes,allocatedAmount,lstAccountingsTypeCloned,false,mapDebitCredit);
        }
        return allDmlSet;
    }
    
    public static Boolean whenORAGreaterThanZeroAndInvAmountIsGreaterTransactionAmountAndTaxToPay(HBX_Invoice__c invoice,String transId,Decimal transactionAmount,String rcName,List<String> lstOdAccountingTypes,Decimal allocatedAmount,List<HBX_Accounting__c> lstAccountingsType,Boolean taxToPay,Map<String,Sobject> mapDebitCredit){
       system.debug('lstAccountingsType 2:: 508 '+lstAccountingsType);
       Boolean allDmlSet = true;
       Decimal additionalPaymentToBookingTypeAccounting = 0.00;
       List<HBX_Accounting__c> newAccountings = new List<HBX_Accounting__c>();
       Boolean foundTax = false;
       Decimal totalDueAmountForInvoicefromAccountings = 0.00; 
       
       for(HBX_Accounting__c accCloned : lstAccountingsType){
           totalDueAmountForInvoicefromAccountings +=(accCloned.HBX_AmountDebit__c!=null?accCloned.HBX_AmountDebit__c:0.00);
       }
       system.debug('taxToPay 2:: '+taxToPay);
       
       for(HBX_Accounting__c accCloned : lstAccountingsType){
           accCloned.Id = null;
          if(taxToPay && accCloned.HBX_AccountingType__c=='Dept - Tax' || accCloned.HBX_AccountingType__c=='Receivable - Tax'){//|| accCloned.HBX_AccountingType__c=='Dept'
              foundTax = true;
              accCloned.HBX_Status__c = 'Matched';
              accCloned.HBX_AccountingType__c = 'Booking - Tax';
              accCloned.HBX_BankTransaction__c = transId;
              accCloned.HBX_CreditAccount__c = accCloned.HBX_ParentAccounting__r.HBX_CreditAccount__c;
              accCloned.HBX_DebitAccount__c = accCloned.HBX_ParentAccounting__r.HBX_DebitAccount__c;
              
            if(invoice.HBX_TaxAmount__c != null && transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c)>accCloned.HBX_AmountDebit__c){
                accCloned.HBX_PaidAmount__c = accCloned.HBX_AmountCredit__c;
                additionalPaymentToBookingTypeAccounting = transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c) - accCloned.HBX_AmountCredit__c;
            }else{
                accCloned.HBX_PaidAmount__c = transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c);
            }
            
            // for new tax accounting
            if(additionalPaymentToBookingTypeAccounting==0.00 && (accCloned.HBX_AmountCredit__c-transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c))>0){
                HBX_Accounting__c accounting = new HBX_Accounting__c();
                accounting.HBX_AccountingType__c = (rcName!=null && rcName == 'IncomingInvoice')?'Dept - Tax':'Receivable - Tax';
                accounting.HBX_Status__c = 'Open';
                accounting.HBX_ParentAccounting__c = accCloned.HBX_ParentAccounting__c;
                accounting.HBX_Invoice__c  = invoice.Id;
                accounting.HBX_AmountCredit__c = accCloned.HBX_AmountCredit__c-transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c);
                accounting.HBX_AmountDebit__c = accCloned.HBX_AmountCredit__c-transactionAmount*(invoice.HBX_TaxAmount__c/invoice.HBX_InvoiceAmountGross__c);
                
                if(accounting.HBX_AccountingType__c == 'Receivable - Tax'){
                    accounting.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(accounting.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null;
                    accounting.HBX_CreditAccount__c = accCloned.HBX_ParentAccounting__r.HBX_CreditAccount__c; 
                }else if(accounting.HBX_AccountingType__c == 'Dept - Tax'){
                    accounting.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(accounting.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(accounting.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
                    accounting.HBX_DebitAccount__c = accCloned.HBX_ParentAccounting__r.HBX_DebitAccount__c;
                }
                newAccountings.add(accounting);
            }
            accCloned.HBX_ParentAccounting__c = null; // if  HBX_AccountingType__c = 'Booking - Tax'
            accCloned.HBX_AmountCredit__c = accCloned.HBX_PaidAmount__c;
            accCloned.HBX_AmountDebit__c = accCloned.HBX_PaidAmount__c;
          }else{// for Booking Accountings
              system.debug('Entered here ::');
            if(additionalPaymentToBookingTypeAccounting!=0.00){
               accCloned.HBX_PaidAmount__c = ((transactionAmount )*((accCloned.HBX_AmountDebit__c!=null?accCloned.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings))+additionalPaymentToBookingTypeAccounting*((accCloned.HBX_AmountDebit__c!=null?accCloned.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            }else{
                accCloned.HBX_PaidAmount__c = (transactionAmount )*((accCloned.HBX_AmountDebit__c!=null?accCloned.HBX_AmountDebit__c:0.00)/totalDueAmountForInvoicefromAccountings);
            }
            
            accCloned.HBX_BankTransaction__c = transId;
            accCloned.HBX_Status__c = 'Matched';
            accCloned.HBX_AccountingType__c = 'Booking';
            accCloned.HBX_CreditAccount__c = accCloned.HBX_ParentAccounting__r.HBX_CreditAccount__c;
            accCloned.HBX_DebitAccount__c = accCloned.HBX_ParentAccounting__r.HBX_DebitAccount__c;
            
            system.debug('rcName :: '+rcName);
            HBX_Accounting__c newAccountingBooking = new HBX_Accounting__c();
            newAccountingBooking.HBX_AccountingType__c = (rcName!=null && rcName == 'IncomingInvoice')?'Dept':'Receivable';
            newAccountingBooking.HBX_Status__c = 'Open';
            newAccountingBooking.HBX_ParentAccounting__c = accCloned.HBX_ParentAccounting__c;
            newAccountingBooking.HBX_Invoice__c  = invoice.Id;
            newAccountingBooking.HBX_AmountCredit__c = accCloned.HBX_AmountDebit__c - accCloned.HBX_PaidAmount__c;
            newAccountingBooking.HBX_AmountDebit__c = accCloned.HBX_AmountDebit__c - accCloned.HBX_PaidAmount__c;
            
            if(newAccountingBooking.HBX_AccountingType__c == 'Receivable'){
                newAccountingBooking.HBX_DebitAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_DebitAccount__c'))):null):null;
                newAccountingBooking.HBX_CreditAccount__c = accCloned.HBX_ParentAccounting__r.HBX_CreditAccount__c;
            }else if(newAccountingBooking.HBX_AccountingType__c == 'Dept'){
                newAccountingBooking.HBX_CreditAccount__c = mapDebitCredit!=null?(mapDebitCredit.containsKey(newAccountingBooking.HBX_AccountingType__c)?(String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))=='null'?null:String.valueof(mapDebitCredit.get(newAccountingBooking.HBX_AccountingType__c).get('HBX_CreditAccount__c'))):null):null;
                newAccountingBooking.HBX_DebitAccount__c = accCloned.HBX_ParentAccounting__r.HBX_DebitAccount__c;
            }
            
            accCloned.HBX_AmountDebit__c = accCloned.HBX_PaidAmount__c;
            accCloned.HBX_AmountCredit__c = accCloned.HBX_PaidAmount__c;
            accCloned.HBX_ParentAccounting__c = null;  // if  HBX_AccountingType__c = 'Booking'  OR HBX_Status__c = 'Matched'
            
            newAccountings.add(newAccountingBooking);
          }
       }
       lstAccountingsType.addAll(newAccountings);
       system.debug(' lstAccountingsType :: '+lstAccountingsType);
       try {
           if(allDmlSet){
               insert lstAccountingsType;
           }
       }catch(Exception ee){
           system.debug('error lstAccountingsType :: '+ee.getMessage());
           allDmlSet = false;
       }
       try{
            if(allDmlSet){
                invoice.HBX_Status__c = 'Partially Paid';
                system.debug('invoice :: '+invoice);
                // update invoice;
            }
        }catch(Exception ee){
            allDmlSet = false;
            system.debug('error :: '+ee.getMessage());
        }
        return allDmlSet;
    }
    
    // public static Set<Id> updateMatchFailResonOnBankTransaction(List<HBX_Accounting__c> listOfAccounting){
    //     Set<Id> setOfAccountingId = new Set<Id>();
    //     Map<id,string> mapOfError = new Map<id,string>();
    //     Database.SaveResult[] saveResultListAcc = Database.insert(listOfAccounting, false); 
    //     integer count = -1;
    //     for (Database.SaveResult sr : saveResultListAcc) {
    //         count++;
    //         if (sr.isSuccess()) {
    //             setOfAccountingId.add(sr.getId());
    //         }
    //         else {             
    //             for(Database.Error err : sr.getErrors()) {
    //                 mapOfError.put(listOfAccounting[count].HBX_BankTransaction__c,err.getMessage());
    //             }
    //         }
    //     }
    //     system.debug('mapOfError :: '+mapOfError);
    //     List<HBX_BankTransaction__c> lstBankTransaction = [Select id,HBX_MatchFailReason__c from HBX_BankTransaction__c where id IN: mapOfError.keyset()];
    //     for(HBX_BankTransaction__c bankTransaction : lstBankTransaction){
    //         bankTransaction.HBX_MatchFailReason__c = mapOfError.get(bankTransaction.Id);
    //     }
    //     if(lstBankTransaction.size()>0){
    //         try{
    //             update lstBankTransaction;
    //         }catch(Exception ee){
                
    //         }
    //     }
    //     if(setOfAccountingId.size()>0){
    //         //updateStatusOnBankTransaction(listOfAccounting);
    //     }
    //     return setOfAccountingId;
    // }
    
    
    // public static void updateRentTimeStamp(Set<Id> setOfAccountingId) {
    //     Map<Id, DateTime> mapOfCreatedDateWithRentId =  new Map<Id, DateTime>();
    //     Set<Id> rentIdOfAutomaticMatchUpdate = new Set<Id>();
    //     for(HBX_Accounting__c objOfAccounting : [SELECT id, CreatedDate, HBX_IsAutomaticMatch__c, HBX_Rent__c from HBX_Accounting__c where Id IN : setOfAccountingId]){
    //         mapOfCreatedDateWithRentId.put(objOfAccounting.HBX_Rent__c,  objOfAccounting.CreatedDate);
    //         if(objOfAccounting.HBX_IsAutomaticMatch__c) {
    //             rentIdOfAutomaticMatchUpdate.add(objOfAccounting.HBX_Rent__c);               
    //         }
    //     }
    //     List<HBX_Rent__c> listOfRents = new List<HBX_Rent__c>();
    //     for(HBX_Rent__c objRent : [SELECT id, HBX_LastAutomaticMatchDate__c from HBX_Rent__c where id IN : mapOfCreatedDateWithRentId.keySet()]) {
    //         if(rentIdOfAutomaticMatchUpdate.contains(objRent.Id)) {
    //             objRent.HBX_LastAutomaticMatchDate__c = mapOfCreatedDateWithRentId.get(objRent.Id);
    //             listOfRents.add(objRent);
    //         }else {
    //             objRent.HBX_LastManualMatchDate__c =  mapOfCreatedDateWithRentId.get(objRent.Id); 
    //             listOfRents.add(objRent);
    //         }
    //     } 
    //     try{
    //         if(listOfRents.size()>0){
    //             update listOfRents;
    //         }
    //     } catch(Exception ex) {
    //         System.debug('ShowPropertyRentsController class at line no 216::'+ ex.getMessage());
    //     }
    // }  
    
    // retrieve total paid amount under a rent in current month.
     public static Map<Id,Decimal> retrievePaidRentAmountForRentInCurrentMonth(List<HBX_Invoice__c> lstRents){
         List<Id> RentIds = new List<Id>();
         Map<Id,Decimal> mapOfRentPaidAmount = new Map<Id,Decimal>();
         for(HBX_Invoice__c rent : lstRents){
             RentIds.add(rent.Id);
         }
         system.debug('RentIds : '+RentIds);
         for(AggregateResult accounting : [select HBX_Invoice__c,calendar_year(CreatedDate),SUM (HBX_PaidAmount__c) allAmount from HBX_Accounting__c GROUP BY HBX_Invoice__c,calendar_year(CreatedDate) HAVING HBX_Invoice__c =:RentIds]){//AND calendar_month(CreatedDate) =:System.today().month()
             
             if(accounting.get('allAmount') != null){
                 mapOfRentPaidAmount.put((Id) accounting.get('HBX_Invoice__c'),(Decimal) accounting.get('allAmount'));
             }else{
                 mapOfRentPaidAmount.put((Id) accounting.get('HBX_Invoice__c'),0);
             }
         }
         return mapOfRentPaidAmount;
     }
    
        // public static void updateStatusOnBankTransaction(List<HBX_Accounting__c> listOfAccounting) {
        //     Set<Id> setOfTransactionId = new Set<Id>();
        //     List<HBX_BankTransaction__c> listOfBankTransaction = new List<HBX_BankTransaction__c>();
        //     for(HBX_Accounting__c objAccounting : listOfAccounting) {
        //         if(objAccounting.Id!=null){
        //             setOfTransactionId.add(objAccounting.HBX_BankTransaction__c);
        //         }
        //     }
        //     for(HBX_BankTransaction__c objOfBankTransaction : [SELECT Id, HBX_Status__c FROM HBX_BankTransaction__c where Id =: setOfTransactionId]) {
        //         objOfBankTransaction.HBX_Status__c = 'Matched';
        //         listOfBankTransaction.add(objOfBankTransaction);
        //     }
        //     try{
        //         update listOfBankTransaction;
        //     }catch(DmlException ex){
        //         System.debug('DmlHandler class method updateStatusOnBankTransaction:: '+ex.getMessage());
        //     }
        // }
}