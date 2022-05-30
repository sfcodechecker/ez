@isTest
public with sharing class TestDataFactory {
    
    public static Gateway_Detail__c  createValidStripeCredentials(){
        Blob CryptoKey = Blob.valueOf('@U!cKCharGeAc0n$');
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c='pk_test_51J1PxVSHrxjdfuOJNlLXneFV6zLRVBFjTngVyRE6WX4gwfHanYPwSAjs2p0uEB6K80NWnnwhADu4iZ8WBXgCzaTh00KxzWuHWZ',
                                                        Client_Key__c='sk_test_51J1PxVSHrxjdfuOJhglXdkj7QUBYulHCdOREyVpd5U03CdOR1zBaUlqnRoGMXifbZKjpvyXFdB2ngJbAvuxH2vP500Ce8YXLrg',
                                                        Default__c=false,Name__c=UTILGateway.STRIPEWORD,Optional_Key_1__c='prod_K6BMGGNI21u8ds',isSandbox__c=false);
        UTILGateway.encodeKeys(Gateway);                                                            
        insert Gateway;
        return Gateway;
    }
    public static Gateway_Detail__c  createValidEzidebitCredentials(){
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c='C4AEFBD5-2A4F-49CB-71CC-14490D6352AD',
                                                        Client_Key__c='6782F49B-3669-4C07-C11E-85469A0DA1EA',
                                                        isSandbox__c=true,Name__c=UTILGateway.EZIDEBITWORD);
        UTILGateway.encodeKeys(Gateway);                                                            
        insert Gateway;
        return Gateway;
    }
    public static Gateway_Detail__c  createValidPaywayCredentials(){ 
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c='T15629_PUB_wirkup5scwubn4q73u2rwv3at5hgdf2wt92d84m5g8nwvptpc66ea9jcqjyt',
                                                        Client_Key__c='T15629_SEC_z4jevdx898enqp9uux4r7rbaqxj9xreir8w5bkiaxncj77z8gvhye6xut2wz',
                                                        Optional_key_1__c='TEST',Name__c=UTILGateway.PAYWAYWORD);
        UTILGateway.encodeKeys(Gateway);                                                            
        insert Gateway;
        return Gateway;
    }
    public static Gateway_Detail__c  createValidSimplifyCredentials(){ 
        Gateway_Detail__c gateway = new Gateway_Detail__c(HostedPayments_PublicKey__c='sbpb_Y2EyMzVjZjItNGJlOC00ZjU1LTgxNzEtNmUxZmYzZGIzZTJi',
                                                            HostedPayments_PrivateKey__c='tYHzqxuY7NGwWmdFoOJSYGhApkv/O9yQipehFFTtwjR5YFFQL0ODSXAOkNtXTToq',
                                                          Name__c=UTILGateway.SIMPLIFYWORD, Authorisation_Code__c='gLzBexgEjy8nd9',isSandbox__c=true);
        UTILGateway.encodeKeys(Gateway);                                                            
        insert Gateway;
        return Gateway;
    }
    public static Gateway_Detail__c  createValidNABCredentials(){ 
        Gateway_Detail__c gateway = new Gateway_Detail__c(Client_Id__c='XYZ0010',
                                                          Client_Key__c='abcd1234', 
                                                          Name__c=UTILGateway.NABTRANSWORD, 
                                                          isSandbox__c=true);
        UTILGateway.encodeKeys(Gateway);                                                            
        insert Gateway;
        return Gateway;
    }
    
    public static Gateway_Detail__c  createValidBPointCredentials(){ 
        Gateway_Detail__c bpoint_gateway = new Gateway_Detail__c();
        bpoint_gateway.Name__c = 'BPoint';
        bpoint_gateway.Client_Id__c = '123456';
        bpoint_gateway.Optional_Key_1__c = '123456';
        bpoint_gateway.Client_Key__c = '123456';
        UTILGateway.encodeKeys(bpoint_gateway);                                          
        insert bpoint_gateway;
        return bpoint_gateway;
    }
    public static Gateway_Detail__c  createValidStripeCredentialsNoOptionalKey(){
        Blob CryptoKey = Blob.valueOf('@U!cKCharGeAc0n$');
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c='pk_test_51J1PxVSHrxjdfuOJNlLXneFV6zLRVBFjTngVyRE6WX4gwfHanYPwSAjs2p0uEB6K80NWnnwhADu4iZ8WBXgCzaTh00KxzWuHWZ',
                                                        Client_Key__c='sk_test_51J1PxVSHrxjdfuOJhglXdkj7QUBYulHCdOREyVpd5U03CdOR1zBaUlqnRoGMXifbZKjpvyXFdB2ngJbAvuxH2vP500Ce8YXLrg',
                                                        Default__c=false,Name__c='stripe',isSandbox__c=false);
        UTILGateway.encodeKeys(Gateway); 
        insert Gateway;
        return Gateway;
    }
    public static Contact createContact(){
        Contact con=new Contact(FirstName='Stripe',LastName='Test',Email='stripetest@gmail.com');
        insert con;
        return con;
    }
    
    public static Contact newContact(){
        Contact con=new Contact(FirstName='Nate',LastName='Angus',Email='stripetest@gmail.com');
        insert con;
        return con;
    }
    public static StripeCheckoutWrapper createStripeCheckOutWrapper(StripeCheckoutWrapper wrapper,Contact con){
        wrapper.customer=con.FirstName+' '+con.LastName;
        wrapper.customer_email=con.Email;
        wrapper.payment_method_types=new List<String>{'onetime','recurring'};
            return wrapper;
    }
    public static Payment_Log__c createPaymentLog(){
        Payment_Log__c paymentLog=new Payment_Log__c();
        paymentLog.Transaction_Id__c='pi_3JSI96GPA9pqSzzU1mXbOUPh';
        paymentLog.Payment_Parameter_1__c='cus_K6V92Tl7bsBk7z';
        paymentLog.Payment_Parameter_2__c='cus_K6WAOc3iPA2aMh';
        paymentLog.Processing_Record_Id__c = createContact().Id;

        insert paymentLog;
        return paymentLog;
    }

    public static Payment_Log__c createPaymentLogStripe(Decimal amount, String installPeriod, Date startDate, String chargeType, String processingId){
        Payment_Log__c paymentLog=new Payment_Log__c();
        paymentLog.Transaction_Id__c='pi_3JSI96GPA9pqSzzU1mXbOUPh';
        paymentLog.Payment_Parameter_1__c='cus_K6V92Tl7bsBk7z';
        paymentLog.Payment_Parameter_2__c='cus_K6WAOc3iPA2aMh';
        paymentLog.Processing_Record_Id__c = processingId; 
        paymentLog.Gateway_Name__c = UTILGateway.STRIPEWORD;
        paymentLog.Charge_Type__c = chargeType;
        paymentLog.Recurring_Start_Date__c = (startDate != null) ? startDate : null;
        paymentLog.Frequency__c = (installPeriod != null) ? installPeriod : '';
        paymentLog.Amount__c = amount;

        insert paymentLog;
        return paymentLog;
    }
    
    public static Payment_Log__c updatePaymentLogStripe(String Id, String logId){
        Payment_Log__c log = [select Id, Frequency__c, Processing_Record_Id__c, HTTP_Response__c, Charge_Type__c from Payment_Log__c where Id =: logId];
        log.Frequency__c = 'Monthly';
        log.Processing_Record_Id__c = Id;
        log.HTTP_Response__c = '{"id":"sub_1Jv0dWFilGkYW1vHoYtGZNSK","object":"subscription","application_fee_percent":null,"automatic_tax":{"enabled":false},"billing_cycle_anchor":1636726910,"billing_thresholds":null,"cancel_at":null,"cancel_at_period_end":false,"canceled_at":null,"collection_method":"charge_automatically","created":1636726910,"current_period_end":1668262910,"current_period_start":1636726910,"customer":"cus_KaAyimSIFhQeuZ","days_until_due":null,"default_payment_method":"pm_1Jv0dVFilGkYW1vHZj4DNZaV","default_source":null,"default_tax_rates":[],"discount":null,"ended_at":null,"items":{"object":"list","data":[{"id":"si_KaAzINij9etEoe","object":"subscription_item","billing_thresholds":null,"created":1636726911,"metadata":{},"plan":{"id":"plan_KaAyWQ1zBbMTGz","object":"plan","active":true,"aggregate_usage":null,"amount":724,"amount_decimal":"724","billing_scheme":"per_unit","created":1636726873,"currency":"aud","interval":"year","interval_count":1,"livemode":false,"metadata":{},"nickname":null,"product":"prod_KU2dlbVBpQFGcj","tiers_mode":null,"transform_usage":null,"trial_period_days":null,"usage_type":"licensed"},"price":{"id":"plan_KaAyWQ1zBbMTGz","object":"price","active":true,"billing_scheme":"per_unit","created":1636726873,"currency":"aud","livemode":false,"lookup_key":null,"metadata":{},"nickname":null,"product":"prod_KU2dlbVBpQFGcj","recurring":{"aggregate_usage":null,"interval":"year","interval_count":1,"trial_period_days":null,"usage_type":"licensed"},"tax_behavior":"unspecified","tiers_mode":null,"transform_quantity":null,"type":"recurring","unit_amount":724,"unit_amount_decimal":"724"},"quantity":1,"subscription":"sub_1Jv0dWFilGkYW1vHoYtGZNSK","tax_rates":[]}],"has_more":false,"total_count":1,"url":"/v1/subscription_items?subscription=sub_1Jv0dWFilGkYW1vHoYtGZNSK"},"latest_invoice":"in_1Jv0dWFilGkYW1vHfr0CQAby","livemode":false,"metadata":{},"next_pending_invoice_item_invoice":null,"pause_collection":null,"payment_settings":{"payment_method_options":null,"payment_method_types":null},"pending_invoice_item_interval":null,"pending_setup_intent":null,"pending_update":null,"plan":{"id":"plan_KaAyWQ1zBbMTGz","object":"plan","active":true,"aggregate_usage":null,"amount":724,"amount_decimal":"724","billing_scheme":"per_unit","created":1636726873,"currency":"aud","interval":"year","interval_count":1,"livemode":false,"metadata":{},"nickname":null,"product":"prod_KU2dlbVBpQFGcj","tiers_mode":null,"transform_usage":null,"trial_period_days":null,"usage_type":"licensed"},"quantity":1,"schedule":null,"start_date":1636726910,"status":"active","transfer_data":null,"trial_end":null,"trial_start":null}';
        log.Charge_Type__c = 'Recurring';
        update log;
        return log;
    }
    
    public static Gateway_Detail__c createValidCredentialsWithNoURL(){
        Gateway_Detail__c Gateway=new Gateway_Detail__c(Client_Id__c='C4AEFBD5-2A4F-49CB-71CC-14490D6352AD',
                                                        Client_Key__c='6782F49B-3669-4C07-C11E-85469A0DA1EA',
                                                        isSandbox__c=true,Name__c=UTILGateway.EZIDEBITWORD);
        UTILGateway.encodeKeys(Gateway);                                                            
        insert Gateway;
        return Gateway;
    }
    public static Recurring_Payment__c createRecurringPayment(Decimal amount,Date estDate,Date nxtDate,String scheduleId,String installmentPeriod,String relatedId,String refundId,String gatewayName ){
        Recurring_Payment__c rp = new Recurring_Payment__c(Amount__c=amount,Date_Established__c=estDate,Gateway_Name__c=gatewayName,Status__c='Open',Next_Installment_Date__c=nxtDate,Installment_Period__c=installmentPeriod,RelatedToId__c=relatedId,
                                                           Refund_Amount__c=1,Refund_Status__c='Awaiting',Gateway_Schedule_Id__c=scheduleId,Gateway_Refund_Id__c=refundId, Secured_Token__c = 'zOWEdiHyXo6QlhsjYw3tThm7JanvggDhM9AiZINppbQob1E1I0rtHFMn31StCksI', Duration__c = 'Ongoing');
        
        insert rp;
        return rp;
    }

    public static Recurring_Payment__c RefundcreateRecurringPayment(Decimal amount,Date estDate,Date nxtDate,String scheduleId,String installmentPeriod,String relatedId,String refundId,String gatewayName ){
        Recurring_Payment__c rp = new Recurring_Payment__c(Amount__c=amount,Date_Established__c=estDate,Gateway_Name__c=gatewayName,Status__c='Open',Next_Installment_Date__c=nxtDate,Installment_Period__c=installmentPeriod,RelatedToId__c=relatedId,
                                                           Refund_Amount__c=1,Refund_Status__c='Failed',Gateway_Schedule_Id__c=scheduleId,Gateway_Refund_Id__c=refundId, Secured_Token__c = 'zOWEdiHyXo6QlhsjYw3tThm7JanvggDhM9AiZINppbQob1E1I0rtHFMn31StCksI', Duration__c = 'Ongoing');
        
        insert rp;
        return rp;
    }
    
    public static Recurring_Payment__c createRecurringPaymentFail(Decimal amount,Date estDate,Date nxtDate,String scheduleId,String installmentPeriod,String relatedId,String refundId,String gatewayName ){
        Recurring_Payment__c rp = new Recurring_Payment__c(Amount__c=amount,Date_Established__c=estDate,Gateway_Name__c=gatewayName,Status__c='Open',Next_Installment_Date__c=nxtDate,Installment_Period__c=installmentPeriod,RelatedToId__c=relatedId,
                                                           Refund_Amount__c=1,Refund_Status__c='AWAITING',Gateway_Schedule_Id__c=scheduleId,Gateway_Refund_Id__c=refundId, Secured_Token__c = 'xg5/gx4m82SepeJBgfZNoRYFV/ulnivrvYAo077fIp/Dr2L5fvkhsgajhaghjdah');
        
        insert rp;
        return rp;
    }
    
    public static Recurring_Payment__c createRecurringPaymentFailNoToken(Decimal amount,Date estDate,Date nxtDate,String scheduleId,String installmentPeriod,String relatedId,String refundId,String gatewayName ){
        Recurring_Payment__c rp = new Recurring_Payment__c(Amount__c=amount,Date_Established__c=estDate,Gateway_Name__c=gatewayName,Status__c='Open',Next_Installment_Date__c=nxtDate,Installment_Period__c=installmentPeriod,RelatedToId__c=relatedId,
                                                           Refund_Amount__c=1,Refund_Status__c='AWAITING',Gateway_Schedule_Id__c=scheduleId,Gateway_Refund_Id__c=refundId);
        
        insert rp;
        return rp;
    }
    
    public static List<Transaction__c> createTransactions(Integer numOfTransactions, String frequency, Datetime fromDate,Decimal amount,Id recurringId){
        
        List<Transaction__c> transactionList = new List<Transaction__c>();
        for(Integer i=0;i<numOfTransactions;i++){
            Transaction__c tran = new Transaction__c();
            if(frequency=='Weekly' && i>=1){
                tran.Transaction_Date__c=fromDate.addDays(7);
            }else if(frequency=='Monthly' && i>=1){
                tran.Transaction_Date__c=fromDate.addDays(30);
            }else if(frequency=='Fortnightly' && i>=1){
                tran.Transaction_Date__c=fromDate.addDays(30);
            }else{
                tran.Transaction_Date__c=fromDate;
            }
            tran.Transaction_Status__c='Scheduled';
            tran.Gateway_Name__c='Ezidebit';
            tran.Amount__c = amount;
            tran.Recurring_Payment__c=recurringId;
            fromDate=tran.Transaction_Date__c;
            transactionList.add(tran);
        }
        insert transactionList;
        return transactionList;
    }
    
    public static Transaction__c createTransaction(String RPrefId, Decimal amount, DateTime transactiondate, String status, String gateway){
        Transaction__c trans = new Transaction__c();
        trans.Recurring_Payment__c = RPrefId;
        trans.Gateway_Name__c = gateway;
        trans.Amount__c = amount;
        trans.Transaction_Date__c = transactiondate;
        trans.Transaction_Status__c = status;
        trans.RecordTypeId = (RPrefId != null) ? Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Recurring').getRecordTypeId() : Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('One_Time').getRecordTypeId();
        insert trans;
        return trans;
    }
    
        public static Transaction__c createTransactionNABFail(String RPrefId, Decimal amount, DateTime transactiondate){
        Transaction__c trans = new Transaction__c();
        trans.Recurring_Payment__c = RPrefId;
        trans.Gateway_Name__c = 'NAB Transact';
        trans.Amount__c = amount;
        trans.Transaction_Date__c = transactiondate;
        trans.Transaction_Status__c = 'Scheduled';
        trans.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
        insert trans;
        return trans;
    }

    public static Transaction__c createTransactionPaywayPaid(String RPrefId, Decimal amount, DateTime transactiondate){
        Transaction__c trans = new Transaction__c();
        trans.Recurring_Payment__c = RPrefId;
        trans.Gateway_Name__c = 'Payway';
        trans.Amount__c = amount;
        trans.Transaction_Date__c = transactiondate;
        trans.Transaction_Status__c = 'Paid';
        trans.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
        insert trans;
        return trans;
    }
    public static Transaction__c createTransactionPaywayScheduled(String RPrefId, Decimal amount, DateTime transactiondate){
        Transaction__c trans = new Transaction__c();
        trans.Recurring_Payment__c = RPrefId;
        trans.Gateway_Name__c = 'Payway';
        trans.Amount__c = amount;
        trans.Transaction_Date__c = transactiondate;
        trans.Transaction_Status__c = 'Scheduled';
        trans.RecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
        insert trans;
        return trans;
    }

    //Payway Specific
    public static Payment_Log__c createValidOneTimeLog(String merchant, String contactID, String tokenValue){
        TransactionWrapper oneoffReq = new TransactionWrapper();
        oneoffReq.sfProcessingId = contactID;
        oneoffReq.merchantId =  merchant;
        oneoffReq.tokenValue = tokenValue; 
        oneoffReq.pcurrency = 'aud';
        oneoffReq.amount = 15;
        oneoffReq.transactionType = 'payment';
        oneoffReq.customerNumber = 'customerReference';
        oneoffReq.actiontype = 'OneTime';
        oneoffReq.transactionPayload = PaywayHelper.createOneTimePayLoad(oneoffReq);
        oneoffReq.encodedCustomerNumber = UTILGateway.encodeCustomerKeys('customerReference');
        oneoffReq.transactionreference = '';
        //Log for Post checkout page.
        String onetimeTransactionWrapper = JSON.serialize(oneoffReq);
        Payment_Log__c plog = new Payment_Log__c(Q_Charge__Gateway_Name__c = 'payway', Processing_Record_Id__c = contactID, Action__c = 'Payway - Post Checkout Requested', Request_Type__c = 'POST', Amount__c = 15, Charge_Type__c = 'OneTime', End_Point__c = '/apex/Q_Charge__GatewayPostCheckout?recordId=',Serialized_Record__c = onetimeTransactionWrapper);
        insert plog;

        return plog;
    }

    public static Payment_Log__c createRePayLog(String merchant, String contactID, String tokenValue)
    {
        RecurringWrapper recurringReq = new RecurringWrapper();
        recurringReq.amount = 15;
        recurringReq.merchantId =  merchant;
        recurringReq.tokenValue = tokenValue;
        recurringReq.instalPeriod = 'weekly';
        recurringReq.nextPaymentDate = UTILGateway.convertDatetoString(Date.today());
        recurringReq.name = 'Nate Angus';
        //creating transaction request payload.
        recurringReq.transactionPayload = PaywayHelper.createReccurringPayLoad(recurringReq);
        recurringReq.startDate = Date.today();
        recurringReq.transactionreference = '11194123189';
        recurringReq.sfProcessingId = contactID;
        //Log for reciept page.
        String recurringRequest = JSON.serialize(recurringReq);
        
        Payment_Log__c paymentLog = new Payment_Log__c(Q_Charge__Gateway_Name__c = 'payway', Processing_Record_Id__c = contactID,Action__c = 'Payway - Post Checkout Requested', 
        Request_Type__c = 'POST', Amount__c = 15, Charge_Type__c = 'Recurring', End_Point__c = '/apex/Q_Charge__GatewayPostCheckout?recordId=',Serialized_Record__c = recurringRequest);
        insert paymentLog;
        
        return paymentLog;
    }

    public static Payment_Log__c createRetryRPLog(String merchant, String contactID, String frequency , Date paymentdate, String tokenValue)
    {
        RecurringWrapper recurringReq = new RecurringWrapper();
        recurringReq.amount = 15;
        recurringReq.merchantId =  merchant;
        recurringReq.tokenValue = tokenValue;
        recurringReq.customerNumber = 'h0jyYk9ofG42DCKHTr939ELAp0ccluYQRRs9hgNNyZI=';
        recurringReq.instalPeriod = frequency;
        recurringReq.nextPaymentDate = UTILGateway.convertDatetoString(paymentdate);
        recurringReq.name = 'Nate Angus';
        //creating transaction request payload.
        recurringReq.transactionPayload = PaywayHelper.createReccurringPayLoad(recurringReq);
        recurringReq.startDate = paymentdate;
        recurringReq.transactionreference = '11194123189';
        recurringReq.sfProcessingId = contactID;
        //Log for reciept page.
        String recurringRequest = JSON.serialize(recurringReq);
        
        Payment_Log__c paymentLog = new Payment_Log__c(Q_Charge__Gateway_Name__c = 'payway', Processing_Record_Id__c = contactID, Action__c = 'Payway - Post Checkout Requested', 
        Request_Type__c = 'POST', Amount__c = 15, Charge_Type__c = 'Recurring', End_Point__c = '/apex/Q_Charge__GatewayPostCheckout?recordId=',Serialized_Record__c = recurringRequest);
        insert paymentLog;
        
        return paymentLog;
    }

    public static Payment_Log__c createPaymentLog(String gatewayName,Decimal amount,String relatedId,String installPeriod,Date startDate,String chargeType,String action,String requestUrl,String wrapper){

        Payment_Log__c log= new Payment_Log__c();
        log.Gateway_Name__c = gatewayName;
        log.Processing_Record_Id__c=relatedId;
        log.Amount__c=amount;
        log.Frequency__c=installPeriod;
        log.Recurring_Start_Date__c=startDate;
        log.Action__c=action;
        log.Charge_Type__c=chargeType;
        log.Requesting_Url__c=requestUrl;
        log.Serialized_Record__c=wrapper;
        insert log;
        return log;
    }

    public static String ezidebitOneTimeSuccessResponse(){
        return '{"BankReceiptID":"32221291","ExchangePaymentID":"49000200","PaymentResult":"A","PaymentResultCode":"00","PaymentResultText":"APPROVED"}';
    }

    public static String ezidebitOneTimeDeclinedResponse(){
        return '{"BankReceiptID":"32221455","ExchangePaymentID":"49000854","PaymentResult":"F","PaymentResultCode":"56","PaymentResultText":"DECLINED"}';
    }

    public static String simplifyOneTimeSuccessResponse(){
        return '{"transactionId":"RMp8oKgpe","transactionStatus":"APPROVED","transactionDateTime":"2022-03-09T07:33:46Z"}';
    }

    public static String simplifyRecurringToken(){
        return 'a1f59409-77b0-4ed9-9fd0-842bbcf748d8';
    }

}