public with sharing class StripeManager {   
    
    /*********************** URL to be Hit ********************************/
    public static FINAL String StripeCharges = 'https://api.stripe.com/v1/charges';    
    public static FINAL String StripeProducts = 'https://api.stripe.com/v1/products';   
    public static FINAL String StripeCustomers = 'https://api.stripe.com/v1/customers'; 
    public static FINAL String StripePlans = 'https://api.stripe.com/v1/plans';  
    public static FINAL String StripeOneTimeCheckoutSessions = 'https://api.stripe.com/v1/checkout/sessions'; 
    public static FINAL String StripeScheduleCheckoutSessions = 'https://api.stripe.com/v1/checkout/sessions';   
    public static FINAL String StripePaymentIntents = 'https://api.stripe.com/v1/payment_intents'; 
    public static FINAL String StripeSubscriptions = 'https://api.stripe.com/v1/subscriptions';     
    public static FINAL String StripeInvoiceParam = 'https://api.stripe.com/v1/invoices?limit=100&starting_after=&collection_method=charge_automatically&status=paid&subscription='; // While using the below StripeInvoiceParam take care of starting_after parameter, it needs the invoice Id, or replace if its first fetch.
    public static FINAL String StripeUpcomingInvoice = 'https://api.stripe.com/v1/invoices/upcoming?subscription='; 
    public static FINAL String StripePaymentMethod = 'https://api.stripe.com/v1/payment_methods'; 
    public static FINAL String StripeSetupIntents = 'https://api.stripe.com/v1/setup_intents'; 
    
    public static FINAL String OneTimeKeyWord = 'One Time';  
    public static FINAL String RecurringKeyWord = 'Recurring';  
    
    /*********************** variables ********************************/ 
    public static Gateway_Detail__c StripeGateWay; 
    public static String detachedReason = null;   // WouldBeGlobal
    public static Boolean isConnected = false;  // WouldBeGlobal
    public static String StripeDefaultProductName = 'EzyCharge Product'; 
    
    public static Integer maxlength = 131070; // Max number of charcter allowed to be stored in HTTP Response.
    
    /***********Static methods ***********/
    static {
        if([Select Id  from Gateway_Detail__c where Name__c = :UTILGateway.STRIPEWORD WITH SECURITY_ENFORCED].size() == 1){
            StripeGateWay = UTILGateway.decodeKeys(UTILGateway.STRIPEWORD);    
            try{
                String credChecking = validateCredentials(StripeGateWay, false);
                isConnected = (credChecking == 'valid' ? true : false);
                detachedReason = (credChecking != 'valid' ? credChecking : detachedReason);
            }catch(Exception ex){
                detachedReason = MessageHandler.apiKeyMissing+' Due to '+ex.getMessage()+'.';
            }     
        } else {
            detachedReason = MessageHandler.apiKeyMissing;
        }
        //Similarly check for licenses and FPs
    }
    
    
    /*********************** WouldBeGlobal Check the stripe credentials ********************************/
    public static String validateCredentials(Gateway_Detail__c Gateway, Boolean createLog){   
        if(detachedReason != null && detachedReason != MessageHandler.apiKeyMissing)
        throw new GatewayException(detachedReason);
        String returnValue = '';
        HTTPResponse responseKey = hitEndpoint(StripeCharges,'GET',Gateway.Client_Key__c,null);
        if(createLog){
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.checkCredential, End_Point__c = StripeCharges,Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength) ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
        }
        
        if(responseKey?.getStatusCode() == 200 && Gateway.Optional_Key_1__c != null ){
            HTTPResponse responseProduct = hitEndpoint(StripeProducts+'/'+EncodingUtil.urlEncode(Gateway.Optional_Key_1__c,'utf-8'),'POST',Gateway.Client_Key__c,null);  
            if(createLog){
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.checkProductid, End_Point__c = StripeProducts+'/'+EncodingUtil.urlEncode(Gateway.Optional_Key_1__c,'utf-8'), Request_Type__c = 'POST', HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()),HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); 
            }
            if(responseProduct?.getStatusCode() != 200){  
                returnValue = StripeErrorWrapper.DeserializeErrorResponse(responseProduct.getBody()).error.message;
            }
            returnValue = 'valid';
        }else{
            returnValue = (Gateway.Optional_Key_1__c != null ? StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message : MessageHandler.loginFailed);
        }      
        return returnValue;
    }
    
    /*********************** WouldBeGlobal create a one off payment session ********************************/
    public static TransactionWrapper requestOneTimePayment(TransactionWrapper req){
        req.status = false;  
        if(req.name != null && req.email != null && req.successURL != null && req.cancelURL != null && req.amount != null && req.sfProcessingId != null){         
            StripeCustomerWrapper custWrap = new StripeCustomerWrapper();
            custWrap.name =  req.name;
            custWrap.email = req.email;            
            String cust = createStripeCustomer(custWrap); 
            req.errorResponse = cust; 
            if(cust.startsWith('valid')){
                cust = cust.substringAfter(':');
                String value = StripeCheckoutInitiator(cust,req.successURL.replace('customer_id=','customer_id='+cust),req.cancelURL.replace('customer_id=','customer_id='+cust),req.amount,req.sfProcessingId);
                req.errorResponse = value; 
                if(value.startsWith('valid')){
                    req.status = true;
                    req.processingLink = '/apex/Q_Charge__StripeCheckOut?session_id='+value.substringAfter(':');
                }
            } 
        }else{
            req.errorResponse = MessageHandler.payError;
        }
        return req;
    }
    
    /*********************** WouldBeGlobal create a recurring payment session ********************************/
    public static RecurringWrapper requestRecurringPayment(RecurringWrapper req){
        req.status = false;    
        if(req.name != null && req.email != null && req.successURL != null && req.cancelURL != null && req.instalPeriod != null && req.amount != null && req.sfProcessingId != null && req.startDate != null){         
            StripeCustomerWrapper custWrap = new StripeCustomerWrapper();
            custWrap.name =  req.name;
            custWrap.email = req.email;            
            String cust = createStripeCustomer(custWrap); 
            req.errorResponse = cust;
            if(cust.startsWith('valid')){
                cust = cust.substringAfter(':');
                String plan = createStripePlan(StripeScheduleHandler.createStripePlanWrapper(req.amount,req.instalPeriod));
                req.errorResponse = plan;
                if(plan.startsWith('valid')){
                    plan = plan.substringAfter(':');
                    String value = StripeCheckoutScheduleSession(cust,plan,req.successURL.replace('customer_id=','customer_id='+cust),req.cancelURL.replace('customer_id=','customer_id='+cust),req.instalPeriod,req.startDate,req.amount,req.sfProcessingId);
                    req.errorResponse = value;
                    if(value.startsWith('valid')){
                        req.status = true;
                        req.processingLink = '/apex/Q_Charge__StripeCheckOut?session_id='+value.substringAfter('valid:');
                    } 
                } 
            } 
        }else{
            req.errorResponse = MessageHandler.payError;
        }
        return req;
    }
    
    
    /*********************** WouldBeGlobal create a recurring payment session ********************************/
    public static TransactionWrapper getTransaction(TransactionWrapper req){
        req.status = false;    
        if(req.paymentId != null && req.sfProcessingId != null){
            
            HttpResponse response = hitEndpoint(StripeOneTimeCheckoutSessions+'/'+req.paymentId ,'GET', StripeGateWay.Client_Key__c, null);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.checkCheckoutProcessing, End_Point__c = StripeOneTimeCheckoutSessions+'/'+req.paymentId, Request_Type__c = 'GET', HTTP_Response_Code__c = String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
            if(response.getStatusCode() == 200){
                StripeCheckoutWrapper CheckOut =  StripeCheckoutWrapper.DeserializeCheckOutResponse(response.getBody());
                response = hitEndpoint(StripePaymentIntents+'/'+CheckOut.payment_intent,'GET',StripeGateWay.Client_Key__c, null);                  
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.chekTransactinStatus, End_Point__c = StripePaymentIntents+'/'+CheckOut.payment_intent, Request_Type__c = 'GET', HTTP_Response_Code__c = String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength), Processing_Record_Id__c = req.sfProcessingId, Payment_Parameter_2__c = req.paymentId ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                if(response.getStatusCode() == 200){
                    StripePaymentIntent payIntent = (StripePaymentIntent)JSON.deserialize(response.getBody(), StripePaymentIntent.class);
                    Integer index = (UTILGateway.PayLogSet_JSON.size() - 1);
                    Payment_Log__c payLog = (Payment_Log__c)JSON.deserialize(UTILGateway.PayLogSet_JSON.get(index),Sobject.class);
                    payLog.Transaction_Id__c = payIntent.Id;
                    payLog.Transaction_Status__c = payIntent.status;  
                    payLog.Amount__c = convertCentToDollar(payIntent.amount);            
                    payLog.Charge_Type__c = OneTimeKeyWord;
                    
                    // remove last elemenet from log and add new one.
                    UTILGateway.PayLogSet_JSON.remove(index);
                    UTILGateway.PayLogSet_JSON.add(JSON.serialize(payLog));
                    
                    if(payIntent?.status =='succeeded'){ 
                        req.status = true;                                 
                        req.amount = convertCentToDollar(payIntent.amount); 
                        req.transactionId = payIntent.id;
                        req.paymentId = payIntent.id;
                        req.transactionStatus = payIntent.status;
                        req.transactionDate = DateTime.newInstance(Long.valueOf(String.valueOf(payIntent.created)+ '000')).date();
                        req.transactionType = OneTimeKeyWord; 
                        req.transResponse = JSON.serialize(payIntent);
                    }
                    else if(payIntent?.status =='canceled'){ 
                        req.errorResponse  = MessageHandler.payIntent_cancel;
                    }
                    else if(payIntent?.status =='requires_payment_method'){ 
                        req.errorResponse  = MessageHandler.payIntent_requires_payment_method;
                    }
                    else if(payIntent?.status =='requires_confirmation'){ 
                        req.errorResponse  = MessageHandler.payIntent_requires_confirmation;
                    }
                    else if(payIntent?.status =='requires_action'){ 
                        req.errorResponse  = MessageHandler.payIntent_requires_action;
                    }
                    else if(payIntent?.status =='processing'){ 
                        req.errorResponse  = MessageHandler.payIntent_processing;
                    }    
                }
                else{
                    req.errorResponse = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message; 
                }
            } else {
                req.errorResponse = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message; 
            }
        }else{
            req.errorResponse = MessageHandler.payError;
        }
        return req;
    }
    
    
    /*********************** WouldBeGlobal fetch a recurring payment details with transactions ********************************/
    public static RecurringWrapper getTransactionRP(RecurringWrapper req, String FetchingInvoiceFilter){
        req.status = false;  
        if(req.recurringRequestId != null && req.sfProcessingId != null && req.instalPeriod != null){ 
            HttpResponse response = hitEndpoint(StripeSubscriptions+'/'+req.recurringRequestId,'GET', StripeGateWay.Client_Key__c, null);                  
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchRPDetails, End_Point__c = StripeSubscriptions+'/'+req.recurringRequestId, Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength), Processing_Record_Id__c = req.sfProcessingId, Payment_Parameter_2__c = req.recurringRequestId, Frequency__c = req.instalPeriod ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
            if(response.getStatusCode() == 200){                
                HTTPResponse transactRes;
                Boolean hasMoreInvoice = false;
                String latestInvoiceId = '';
                List<TransactionWrapper> transList = new List<TransactionWrapper>();
                
                StripeSubscriptionWrapper ScheduleWrapper = StripeSubscriptionWrapper.DeserializeSubscriptionResponse(response.getBody());
                
                ScheduleWrapper.RelatedToId = req.sfProcessingId;
                ScheduleWrapper.Installment_Period = req.instalPeriod;
                
                if(ScheduleWrapper.default_payment_method != null){
                    transactRes = hitEndpoint(StripePaymentMethod+'/'+ScheduleWrapper.default_payment_method,'GET',StripeGateWay.Client_Key__c,null);  
                    System.debug(' transactRes222 :'+transactRes.getBody());
                    UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchPayMethodofscheule, End_Point__c = StripePaymentMethod+'/'+ScheduleWrapper.default_payment_method,Request_Type__c = 'GET', HTTP_Response_Code__c = String.valueOf(transactRes.getStatusCode()), HTTP_Response__c = transactRes.getBody().abbreviate(maxlength) ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                    
                    if(transactRes.getStatusCode() == 200){
                        StripePaymentMethodwrapper paymethod = StripePaymentMethodwrapper.parse(transactRes.getBody());
                        ScheduleWrapper.default_pay_method = paymethod;
                    }else{
                        req.errorResponse = StripeManager.StripeErrorWrapper.DeserializeErrorResponse(transactRes.getBody()).error.message; 
                    }
                    
                }
                
                Integer index = (UTILGateway.PayLogSet_JSON.size() - 1);
                Payment_Log__c payLog = (Payment_Log__c)JSON.deserialize(UTILGateway.PayLogSet_JSON.get(index),Sobject.class);
                // Only storing the subsctiption Id, Not storing the subscription item id.
                payLog.Transaction_Id__c = ScheduleWrapper.Id;  
                payLog.Transaction_Status__c = ScheduleWrapper.status;
                payLog.Charge_Type__c = RecurringKeyWord;
                payLog.Amount__c = convertCentToDollar(ScheduleWrapper.plan.amount);
                // remove last elemenet from log and add new one.
                UTILGateway.PayLogSet_JSON.remove(index);
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(payLog));                    
                
                do{
                    String endpoint = ( hasMoreInvoice ? StripeInvoiceParam.replace('&starting_after=', '&starting_after='+latestInvoiceId)+''+ScheduleWrapper.id : StripeInvoiceParam.replace('&starting_after=', '')+''+ScheduleWrapper.id); 
                    if(FetchingInvoiceFilter != null)
                    endpoint = endpoint+FetchingInvoiceFilter;
                    transactRes = hitEndpoint(endpoint,'GET',StripeGateWay.Client_Key__c,null);  
                    System.debug(' transactRes111 :'+transactRes.getBody());
                    UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchRecurringPayments, End_Point__c = StripeInvoiceParam+''+ScheduleWrapper.id,Request_Type__c = 'GET', HTTP_Response_Code__c = String.valueOf(transactRes.getStatusCode()), HTTP_Response__c = transactRes.getBody().abbreviate(maxlength) ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                    
                    if(transactRes.getStatusCode() == 200){                         
                        StripeInvoiceWrapper fetchedInvoices = StripeInvoiceWrapper.parse(transactRes.getBody());
                        if(fetchedInvoices != null && fetchedInvoices.data != null && fetchedInvoices.data.size() > 0) {
                            for(StripeInvoiceWrapper.data invoice : fetchedInvoices.data){
                                if(invoice.amount_paid > 0){                                        
                                    TransactionWrapper eachTranct = new TransactionWrapper();
                                    eachTranct.amount = convertCentToDollar(invoice.amount_paid); 
                                    eachTranct.transactionId = invoice.id;
                                    eachTranct.paymentId = invoice.payment_intent;
                                    eachTranct.transactionStatus = invoice.status;
                                    eachTranct.transactionDate = DateTime.newInstance(Long.valueOf(String.valueOf(invoice.created)+ '000')).date(); 
                                    eachTranct.transactionType = RecurringKeyWord; 
                                    transList.add(eachTranct);
                                }
                            }
                            latestInvoiceId = fetchedInvoices.data[fetchedInvoices.data.size() - 1].id;   
                        } 
                        hasMoreInvoice = (fetchedInvoices != null && fetchedInvoices.has_more ? true : false); 
                    }else{                
                        req.errorResponse = StripeManager.StripeErrorWrapper.DeserializeErrorResponse(transactRes.getBody()).error.message;
                        hasMoreInvoice = false;
                    }
                }while(hasMoreInvoice);
                
                // poulate upcoming invoices.
                
                transactRes = hitEndpoint(StripeUpcomingInvoice+''+ScheduleWrapper.Id,'GET',StripeGateWay.Client_Key__c,null);  
                System.debug(' transactRes :'+transactRes.getBody());
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchUpcomingInvoice, End_Point__c = StripeUpcomingInvoice+''+ScheduleWrapper.Id,Request_Type__c = 'GET', HTTP_Response_Code__c = String.valueOf(transactRes.getStatusCode()), HTTP_Response__c = transactRes.getBody().abbreviate(maxlength) ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                
                if(transactRes.getStatusCode() == 200){
                    StripeUpcomingInvoiceWrapper upcomingInv = StripeUpcomingInvoiceWrapper.parse(transactRes.getBody());
                    if(upcomingInv.amount_due > 0){                                        
                        TransactionWrapper upComingTranct = new TransactionWrapper();
                        upComingTranct.amount = convertCentToDollar(upcomingInv.amount_due); 
                        upComingTranct.transactionId = upcomingInv.customer+''+upcomingInv.subscription;
                        upComingTranct.paymentId = upcomingInv.customer+''+upcomingInv.subscription;
                        upComingTranct.transactionStatus = upcomingInv.status;
                        upComingTranct.transactionDate = DateTime.newInstance(Long.valueOf(String.valueOf(upcomingInv.next_payment_attempt)+ '000')).date(); 
                        upComingTranct.transactionType = RecurringKeyWord; 
                        transList.add(upComingTranct);
                    }                    
                }else{
                    req.errorResponse = StripeManager.StripeErrorWrapper.DeserializeErrorResponse(transactRes.getBody()).error.message; 
                }
                

                if(ScheduleWrapper != null){                                       
                    req.transactionList = (!transList.isEmpty() ? transList: null);
                    req.status = true; 
                    req.recurringResponse  = JSON.serialize(ScheduleWrapper); 
                }else{
                    req.status = false;
                    req.errorResponse = MessageHandler.wentWrongCatchMessage+' '+req.errorResponse; 
                }             
            }
            else{
                req.errorResponse = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message; 
            }
        }else{
            req.errorResponse = MessageHandler.payError;
        }
        return req;
    }
    
    
    /*********************** recurring payment session response ********************************/
    public static RecurringWrapper getTransactionRPbyCheckout(RecurringWrapper req){
        req.status = false;    
        if(req.recurringRequestId != null && req.sfProcessingId != null && req.instalPeriod != null){ 
            HttpResponse response = hitEndpoint(StripeOneTimeCheckoutSessions+'/'+req.recurringRequestId,'GET', StripeGateWay.Client_Key__c, null);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.checkScheduleSession, End_Point__c = StripeOneTimeCheckoutSessions+'/'+req.recurringRequestId, Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
            if(response.getStatusCode() == 200){
                StripeCheckoutWrapper CheckOut =  StripeCheckoutWrapper.DeserializeCheckOutResponse(response.getBody());
                req.recurringRequestId = CheckOut.subscription;
                req = getTransactionRP(req, null);
            }else {
                req.errorResponse = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message; 
            }
        }else{
            req.errorResponse = MessageHandler.payError;
        }
        return req;
    }
    
    
    /*********************** Maintain the stripe credentials, check the keys and also manage product ********************************/
    public static String PostCredentails(Gateway_Detail__c Gateway){ 
        if(detachedReason != null && detachedReason != MessageHandler.apiKeyMissing)
        throw new GatewayException(detachedReason);
        String returnValue = '';  
        HTTPResponse responseKey = hitEndpoint(StripeCharges,'GET',Gateway.Client_Key__c,null); 
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.verifyCredBeforeStore, End_Point__c = StripeCharges,Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
        if(responseKey?.getStatusCode() == 200){ 
            Boolean createProduct = true;
            if(Gateway.Optional_Key_1__c != null){
                HTTPResponse responseProduct = hitEndpoint(StripeProducts+'/'+EncodingUtil.urlEncode(Gateway.Optional_Key_1__c,'utf-8'),'POST',Gateway.Client_Key__c,null);                
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.verifyProdIdBeforeStore, End_Point__c = StripeProducts+'/'+EncodingUtil.urlEncode(Gateway.Optional_Key_1__c,'utf-8'), Request_Type__c = 'POST', HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                if(responseProduct?.getStatusCode() == 200)
                createProduct = false;                
            }                   
            if(createProduct){                     
                StripeProductWrapper product = new StripeProductWrapper(StripeDefaultProductName,'service');
                HTTPResponse responseNewProduct = hitEndpoint(StripeProducts,'POST',Gateway.Client_Key__c,StripeProductWrapper.createProductPayLoad(product));                
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.createProdIdBeforeStoe, End_Point__c = StripeProducts,Request_Type__c = 'POST',HTTP_Response_Code__c = String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength), Payload__c = StripeProductWrapper.createProductPayLoad(product),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                if(responseNewProduct?.getStatusCode() == 200){
                    StripeProductWrapper productwrapper = StripeProductWrapper.DeserializeProductResponse(responseNewProduct.getBody());
                    Gateway.Optional_Key_1__c = productwrapper.id;
                }else{
                    returnValue = StripeErrorWrapper.DeserializeErrorResponse(responseNewProduct.getBody()).error.message; 
                } 
            }
            returnValue = 'valid:'+Gateway.Optional_Key_1__c;
        }else{
            returnValue = StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
        } 
        return returnValue;
    }
    
    
    /*********************** Check the stripe credentials ********************************/
    public static String CheckExistingCredentails(){   
        if(detachedReason != null)
        throw new GatewayException(detachedReason);
        return validateCredentials(StripeGateWay, false);
    }
    
    /*********************** create a customer in stripe ********************************/
    public static String createStripeCustomer(StripeCustomerWrapper customer){ 
        if(detachedReason != null)
        throw new GatewayException(detachedReason);
        String returnValue = '';
        HTTPResponse response = hitEndpoint(StripeCustomers,'POST',StripeGateWay.Client_Key__c,StripeCustomerWrapper.createCustomerPayLoad(customer));
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.createCustomer, End_Point__c = StripeCustomers,Request_Type__c = 'POST', Payload__c =  StripeCustomerWrapper.createCustomerPayLoad(customer), HTTP_Response_Code__c =String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
        if(response?.getStatusCode() == 200){      
            StripeCustomerWrapper createdCust =  StripeCustomerWrapper.DeserializeCustomerResponse(response.getBody());      
            returnValue = 'valid:'+createdCust.Id;
        }else{
            returnValue = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message;
        } 
        return returnValue;
    }
    
    /*********************** create a plan in stripe ********************************/
    public static String createStripePlan(StripePlanWrapper plan){ 
        if(detachedReason != null)
        throw new GatewayException(detachedReason);
        String returnValue = '';
        HTTPResponse response = hitEndpoint(StripePlans,'POST',StripeGateWay.Client_Key__c,StripePlanWrapper.createPlanPayLoad(plan));
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.createPlan, End_Point__c = StripePlans,Request_Type__c = 'POST', Payload__c =  StripePlanWrapper.createPlanPayLoad(plan), HTTP_Response_Code__c =String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
        if(response?.getStatusCode() == 200){      
            StripePlanWrapper createdPlan =  StripePlanWrapper.DeserializePlanResponse(response.getBody());      
            returnValue = 'valid:'+createdPlan.Id;
        }else{
            returnValue = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message;
        } 
        return returnValue;
    }
    
    /*********************** create a one off payment session ********************************/
    public static String StripeCheckoutOneOffSession(StripeCheckOutWrapper stripeRequest){
        if(detachedReason != null)
        throw new GatewayException(detachedReason);
        String returnValue = '';
        HTTPResponse response = hitEndpoint(StripeOneTimeCheckoutSessions,'POST',StripeGateWay.Client_Key__c,StripeCheckoutWrapper.createSessionPayLoad(stripeRequest));
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.oneTimeCheckoutSession, End_Point__c = StripeOneTimeCheckoutSessions,Request_Type__c = 'POST', Payload__c = StripeCheckoutWrapper.createSessionPayLoad(stripeRequest), HTTP_Response_Code__c = String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
        if(response?.getStatusCode() == 200){      
            StripeCheckoutWrapper responseCheckOut =  StripeCheckoutWrapper.DeserializeCheckOutResponse(response.getBody());
            returnValue = 'valid:'+responseCheckOut.Id;            
        }else{
            returnValue = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message;
        } 
        return returnValue;
    }
    
    /*********************** create a one off payment helper method ********************************/
    public static String StripeCheckoutInitiator(String CustId, String SuccessURL, String CancelUrl, Decimal PayAmount, String SFId ){
        if(detachedReason != null)
        throw new GatewayException(detachedReason); 
        StripeCheckoutWrapper checkout = new StripeCheckoutWrapper();
        checkout.payment_method_types = new List<String>();
        checkout.payment_method_types.add('card');
        checkout.submit_type = 'pay';
        checkout.customer = CustId;
        checkout.mode = 'payment'; 
        checkout.success_url = SuccessURL;
        checkout.cancel_url  = CancelUrl;
        StripeCheckoutWrapper.Line_items pro= new StripeCheckoutWrapper.Line_items();
        pro.Name = 'One Time Payment';
        pro.amount = Integer.valueOf(PayAmount*100);
        pro.currency_z = 'AUD'; // Need to store some where on Database to be fetched from settings.
        pro.quantity = 1;
        checkout.Line_items = new list<StripeCheckoutWrapper.Line_items>();
        checkout.Line_items.add(pro); 
        String checkOutBody = StripeCheckoutOneOffSession(checkout);         
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.oneTimeCheckoutResponse, Processing_Record_Id__c = SFId,Payment_Parameter_1__c = CustId, Payment_Parameter_2__c = checkOutBody.substringAfter('valid:'),Amount__c = PayAmount ,Gateway_Name__c = UTILGateway.STRIPEWORD, Charge_Type__c = UTILGateway.ONETIMEKEYWORD))); // Add to Log
        return checkOutBody;
    }
    
    
    /*********************** create a Schedule Stripe helper method ********************************/
    public static String StripeCheckoutScheduleSession(String custId, String planId, String successURL, String cancelURL,String InstalPeriod, Date firstPayment, Decimal Amount, String SFId){
        String returnValue = '';
        if(detachedReason != null)
        throw new GatewayException(detachedReason); 
        StripeCheckoutWrapper checkoutScheduleWrapper = new StripeCheckoutWrapper();
        checkoutScheduleWrapper.customer = custId;
        checkoutScheduleWrapper.success_url = successURL;
        checkoutScheduleWrapper.cancel_url = cancelURL;
        checkoutScheduleWrapper.payment_method_types = new List<String>();
        checkoutScheduleWrapper.payment_method_types.addall(new List<String>{'card'});
        StripeCheckoutWrapper.Subscription subscription = new StripeCheckoutWrapper.Subscription();
        subscription.plan = planId;
        if(firstPayment > System.Today()){
            Integer trial_period = System.Today().daysBetween(firstPayment);
            subscription.trial_period_days = String.valueOf(trial_period);
        }/*else if(firstPayment == System.today()){
            subscription.trial_end = 'now';
        }*/
        checkoutScheduleWrapper.Subscription_z = subscription;
        
        HTTPResponse response = hitEndpoint(StripeScheduleCheckoutSessions,'POST',StripeGateWay.Client_Key__c,StripeCheckoutWrapper.createSessionPayLoadSubscription(checkoutScheduleWrapper));
        
        if(response?.getStatusCode() == 200){      
            StripeCheckoutWrapper responseCheckOut =  StripeCheckoutWrapper.DeserializeCheckOutResponse(response.getBody());
            returnValue = 'valid:'+responseCheckOut.Id;            
        }else{
            returnValue = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message;
        } 
        
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Recurring_Start_Date__c = firstPayment,Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.createScheduleSession, End_Point__c = StripeScheduleCheckoutSessions, Request_Type__c = 'POST', Payload__c = StripeCheckoutWrapper.createSessionPayLoadSubscription(checkoutScheduleWrapper), HTTP_Response_Code__c = String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Payment_Parameter_1__c = custId, Payment_Parameter_2__c = (returnValue.startsWith('valid:') ? returnValue.substringAfter('valid:') : null), Payment_Parameter_3__c = planId, Processing_Record_Id__c = SFId, Amount__c = Amount, Frequency__c = InstalPeriod ,Gateway_Name__c = UTILGateway.STRIPEWORD, Charge_Type__c = UTILGateway.RECURRINGKEYWORD))); // Add to Log
        
        return returnValue;
    }
    
    
    
    
    /***************** Method to update the recurring payment in stripe ***************/
    public static String updateRecurringPayment(RecurringWrapper req){
        String value = '';
        String plan = createStripePlan(StripeScheduleHandler.createStripePlanWrapper(req.amount,req.instalPeriod)); 
        if(plan.startsWith('valid')){
            HTTPResponse responseKey = hitEndpoint(StripeSubscriptions+'/'+req.recurringRequestId,'GET',StripeGateWay.Client_Key__c,null); 
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c =  UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchRPDetails, End_Point__c = StripeSubscriptions+'/'+req.recurringRequestId, Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
            
            if(responseKey.getStatusCode() == 200){
                StripeSubscriptionWrapper sub =  StripeSubscriptionWrapper.DeserializeSubscriptionResponse(responseKey.getBody());
                
                //Start to create Subscription Payload
                String subscription_payload = '&items[0][id]='+EncodingUtil.urlEncode(sub.items.data[0].id , 'UTF-8');
                String planId=plan.substringAfter(':');
                subscription_payload += '&items[0][plan]='+EncodingUtil.urlEncode(planId, 'UTF-8');
                subscription_payload += '&proration_behavior='+EncodingUtil.urlEncode('none', 'UTF-8');
                subscription_payload += req.startDateUnix != null ? '&trial_end='+EncodingUtil.urlEncode(req.startDateUnix, 'UTF-8'): '';
               // subscription_payload += '&billing_cycle_anchor='+EncodingUtil.urlEncode('now', 'UTF-8');
                /*subscription_payload += '&proration_behavior='+((req.startDateUnix == null) ? EncodingUtil.urlEncode('always_invoice', 'UTF-8'):EncodingUtil.urlEncode('none', 'UTF-8'));

                subscription_payload += req.startDateUnix != null ? '&trial_end='+EncodingUtil.urlEncode(req.startDateUnix, 'UTF-8'): '&trial_end='+EncodingUtil.urlEncode('now', 'UTF-8');*/

                /*if(System.today()==req.startDate){
                    
                }else{
                    subscription_payload += req.startDateUnix != null ? '&trial_end='+EncodingUtil.urlEncode(req.startDateUnix, 'UTF-8'): '';
                }*/
                responseKey = hitEndpoint(StripeSubscriptions+'/'+req.recurringRequestId,'POST',StripeGateWay.Client_Key__c,subscription_payload );
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.updateRPDetails, End_Point__c = StripeSubscriptions+'/'+req.recurringRequestId, Request_Type__c = 'POST', Payload__c = subscription_payload , HTTP_Response_Code__c =  String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log 
                
                if(responseKey.getStatusCode() == 200){
                    value = MessageHandler.updateRP + UTILGateway.STRIPEWORD.capitalize() + '.';
                }else{
                    value = MessageHandler.stripeRPNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
                }
            }else{
                value = MessageHandler.stripeRPNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
            }        
        }else{
            value = plan;
        }
        return value;
    }
    
    
    /***************** Method to cancel the recurring payment in stripe ***************/
    public static String cancelRecurringPayment(String recRequestId){
        String value = '';
        HTTPResponse responseKey = hitEndpoint(StripeSubscriptions+'/'+recRequestId,'DELETE',StripeGateWay.Client_Key__c,null );
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.cancelRecPay, End_Point__c = StripeSubscriptions+'/'+recRequestId, Request_Type__c = 'POST', HTTP_Response_Code__c =  String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log 
        if(responseKey.getStatusCode() == 200){
            value = MessageHandler.cancelRP;
        }else{
            value = MessageHandler.stripeRPNotCancel + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
        }
        return value;
    }
    
    
    /*********************** create a update card session in stripe ********************************/
    public static String updateCardDetails(StripePaymentMethodwrapper pay_method){ 
        if(detachedReason != null)
        throw new GatewayException(detachedReason);
        String returnValue = '';
        HTTPResponse response = hitEndpoint(StripeScheduleCheckoutSessions,'POST',StripeGateWay.Client_Key__c,StripePaymentMethodwrapper.createPaymentMethodPayLoad(pay_method));
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.updateCardSession, End_Point__c = StripeScheduleCheckoutSessions ,Request_Type__c = 'POST', Payload__c =  StripePaymentMethodwrapper.createPaymentMethodPayLoad(pay_method), HTTP_Response_Code__c =  String.valueOf(response.getStatusCode()), HTTP_Response__c = response.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log 
        if(response?.getStatusCode() == 200){                 
            StripeCheckoutWrapper responseCheckOut =  StripeCheckoutWrapper.DeserializeCheckOutResponse(response.getBody()); 
            returnValue = '/apex/Q_Charge__StripeCheckout?session_id='+responseCheckOut.Id;
        }else{
            returnValue = StripeErrorWrapper.DeserializeErrorResponse(response.getBody()).error.message;
        } 
        return returnValue;
    }
    
    
    /***************** Method to process the update card ***************/
    public static String ProcessUpdateCard(Payment_Log__c log){
        HTTPResponse responseKey; 
        String result = '';
        responseKey = hitEndpoint(StripeScheduleCheckoutSessions+'/'+log.Payment_Parameter_1__c,'GET',StripeGateWay.Client_Key__c,null); 
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchSesionResponse, End_Point__c = StripeScheduleCheckoutSessions+'/'+log.Payment_Parameter_1__c,Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
        if(responseKey.getStatusCode() == 200){
            StripeCheckoutWrapper CheckOut =  StripeCheckoutWrapper.DeserializeCheckOutResponse(responseKey.getBody());
            if(CheckOut.setup_intent != null) {                
                responseKey = hitEndpoint(StripeSetupIntents+'/'+CheckOut.setup_intent,'GET',StripeGateWay.Client_Key__c,null); 
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchSetupIntent, End_Point__c = StripeSetupIntents+'/'+CheckOut.setup_intent,Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                if(responseKey.getStatusCode() == 200) {
                    StripeSetupIntentWrapper intent_wrapper = StripeSetupIntentWrapper.parse(responseKey.getBody());
                    if(intent_wrapper.status == 'succeeded') {        
                        responseKey = hitEndpoint(StripeSubscriptions+'/'+log.Transaction_Id__c,'GET',StripeGateWay.Client_Key__c,null); 
                        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchRPDetails, End_Point__c = StripeSubscriptions+'/'+log.Transaction_Id__c, Request_Type__c = 'GET', HTTP_Response_Code__c =String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                        if(responseKey.getStatusCode() == 200){
                            StripeSubscriptionWrapper subscription_wrapper =  StripeSubscriptionWrapper.DeserializeSubscriptionResponse(responseKey.getBody());
                            
                            responseKey = hitEndpoint(StripePaymentMethod+'/'+intent_wrapper.payment_method+'/attach','POST',StripeGateWay.Client_Key__c,'&customer='+subscription_wrapper.customer);
                            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.updatePaymentMethod, End_Point__c = StripePaymentMethod+'/'+intent_wrapper.payment_method+'/attach', Request_Type__c = 'POST', Payload__c =  '&customer='+subscription_wrapper.customer, HTTP_Response_Code__c =  String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log  
                            if(responseKey.getStatusCode() == 200){
                                responseKey = hitEndpoint(StripeCustomers+'/'+subscription_wrapper.customer,'POST',StripeGateWay.Client_Key__c,'&[invoice_settings][default_payment_method]='+intent_wrapper.payment_method);
                                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.attachPaymentIntent, End_Point__c = StripeCustomers+'/'+subscription_wrapper.customer ,Request_Type__c = 'POST', Payload__c = '&[invoice_settings][default_payment_method]='+intent_wrapper.payment_method, HTTP_Response_Code__c =  String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log 
                                
                                if(responseKey.getStatusCode() == 200){
                                    
                                    responseKey = hitEndpoint(StripeSubscriptions+'/'+log.Transaction_Id__c,'POST',StripeGateWay.Client_Key__c,'&default_payment_method='+intent_wrapper.payment_method);
                                    UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.updateRPDetails, End_Point__c = StripeSubscriptions+'/'+log.Transaction_Id__c, Request_Type__c = 'POST', Payload__c = '&default_payment_method='+intent_wrapper.payment_method, HTTP_Response_Code__c =  String.valueOf(responseKey.getStatusCode()), HTTP_Response__c = responseKey.getBody().abbreviate(maxlength),Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log 
                                    
                                    if(responseKey.getStatusCode() == 200){
                                        
                                        if(intent_wrapper.payment_method != null){
                                            HTTPResponse transactRes = hitEndpoint(StripePaymentMethod+'/'+intent_wrapper.payment_method,'GET',StripeGateWay.Client_Key__c,null);  
                                            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Action__c = UTILGateway.STRIPEWORD.capitalize() + MessageHandler.fetchPayMethodofscheule, End_Point__c = StripePaymentMethod+'/'+intent_wrapper.payment_method,Request_Type__c = 'GET', HTTP_Response_Code__c = String.valueOf(transactRes.getStatusCode()), HTTP_Response__c = transactRes.getBody().abbreviate(maxlength) ,Gateway_Name__c = UTILGateway.STRIPEWORD))); // Add to Log
                                            
                                            if(transactRes.getStatusCode() == 200){
                                                StripePaymentMethodwrapper paymethod = StripePaymentMethodwrapper.parse(transactRes.getBody());
                                                result = 'succeeded:'+JSON.serialize(paymethod);
                                            }else{
                                                result = MessageHandler.stripeCardNotUpdated +StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message; 
                                            }                        
                                        }
                                    }
                                    else{
                                        result = MessageHandler.stripeCardNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
                                    }
                                }
                                else{
                                    result = MessageHandler.stripeCardNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
                                }
                            }else 
                            result = MessageHandler.stripeCardNotUpdated + MessageHandler.stripeUnblToGetRPInfo;
                        } else {
                            result = MessageHandler.stripeCardNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
                        }
                    } else {
                        result = MessageHandler.stripeCardNotUpdated + MessageHandler.stripeCardnotSetup;
                        if(intent_wrapper.cancellation_reason != null) 
                        result += intent_wrapper.cancellation_reason;
                    }
                } else {
                    result = MessageHandler.stripeCardNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
                }
            } else {
                result =   MessageHandler.setupInfoError(CheckOut.Id);
            }
        } else {
            result = MessageHandler.stripeCardNotUpdated + StripeErrorWrapper.DeserializeErrorResponse(responseKey.getBody()).error.message;
        }
        return result;
    }
    
    
    public static Decimal convertCentToDollar(Integer cent){
        return (cent != null ? Decimal.valueOf(cent) / 100 : 0);
    }
    
    /********** StripeProductWrapper Start ***********************/
    public class StripeProductWrapper {
        public String name;
        public String type;
        public String id;        
        public StripeProductWrapper(String name,String type) {this.name = name; this.type = type;}
    }
    
    public static String createProductPayLoad(StripeProductWrapper wrapper){
        String product_wrapper = '';
        product_wrapper += 'name='+EncodingUtil.urlEncode(wrapper.name, 'UTF-8');
        product_wrapper += '&type='+EncodingUtil.urlEncode(wrapper.type, 'UTF-8');
        return product_wrapper;
    }
    
    public static StripeProductWrapper DeserializeProductResponse(String wrapper_body){
        return (StripeProductWrapper)JSON.deserialize(wrapper_body, StripeProductWrapper.class);
    }
    /********** StripeProductWrapper End ***********************/    
    
    /********** StripeErrorWrapper Start ***********************/
    public class StripeErrorWrapper{        
        public StripeError error;        
    }
    
    public class StripeError{
        public string type_z;
        public string charge;
        public string code;
        public string decline_code;
        public string doc_url;
        public string message;
        public string param;
        public string payment_intent;
        public string payment_method;
        public string setup_intent;
        public string source;
    }
    
    public static StripeErrorWrapper DeserializeErrorResponse(String Error_body){
        return (StripeErrorWrapper)JSON.deserialize(Error_body, StripeErrorWrapper.class);
    }
    /********** StripeErrorWrapper End ***********************/
    
    /************* HTTP Stripe Generic methods ***************************************/    
    public Static HTTPResponse hitEndpoint(String EndPointURL, String Method, String APIKEY, String PayLoad){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(EndPointURL);
        request.setMethod(Method);        
        request.setHeader('Content-Type','application/x-www-form-urlencoded');      
        request.setHeader('accept','Application/json'); 
        request.setHeader('Authorization', 'Bearer '+APIKEY); 
        if(PayLoad != null)
        request.setBody(PayLoad);
        request.setTimeout(120000); 
        return new Http().send(request);
    }
}