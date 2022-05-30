public with sharing class NABTransactCheckoutController 
{   
    /*********************** variables ********************************/
    public string showAmount{get;set;}
    public String endPoint{get;set;}
    public string chargeType{get;set;}
    public String merchantId{get;set;}
    public boolean tokenStore{get;set;}
    public string tokenStoreType{get;set;}         
    public String amount{get;set;}
    public Integer transactionType{get;set;}
    public String paymentReference{get;set;}
    public String GMTtimestamp{get;set;}
    public String fingerprintValue{get;set;}
    public String resultURL{get;set;}
    public Boolean redirect{get;set;}
    public boolean resultParams{get;set;}    
    public String recordId;
    public string installPeriod {get;set;} 
    public Date startDate;
    public string transactionPassword;
    public String combineString;
    public Blob hmacData;
    public String btnName{get;set;}
    public List<String> expiryYear{get;set;}
    public List<String> monthsOfYear{get;set;}


    //changes added by VS
    public Contact payeeDetails;
    public String email {get; set;}
    public string phone {get;set;}
    public string name {get; set;}
    public String paymentDate {get; set;}
    public String paymentAmount {get; set;}

    public NABTransactCheckoutController(){
        try{
            Gateway_Detail__c Gateway = UTILGateway.decodeKeys(UTILGateway.NABTRANSWORD);
            paymentReference = ApexPages.currentPage().getParameters().get('reference').escapeHtml4();

            Payment_Log__c ref_log = [Select Id, Name, Amount__c, Charge_Type__c, Processing_Record_Id__c, End_Point__c, Frequency__c, Recurring_Start_Date__c, Transaction_Id__c From Payment_Log__c where Id =: paymentReference WITH SECURITY_ENFORCED LIMIT 1];
            
            showAmount = String.valueOf(ref_log.Amount__c);
            recordId = ref_log.Processing_Record_Id__c;

            endPoint = ref_log.End_Point__c;
            chargeType = ref_log.Charge_Type__c;
            installPeriod = ref_log.Frequency__c;
            startDate = ref_log.Recurring_Start_Date__c;
            paymentDate = (ref_log.Recurring_Start_Date__c != null) ?  UTILGateway.convertDatetoString(ref_log.Recurring_Start_Date__c) : null;
            paymentAmount = ref_log.Amount__c.format().contains('.')?ref_log.Amount__c.format():ref_log.Amount__c.format()+'.00';


            expiryYear = UTILGateway.expiryYearGenerator();
            monthsOfYear = UTILGateway.monthsGenerator();


            payeeDetails = [select id,firstName,LastName,Email,Phone from contact where Id=:recordId WITH SECURITY_ENFORCED Limit 1];
            email = PayeeDetails.Email;
            phone = PayeeDetails.Phone;
            name = ((payeeDetails.FirstName != null)) ? payeeDetails.FirstName+' '+payeeDetails.LastName : payeeDetails.LastName;

            
            GMTtimestamp = DateTime.now().formatGMT('yyyyMMddHHmmss');
            amount = String.valueOf(Integer.valueOf(Decimal.valueOf(showAmount)*100));
            if(Gateway == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, MessageHandler.prevStartDate));
                return;
            }
            if(Decimal.valueOf(showAmount) <= 0){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,MessageHandler.amountLessThan1Cent));
                return;
            }
            if(Decimal.valueOf(showAmount) > 99999999.99){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,MessageHandler.amountAboveLimit));
                return;
            }
            merchantId = Gateway.Client_Id__c;          
            transactionPassword = Gateway.Client_Key__c;  
            redirect = TRUE;
            resultParams = TRUE;

            if(chargeType == UTILGateway.RECURRINGKEYWORD){
                tokenStore = TRUE;
                tokenStoreType = 'TOKEN';
            }
            resultURL = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Q_Charge__GatewayPostCheckout?reference='+paymentReference;

            //generating fingerprint
            if(chargeType == UTILGateway.ONETIMEKEYWORD){
                btnName='Charge';
                transactionType = 0;
                combineString = merchantId+'|'+transactionPassword+'|'+transactionType+'|'+paymentReference+'|'+amount+'|'+GMTtimestamp;
            }
            else if(chargeType == UTILGateway.RECURRINGKEYWORD){
                btnName='Setup';
                transactionType = 8; 
                combineString = merchantId+'|'+transactionPassword+'|'+transactionType+'|'+tokenStoreType+'|'+paymentReference+'|'+GMTtimestamp;
            }
            hmacData = Crypto.generateMac('HMACSHA256', Blob.valueOf(combineString), Blob.valueOf(transactionPassword));
            fingerprintValue = EncodingUtil.convertToHex(hmacData);
        }
        catch(Exception ex){
            system.debug(ex.getMessage()+' at '+ex.getLineNumber()+'\n Stack Trace:'+ex.getStackTraceString());
            EmailHandler.sendExceptionEmail('NABTransactCheckoutController', ex, false);
        }
    }
}