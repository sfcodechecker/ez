public with sharing class BpointHelper {
    public BpointHelper() {
        
    }
    public static HttpResponse searchResponse(){
        HttpResponse response = new HttpResponse();
        response.setBody('{"APIResponse":{"ResponseCode":0,"ResponseText":"Success"},"TxnRespList":[{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"372626","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}},{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"380662","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}}]}');
        response.setStatus('Ok');
        response.setStatusCode(200);
        return response;
    }
    
    public static HttpResponse failedSearchResponse(){
        HttpResponse response = new HttpResponse();
        response.setBody('{"APIResponse":{"ResponseCode":1,"ResponseText":"Invalid credentials"},"TxnRespList":[{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"372626","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}},{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"380662","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}}]}');
        response.setStatus('Ok');
        response.setStatusCode(200);
        return response;        
    }
    public static HttpResponse processtxnauthkeyResponse(){
        HttpResponse response = new HttpResponse();
        response.setBody('{"APIResponse":{"ResponseCode":0,"ResponseText":"Success"},"AuthKey":"df998fea-f309-4e6e-9629-7149799dc028"}');
        response.setStatus('Ok');
        response.setStatusCode(200);
        return response;
    }
    public static Id processOneOffPayment(BpointTxnResponseWrapper response,TransactionWrapper transWrapper) {
        if(response.APIResponse.ResponseText=='Success'){
            Transaction__c transactionData = new Transaction__c();
            if((UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Create') || UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','update') || UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Upsert'))
               && (Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() 
                   && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() 
                   && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()
                   && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable()) || (Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isUpdateable()
                                                                                                        && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable() 
                                                                                                        && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable() 
                                                                                                        && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable()))
            {
                transactionData.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('One Time').getRecordTypeId();
                transactionData.Amount__c = (response.TxnResp.Amount);
                transactionData.Transaction_Date__c = Datetime.now();
                transactionData.Gateway_Name__c = UTILGateway.BPOINTWORD;
                transactionData.Transaction_Status__c = 'PAID';
                String paymentId=generatePaymentId();
                transactionData.Transaction_Id__c = paymentId;
                insert transactionData;
                ReceiptWrapper receipt=new ReceiptWrapper();
                receipt.amount = transactionData.Amount__c;
                receipt.chargeType = UTILGateway.ONETIMEKEYWORD;
                receipt.paymentStatus = 'Transaction Approved';
                receipt.paymentResponse = MessageHandler.onetimeSuccess;
                receipt.paymentId = paymentId;
                String serializedWrapper=JSON.serialize(receipt);
                UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UtilGateway.BPOINTWORD,Retry_Schedule_URL__c = '',Action__c='Bpoint - Transaction Complete',Request_Type__c = 'POST',Amount__c = transactionData.Amount__c,Charge_Type__c = UTILGateway.ONETIMEKEYWORD ,End_Point__c = '/apex/Q_Charge__BpointCheckout',Serialized_Record__c = serializedWrapper)));
                List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
                return paymentLogList[0].Id;
            }else{
                throw new UTILPermission.PermsException('Transaction__c','RecordTypeId,Amount__c,Transaction_Date__c,Gateway_Name__c,Transaction_Status__c,Transaction_Id__c,Recurring_Payment__c','Create');
            }
        }else{
            ReceiptWrapper receipt=new ReceiptWrapper();
            receipt.amount=transWrapper.amount;
            receipt.chargeType = UTILGateway.ONETIMEKEYWORD;
            receipt.paymentId=generatePaymentId();
            receipt.paymentStatus='Transaction Rejected';
            receipt.paymentResponse='Payment is not charged due to Card specified is invalid.';
            transWrapper = retryOneTime(transWrapper,receipt);
            return transWrapper.logrefId;
        }
        
    }
    public static String responseBpoint(){
        return '{"APIResponse":{"ResponseCode":0,"ResponseText":"Success"},"TxnResp":{"Action":"payment","Amount":19900,"AmountOriginal":19800,"AmountSurcharge":100,"ThreeDSResponse":null,"AuthoriseId":"372626","BankAccountDetails":null,"BankResponseCode":"00","CVNResult":{"CVNResultCode":"Unsupported"},"CardDetails":{"CardHolderName":"John Smith","ExpiryDate":"0521","MaskedCardNumber":"512345...346","Category":"STANDARD","Issuer":"BANCO DEL PICHINCHA, C.A.","IssuerCountryCode":"ECU","Localisation":"international","SubType":"credit"},"CardType":"MC","Currency":"AUD","MerchantReference":"test merchant ref","IsThreeDS":false,"IsCVNPresent":true,"MerchantNumber":"5353109000000000","OriginalTxnNumber":null,"ProcessedDateTime":"2014-12-12T12:15:19.6370000","RRN":"434612372626","ReceiptNumber":"49316411177","Crn1":"test crn1","Crn2":"test crn2","Crn3":"test crn3","ResponseCode":"0","ResponseText":"Approved","BillerCode":null,"SettlementDate":"20141212","Source":"api","StoreCard":false,"IsTestTxn":false,"SubType":"single","TxnNumber":"1177","DVToken":null,"Type":"internet","FraudScreeningResponse":{"ReDResponse":{"FRAUD_REC_ID":"123412341234SAX20150101100000000","FRAUD_RSP_CD":"0100","FRAUD_STAT_CD":"ACCEPT","ORD_ID":"12341234","REQ_ID":"123412341234","STAT_CD":"PENDING"},"ResponseCode":"","ResponseMessage":"","TxnRejected":false},"StatementDescriptor":{"AddressLine1":"123 Drive Street","AddressLine2":"","City":"Melbourne","CompanyName":"A Company Name","CountryCode":"AUS","Postcode":"3000","State":"Victoria","MerchantName":"A Merchant Name","PhoneNumber":"0123456789"}}}';
    }

    public static String ProcessOneTimeRequest(BpointAuthKeyRequestWrapper wrapper,String recordId){

        String response=responseBpoint();
        TransactionWrapper transWrapper=new TransactionWrapper();
        transWrapper.amount=Decimal.valueOf(wrapper.ProcessTxnData.Amount);
        transWrapper.sfProcessingId=recordId;
        transWrapper.jsonRequest=JSON.serialize(wrapper);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=recordId,Action__c=UTILGateway.BPOINTWORD.capitalize() + MessageHandler.accessOnetimePage, Http_Response__c=String.valueOf(response),Http_Response_Code__c='200',Request_Type__c='POST',Transaction_Id__c=generatePaymentId(),Transaction_Status__c='APPROVED',Serialized_Record__c=JSON.serialize(transWrapper),Charge_Type__c=UtilGateway.ONETIMEKEYWORD,Gateway_Name__c=UtilGateway.BPOINTWORD)));
        List<Payment_Log__c> paymentLogList=UtilGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        UTILGateway.PayLogSet_JSON.remove(0);
        Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
        transWrapper.logrefId=log.Id;
        String checkoutLink = BPointManager.requestOneOfPayment(transWrapper);
        return checkoutLink;
    }

    public static TransactionWrapper retryOneTime(TransactionWrapper transWrapper,ReceiptWrapper receipt){
        String url=BPointManager.requestOneOfPayment(transWrapper);
        UTILGateway.PayLogSet_JSON.remove(0);
        transWrapper.processingLink=url;
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=transWrapper.sfProcessingId,Action__c=UTILGateway.BPOINTWORD.capitalize() + 'Retry Transaction', Http_Response__c=String.valueOf(transWrapper.jsonRequest),Http_Response_Code__c='400',Request_Type__c='POST',Transaction_Id__c=generatePaymentId(),Transaction_Status__c='DECLINED',Serialized_Record__c=JSON.serialize(receipt),Charge_Type__c=UtilGateway.ONETIMEKEYWORD,Gateway_Name__c=UtilGateway.BPOINTWORD,Retry_Schedule_URL__c=url)));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        transWrapper.logrefId=paymentLogList.get(paymentLogList.size()-1).Id;
        return transWrapper;

    }

    public static String ProcessRecurringRequest(BpointAuthKeyRequestWrapper wrapper,String recordId,String InstalPeriod,String StartDate){
        String response = responseBpoint();
        RecurringWrapper reccWrapper = new RecurringWrapper();
        reccWrapper.amount=Decimal.valueOf(wrapper.ProcessTxnData.Amount);
        reccWrapper.sfProcessingId=recordId;
        reccWrapper.instalPeriod=InstalPeriod;
        reccWrapper.startDate=Date.valueOf(StartDate);
        reccWrapper.jsonRequest=JSON.serialize(wrapper);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Recurring_Start_Date__c=Date.valueOf(StartDate),Frequency__c = InstalPeriod,Processing_Record_Id__c=recordId,Action__c=UTILGateway.BPOINTWORD.capitalize() + MessageHandler.accessRecPayPage, Http_Response__c=String.valueOf(response),Http_Response_Code__c='200',Request_Type__c='POST',Transaction_Id__c=generatePaymentId(),Transaction_Status__c='APPROVED',Serialized_Record__c=JSON.serialize(reccWrapper),Charge_Type__c=UtilGateway.RECURRINGKEYWORD,Gateway_Name__c=UtilGateway.BPOINTWORD)));
        List<Payment_Log__c> paymentLogList=UtilGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        Payment_Log__c log=paymentLogList.get(paymentLogList.size()-1);
        UTILGateway.PayLogSet_JSON.remove(0);
        reccWrapper.logrefId=log.Id;
        String checkoutLink = BPointManager.requestRecurringPayment(reccWrapper);
        return checkoutLink;
    }

    public static String ProcessRecurringPayment(BpointTxnResponseWrapper response, RecurringWrapper reccWrapper){
        Boolean createPaidTransaction=false;
        ReceiptWrapper receipt = new ReceiptWrapper();
        receipt.amount=reccWrapper.amount;
        receipt.chargeType=UTILGateway.RECURRINGKEYWORD;
        receipt.installPeriod=reccWrapper.instalPeriod;
        receipt.nextInstallmentDate=reccWrapper.startDate;
        receipt.establishmentDate=Date.today();
        if(response.APIResponse.ResponseText=='Success'){
            List<Transaction__c> transactionList=new List<Transaction__c>();
            if(reccWrapper.startDate==Date.today()){
                createPaidTransaction=true;
            }
            Recurring_Payment__c newRecurring = mapRecurringPayment(reccWrapper);
            if(UTILPermission.CheckSingleObject('Q_Charge__Recurring_Payment__c','Create')){
            	insert newRecurring;
            }
            reccWrapper.startDate=newRecurring.Next_Installment_Date__c;
            receipt.nextInstallmentDate=newRecurring.Next_Installment_Date__c;
            if(createPaidTransaction){
                Transaction__c newTransactionPaid = mapRecurringTransaction(reccWrapper,newRecurring.Id,'Paid');
                transactionList.add(newTransactionPaid);
            }
            Transaction__c newTransaction = mapRecurringTransaction(reccWrapper,newRecurring.Id,'Scheduled');
            transactionList.add(newTransaction);
            if(UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Create')){
            	insert transactionList;
            }
            receipt.paymentId=generatePaymentId();
            receipt.paymentStatus='Payment Approved';
            receipt.paymentResponse=MessageHandler.recurringSuccess;
            String serializedWrapper = JSON.serialize(receipt);
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = UtilGateway.BPOINTWORD,Retry_Schedule_URL__c = '',Action__c=UtilGateway.BpointWord.capitalize()+' '+MessageHandler.recPayCheckoutComplete,Request_Type__c = 'POST',Amount__c = reccWrapper.amount,Charge_Type__c = UTILGateway.RecurringKEYWORD ,End_Point__c = '/apex/Q_Charge__BpointCheckout',Serialized_Record__c = serializedWrapper)));
            List<Payment_Log__c> paymentLogList = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            reccWrapper.logrefId=paymentLogList.get(paymentLogList.size()-1).Id;
        }else{
            receipt.paymentId=generatePaymentId();
            receipt.paymentStatus='Payment Rejected';
            receipt.paymentResponse=MessageHandler.recurringFailed+' Card specified is invalid.';
            reccWrapper = retryRecurringPayment(reccWrapper, receipt);
        }
        return reccWrapper.logrefId;

    }

    public static Recurring_Payment__c mapRecurringPayment(RecurringWrapper wrapper){
        Recurring_Payment__c newRecurringPayment = new Recurring_Payment__c();
        if(UTILPermission.CheckSinglePerm('create', 'Q_Charge__Recurring_Payment__c', new Set<String>{'Q_Charge__Amount__c','Q_Charge__Date_Established__c','Q_Charge__Next_Installment_Date__c','Q_Charge__Gateway_Name__c','Q_Charge__Installment_Period__c','Q_Charge__Status__c','Q_Charge__RelatedToId__c','Q_Charge__Gateway_Schedule_Id__c','Q_Charge__Gateway_Refund_Id__c','Q_Charge__Refund_Status__c','Q_Charge__Refund_Amount__c'})){
            if((Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isCreateable() &&
            Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isCreateable() &&
            Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isCreateable()
            && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isCreateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isCreateable()
            &&Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isCreateable())
            ||
            (Schema.sObjectType.Recurring_Payment__c.fields.Amount__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Date_Established__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Next_Installment_Date__c.isUpdateable() &&
            Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Installment_Period__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Status__c.isUpdateable() &&
            Schema.sObjectType.Recurring_Payment__c.fields.RelatedToId__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Schedule_Id__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Gateway_Refund_Id__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Status__c.isUpdateable()
            && Schema.sObjectType.Recurring_Payment__c.fields.Refund_Amount__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Last_Updated_On__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Name__c.isUpdateable() && Schema.sObjectType.Recurring_Payment__c.fields.Card_Expiry_Date__c.isUpdateable()
            &&Schema.sObjectType.Recurring_Payment__c.fields.Card_Number__c.isUpdateable())){
                newRecurringPayment.Amount__c=wrapper.amount;
                newRecurringPayment.Date_Established__c=Date.today();
                newRecurringPayment.Gateway_Name__c=UtilGateway.BpointWord;
                newRecurringPayment.Installment_Period__c=wrapper.instalPeriod;
                newRecurringPayment.Status__c='Open';
                newRecurringPayment.RelatedToId__c=wrapper.sfProcessingId;
                newRecurringPayment.Gateway_Schedule_Id__c=generatePaymentId();
                if(wrapper.startDate==Date.today()){
                    newRecurringPayment.Next_Installment_Date__c= Date.newInstance(wrapper.startDate.year(), wrapper.startDate.month()+1, wrapper.startDate.day());
                }else if(wrapper.startDate>Date.today()){
                    newRecurringPayment.Next_Installment_Date__c=wrapper.startDate;
                    newRecurringPayment.Gateway_Refund_Id__c=generatePaymentId();
                    newRecurringPayment.Refund_Status__c='Awaiting';
                    newRecurringPayment.Refund_Amount__c=1.00;
                }
                newRecurringPayment.Card_Name__c='Test User';
                newRecurringPayment.Card_Number__c='518554...346';
                newRecurringPayment.Card_Expiry_Date__c=Date.newInstance(2026,06,30);
                newRecurringPayment.Card_Last_Updated_On__c=Datetime.now();
                
            }
        }
        return newRecurringPayment;
    }

    public static RecurringWrapper retryRecurringPayment(RecurringWrapper reccWrapper,ReceiptWrapper receipt){
        String url = BPointManager.requestRecurringPayment(reccWrapper);
        UTILGateway.PayLogSet_JSON.remove(0);
        UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Processing_Record_Id__c=reccWrapper.sfProcessingId,Action__c=UTILGateway.BPOINTWORD.capitalize() +' '+MessageHandler.recPayCheckoutfail, Http_Response__c=String.valueOf(reccWrapper.jsonRequest),Http_Response_Code__c='400',Request_Type__c='POST',Transaction_Id__c=generatePaymentId(),Transaction_Status__c='DECLINED',Serialized_Record__c=JSON.serialize(receipt),Charge_Type__c=UtilGateway.RECURRINGKEYWORD,Gateway_Name__c=UtilGateway.BPOINTWORD,Retry_Schedule_URL__c=url)));
        List<Payment_Log__c> paymentLogList=UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
        reccWrapper.logrefId=paymentLogList.get(paymentLogList.size()-1).Id;
        return reccWrapper;
    }

    public static Transaction__c mapRecurringTransaction(RecurringWrapper wrapper,Id recurringId,String transactionStatus){
        Transaction__c transactionData = new Transaction__c();
        if((UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Create') || UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','update') || UTILPermission.CheckSingleObject('Q_Charge__Transaction__c','Upsert'))
               && (Schema.sObjectType.Transaction__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isCreateable() 
                   && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isCreateable() 
                   && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isCreateable()
                   && Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isCreateable()) || (Schema.sObjectType.Transaction__c.fields.Recurring_Payment__c.isUpdateable()
                                                                                                        && Schema.sObjectType.Transaction__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Amount__c.isUpdateable() 
                                                                                                        && Schema.sObjectType.Transaction__c.fields.Transaction_Date__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Gateway_Name__c.isUpdateable() 
                                                                                                        && Schema.sObjectType.Transaction__c.fields.Transaction_Status__c.isUpdateable() && Schema.sObjectType.Transaction__c.fields.Transaction_Id__c.isUpdateable()))
            {
                transactionData.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
                transactionData.Amount__c = wrapper.amount;
                if(wrapper.startDate!=Date.today() && transactionStatus == 'Paid' ){
                    transactionData.Transaction_Date__c = Datetime.now();
                    transactionData.Transaction_Id__c = generatePaymentId();
                }else{
                    transactionData.Transaction_Date__c = wrapper.startDate;
                }
                transactionData.Gateway_Name__c = UTILGateway.BPOINTWORD;
                transactionData.Transaction_Status__c = transactionStatus;
                transactionData.Recurring_Payment__c = recurringId;
            }
            return transactionData;
    }

    public static String generatePaymentId(){
        return String.valueOf(Math.round(Math.random()*99999));
    }

    

    
}