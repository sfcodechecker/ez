public with sharing class ChargeNowController{
    
    @AuraEnabled
    public static String StripeOneOffService(String recordId, Decimal Amount, String requestingURL){
        try{
            Contact con = [Select Id,Name,Email,Phone from Contact Where ID =: recordId WITH SECURITY_ENFORCED limit 1];            
            TransactionWrapper oneWrap = new TransactionWrapper();          
            oneWrap.name = con.Name;
            oneWrap.email = (con != null && con.Email != null) ? con.Email : '';
            oneWrap.amount = Amount;
            oneWrap.sfProcessingId = recordId;
            oneWrap.successURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__GatewayPostCheckout?customer_id=&type=onetime&record_id='+con.Id+'&requestedURL='+requestingURL+'&reference=stripe&status=accept';
            oneWrap.cancelURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__GatewayPostCheckout?customer_id=&type=onetime&record_id='+con.Id+'&requestedURL='+requestingURL+'&reference=stripe&status=cancel';
            
            oneWrap = StripeManager.requestOneTimePayment(oneWrap);
            String returnValue = (oneWrap.status ? 'valid:'+oneWrap.processingLink : oneWrap.errorResponse);
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            return returnValue;
        }
        catch(Exception ex){
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static List<Object> bpointOneOffService(String recordId, Decimal Amount, String chargeType){
        List<Object> result = new List<Object>();
        try{
            Contact con = [Select Id,FirstName,LastName,Email,Phone,Salutation from Contact Where ID =: recordId WITH SECURITY_ENFORCED Limit 1];
            BpointAuthKeyRequestWrapper reqWrap = new BpointAuthKeyRequestWrapper();
            reqWrap.ProcessTxnData = new BpointAuthKeyRequestWrapper.cls_ProcessTxnData();
            reqWrap.ProcessTxnData.Action = 'Payment';
            reqWrap.ProcessTxnData.Amount = String.valueOf(Amount);
            reqWrap.ProcessTxnData.TokenisationMode = 1;
            reqWrap.ProcessTxnData.SubType = chargeType;
            reqWrap.ProcessTxnData.Type = 'internet';
            reqWrap.ProcessTxnData.Customer = new BpointAuthKeyRequestWrapper.cls_Customer();
            reqWrap.ProcessTxnData.Customer.PersonalDetails = new BpointAuthKeyRequestWrapper.cls_PersonalDetails();
            reqWrap.ProcessTxnData.Customer.PersonalDetails.FirstName = con.FirstName;
            reqWrap.ProcessTxnData.Customer.PersonalDetails.LastName = con.LastName;
            reqWrap.ProcessTxnData.Customer.PersonalDetails.Salutation = con.Salutation;
            reqWrap.ProcessTxnData.Customer.ContactDetails = new BpointAuthKeyRequestWrapper.cls_ContactDetails();
            reqWrap.ProcessTxnData.Customer.ContactDetails.EmailAddress = con.Email;
            //reqWrap.RedirectionUrl = URL.getSalesforceBaseUrl().getHost() + '/apex/Q_Charge__BPointSomethingWentWrong';
            String URL = BPointHelper.ProcessOneTimeRequest(reqWrap,recordId);
            result.add('success');
            result.add(URL);
        }catch(Exception e){
            result.add('failed');
            result.add(e.getMessage());
        } 
        return result;
    }
    @AuraEnabled
    public static String EzidebitOneOffService(String recordId,Decimal amount,String requestUrl){
        String returnValue='';
        Payment_Log__c log=new Payment_Log__c(Gateway_Name__c = UtilGateway.EZIDEBITWORD, Processing_Record_Id__c=recordId,Amount__c=amount,Action__c= UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessOnetimePage,Charge_Type__c=UTILGateway.ONETIMEKEYWORD,Requesting_Url__c=requestUrl);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(log));
        try{
            returnValue=EzidebitHelper.ProcessOneTimeRequest(log);
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        }catch(Exception ex){
            returnValue = ex.getMessage();
        }
        return returnValue;
    }
    @AuraEnabled
    public static string SimplifyOneOffService(String recordId, Decimal amount,String requestUrl){
        String hostedPage=''; 
        if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
            Payment_Log__c log=new Payment_Log__c(Processing_Record_Id__c=recordId,Action__c = UTILGateway.SIMPLIFYWORD.capitalize() +''+MessageHandler.accessOnetimePage,Amount__c=Amount,Charge_Type__c=UTILGateway.ONETIMEKEYWORD,Gateway_Name__c=UTILGateway.SIMPLIFYWORD,Requesting_Url__c=requestUrl);
            try {
                hostedPage = SimplifyHelper.ProcessOneTimeRequest(log);
            } catch (Exception ex) {
                return ex.getMessage();
            }
        }
        return hostedPage;
    }
    
    @AuraEnabled
    public static String paywayOneOffService(String recordId, Decimal amount){
        String pawayCardDetailspage='';
        RecurringWrapper oneWrap = new RecurringWrapper();
        oneWrap.sfProcessingId=recordId;
        oneWrap.amount=amount;
        oneWrap.transactionType=UTILGateway.ONETIMEKEYWORD;
        try 
        {
            if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=recordId,Amount__c=amount,	Action__c=UTILGateway.PAYWAYWORD.capitalize() +''+MessageHandler.accessOnetimePage, Request_Type__c='POST', Charge_Type__c = UTILGateway.ONETIMEKEYWORD, Transaction_Status__c = 'Void', Gateway_Name__c=UTILGateway.PAYWAYWORD)));
                List<Payment_Log__c> loggedLog = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
                Payment_Log__c urlLog = loggedLog.get(loggedLog.size()-1);
                pawayCardDetailspage = PaywayHelper.requestPaymentURL(oneWrap);
                if(pawayCardDetailspage.startsWith('/apex/')){
                    pawayCardDetailspage = pawayCardDetailspage+''+urlLog.Id;
                }
            }
            
        } catch (Exception ex) {
            pawayCardDetailspage =  ex.getMessage();
        }
        return pawayCardDetailspage;
    }
    
    @AuraEnabled
    public static string NABTransactOneOffService(String recordId, Decimal amount){
        String returnValue = '';
        try {
            TransactionWrapper oneOffWrap = new TransactionWrapper();
            oneOffWrap.amount = amount;
            oneOffWrap.sfProcessingId = recordId;
            oneOffWrap.transactionType = UTILGateway.ONETIMEKEYWORD;
            
            oneOffWrap = NABTransactManager.requestOneTimePayment(oneOffWrap);
            if(oneOffWrap.status == true){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c=UTILGateway.NABTRANSWORD, Serialized_Record__c = JSON.serialize(oneOffWrap),Processing_Record_Id__c=recordId,Amount__c=amount,	Action__c = UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.accessOnetimePage, Request_Type__c='POST', Charge_Type__c = UTILGateway.ONETIMEKEYWORD, Transaction_Status__c = 'Void', End_Point__c = oneOffWrap.successURL)));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                returnValue = '/apex/Q_Charge__NABTransactCheckout?reference='+current_log.Id;
                return returnValue;
            }
            else{
                returnValue = oneOffWrap.errorResponse;
            } 
        } catch (Exception ex) {
            EmailHandler.sendExceptionEmail('ChargeNowController', ex, false);
            return ex.getMessage();
        }
        return returnValue;
    }
    
    @AuraEnabled
    public static List<ComboClass> InstalmentPeriodList(String GatewayName){
        List<ComboClass> cmblist = new List<ComboClass>();
        try{
            Frequency__mdt frequency = Frequency__mdt.getInstance(GatewayName.toLowerCase());
            if(frequency != null){                
                for(String eachPeriod : frequency.Instalment_Period__c.split(',')) { 
                    cmblist.add(new ComboClass(eachPeriod,eachPeriod,false));
                }
            }
        }catch(Exception ex){
        }
        return cmblist;
    }

    @AuraEnabled
    public static List<ComboClass> ActivePaymentList(){
        List<ComboClass> cmblist = new List<ComboClass>();
        try{
            String defaultGateway = '';    
            for(Gateway_Detail__c gateWay : [Select Id,Name__c,Default__c From Gateway_Detail__c Where Name__c != null and Default__c = true WITH SECURITY_ENFORCED] ) {
                defaultGateway =  gateWay.Name__c;
            } 
            try{
                if(EzidebitManager.isConnected)
                cmblist.add(new ComboClass(UTILGateway.EZIDEBITWORD.toUpperCase() ,UTILGateway.EZIDEBITWORD,(UTILGateway.EZIDEBITWORD == defaultGateway ? true: false)));
            }catch(GatewayException ex){}         
            try{
                if(StripeManager.isConnected)
                cmblist.add(new ComboClass(UTILGateway.STRIPEWORD.toUpperCase() ,UTILGateway.STRIPEWORD,(UTILGateway.STRIPEWORD == defaultGateway ? true: false))); 
            }catch(GatewayException ex){}
            try{
                if(PaywayManager.isConnected)
                cmblist.add(new ComboClass(UTILGateway.PAYWAYWORD.toUpperCase() ,UTILGateway.PAYWAYWORD,(UTILGateway.PAYWAYWORD == defaultGateway ? true: false)));
            }catch(GatewayException ex){}
            try{
                if(SimplifyManager.isConnected)
                cmblist.add(new ComboClass(UTILGateway.SIMPLIFYWORD.toUpperCase() ,UTILGateway.SIMPLIFYWORD,(UTILGateway.SIMPLIFYWORD == defaultGateway ? true: false)));
            }catch(GatewayException ex){}
            try{
                if(BPointManager.isConnected)
                cmblist.add(new ComboClass(UTILGateway.BPOINTWORD.toUpperCase() ,UTILGateway.BPOINTWORD,(UTILGateway.BPOINTWORD == defaultGateway ? true: false)));
            }catch(GatewayException ex){}
            try{
                if(NABTransactManager.isConnected)
                cmblist.add(new ComboClass(UTILGateway.NABTRANSWORD.replaceAll('_', ' ').toUpperCase() ,UTILGateway.NABTRANSWORD,(UTILGateway.NABTRANSWORD == defaultGateway ? true: false)));
            }catch(GatewayException ex){}
            
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            for(integer i=0;i<cmblist.size();i++){
                ComboClass gatewaydetail = cmblist.get(i);
                if(i==0 && gatewaydetail.isdefault==true){
                    break;
                }else if(gatewaydetail.isdefault==true){
                    ComboClass tempGateway = cmblist.get(0);
                    cmblist.set(0,gatewaydetail);
                    cmblist.set(i,tempGateway);
                }
            }
        }catch(Exception ex){
        }
        return cmblist;
    }
    
    // Method for Schedule[Recurring] payments.
    
    @AuraEnabled
    public static String StripeScheduleService(String recordId, Decimal Amount, String InstalPeriod, String StartDate, String requestingURL){
        try{
            Contact con = [Select Id,Name,Email,Phone from Contact Where ID =: recordId WITH SECURITY_ENFORCED limit 1 ];             
            RecurringWrapper recurrWrap = new RecurringWrapper();          
            recurrWrap.name = con.Name;
            recurrWrap.email = (con != null && con.Email != null) ? con.Email : '';
            recurrWrap.amount = Amount;
            recurrWrap.sfProcessingId = recordId;
            recurrWrap.instalPeriod = InstalPeriod;          
            recurrWrap.startDate = Date.valueOf(StartDate);
            recurrWrap.successURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__GatewayPostCheckout?customer_id=&type=recurring&record_id='+con.Id+'&requestedURL='+requestingURL+'&reference=stripe&status=accept';
            recurrWrap.cancelURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__GatewayPostCheckout?customer_id=&type=recurring&record_id='+con.Id+'&requestedURL='+requestingURL+'&reference=stripe&status=cancel';
            recurrWrap = StripeManager.requestRecurringPayment(recurrWrap);
            
            String returnValue = (recurrWrap.status ? 'valid:'+recurrWrap.processingLink : recurrWrap.errorResponse);
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            return returnValue;
        }
        catch(Exception ex){
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static List<Object> BpointScheduleService(String recordId, Decimal Amount, String InstalPeriod, String StartDate){
        List<Object> result = new List<Object>();
        try{
            Contact con = [Select Id,FirstName,LastName,Email,Phone,Salutation from Contact Where ID =: recordId WITH SECURITY_ENFORCED Limit 1];
            BpointAuthKeyRequestWrapper reqWrap = new BpointAuthKeyRequestWrapper();
            reqWrap.ProcessTxnData = new BpointAuthKeyRequestWrapper.cls_ProcessTxnData();
            reqWrap.ProcessTxnData.Action = 'Payment';
            reqWrap.ProcessTxnData.Amount = String.valueOf(Amount);
            reqWrap.ProcessTxnData.TokenisationMode = 1;
            reqWrap.ProcessTxnData.SubType = 'recurring';
            reqWrap.ProcessTxnData.Type = 'internet';
            reqWrap.ProcessTxnData.Customer = new BpointAuthKeyRequestWrapper.cls_Customer();
            reqWrap.ProcessTxnData.Customer.PersonalDetails = new BpointAuthKeyRequestWrapper.cls_PersonalDetails();
            reqWrap.ProcessTxnData.Customer.PersonalDetails.FirstName = con.FirstName;
            reqWrap.ProcessTxnData.Customer.PersonalDetails.LastName = con.LastName;
            reqWrap.ProcessTxnData.Customer.PersonalDetails.Salutation = con.Salutation;
            reqWrap.ProcessTxnData.Customer.ContactDetails = new BpointAuthKeyRequestWrapper.cls_ContactDetails();
            reqWrap.ProcessTxnData.Customer.ContactDetails.EmailAddress = con.Email;
            //reqWrap.RedirectionUrl = URL.getSalesforceBaseUrl().getHost() + '/apex/Q_Charge__BPointSomethingWentWrong';
            String URL = BPointHelper.ProcessRecurringRequest(reqWrap,recordId,InstalPeriod,StartDate);
            result.add('success');
            result.add(URL);
        }catch(Exception e){
            result.add('failed');
            result.add(e.getMessage());
        } 
        return result;
    }
    
    @AuraEnabled
    public static String EzidebitScheduleService(String recordId, Decimal Amount, String InstallPeriod, String StartDate,String requestUrl){
        String value='';
        Payment_Log__c log = new Payment_Log__c(Gateway_Name__c = UtilGateway.EZIDEBITWORD, Processing_Record_Id__c=recordId,Amount__c=Amount,Frequency__c=InstallPeriod,Recurring_Start_Date__c=Date.valueOf(StartDate),Action__c=UTILGateway.EZIDEBITWORD.capitalize() +''+MessageHandler.accessRecPayPage,Charge_Type__c=UTILGateway.RecurringKEYWORD,Requesting_Url__c=requestUrl);
        try{
            value=EzidebitHelper.ProcessRecurringRequest(log);
        }
        catch(Exception ex){
            value = MessageHandler.wentWrongCatchMessage;
        }
        return value;
    }
    
    @AuraEnabled
    public static String SimplifyScheduleService(String recordId, Decimal Amount, String InstalPeriod, String StartDate){
        String value = '';
        try{
            Payment_Log__c log=new Payment_Log__c(Gateway_Name__c = UtilGateway.SIMPLIFYWORD,Processing_Record_Id__c=recordId,Action__c=UTILGateway.SIMPLIFYWORD.capitalize() +''+MessageHandler.accessRecPayPage,Amount__c=Amount,Frequency__c=InstalPeriod,Recurring_Start_Date__c=Date.valueOf(StartDate));
            value = SimplifyHelper.ProcessRecurringPaymentRequest(log);
        }
        catch(Exception ex){
            value = MessageHandler.wentWrongCatchMsgFun(ex.getMessage());
        }
        return value;
    }
    
    @AuraEnabled
    public static String paywayScheduleService(String recordId, Decimal amount, String installPeriod, String startDate){
        String pawayCardDetailspage = '';
        try{
            RecurringWrapper reccWrapper = new RecurringWrapper();
            reccWrapper.amount = amount;
            reccWrapper.sfProcessingId = recordId;
            reccWrapper.instalPeriod = (installPeriod=='Half Yearly')?'six-monthly':installPeriod;          //changed KW
            reccWrapper.startDate = Date.valueOf(startDate);
            reccWrapper.transactionType = UTILGateway.RECURRINGKEYWORD;

            if(UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','create')){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c=UTILGateway.PAYWAYWORD,Processing_Record_Id__c=recordId,Amount__c=amount,	Action__c = UTILGateway.PAYWAYWORD.capitalize() +''+MessageHandler.accessRecPayPage, Request_Type__c='POST', Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Frequency__c = installPeriod, Transaction_Status__c = 'Void', Recurring_Start_Date__c = Date.valueOf(startDate))));
                List<Payment_Log__c> loggedLog = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
                Payment_Log__c urlLog = loggedLog.get(loggedLog.size()-1);
                pawayCardDetailspage = PaywayHelper.requestPaymentURL(reccWrapper);
                if(pawayCardDetailspage.startsWith('/apex/')){
                    pawayCardDetailspage = pawayCardDetailspage+''+urlLog.Id;
                }
            }      
        }
        catch(Exception ex){
            pawayCardDetailspage = ex.getMessage();
        }
        return pawayCardDetailspage;
    }
    @AuraEnabled
    public static String NABTransactScheduleService(String recordId, Decimal amount, String installPeriod, String startDate){
        String returnValue = '';
        try{
            RecurringWrapper recurringWrap = new RecurringWrapper();
            recurringWrap.sfProcessingId = recordId;
            recurringWrap.amount = amount;
            recurringWrap.instalPeriod = installPeriod;
            recurringWrap.startDate = Date.valueOf(startDate);
            recurringWrap.transactionType = UTILGateway.RECURRINGKEYWORD;
            recurringWrap = NABTransactManager.requestRecurringPayment(recurringWrap); 
            
            if(recurringWrap.status == true){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c=UTILGateway.NABTRANSWORD, Serialized_Record__c = JSON.serialize(recurringWrap) ,Processing_Record_Id__c=recordId,Amount__c=amount,	Action__c=UTILGateway.NABTRANSWORD.capitalize() +''+MessageHandler.accessRecPayPage, Request_Type__c='POST', Charge_Type__c = UTILGateway.RECURRINGKEYWORD, Frequency__c = installPeriod, End_Point__c = recurringWrap.successURL, Transaction_Status__c = 'Void', Recurring_Start_Date__c = Date.valueOf(startDate))));
                List<Payment_Log__c> new_log = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON); 
                Payment_Log__c current_log = new_log.get(new_log.size()-1);
                returnValue = '/apex/Q_Charge__NABTransactCheckout?reference='+current_log.Id;
                return returnValue;
            }
            else{
                returnValue = recurringWrap.errorResponse;
            } 
        }
        catch(Exception ex){
            EmailHandler.sendExceptionEmail('ChargeNowController', ex, false);
            returnValue = ex.getMessage();
        }
        return returnValue;
    }
    
    
    public class ComboClass{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isdefault; 
        
        public ComboClass(String l, String v, Boolean def){
            this.label = l;
            this.value = v;
            this.isdefault = def;
        }
    }
    
    // Sends an Exception email to support.    
    @AuraEnabled
    public static void sendExceptionEmail(String emailBody){
        EmailHandler.sendEmailTo('Error occurred during the process', emailBody, null, false);
    }
    
}