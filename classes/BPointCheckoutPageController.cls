public with sharing class BPointCheckoutPageController {
    public String authKey { get;set; }
    public Decimal amount { get;set; }
    public String showAmount {get;set;}
    public String paymentAmount {get;set;}
    public String charge_type { get;set; }
    public BpointTxnResponseWrapper result;
    public String referenceId{get;set;}
    public String errorMessage{get;set;}

    public List<Payment_Log__c> ref_log {get;set;}
    public List<Contact> payeeDetails;
    public String email {get; set;}
    public string phone {get;set;}
    public string name {get; set;}
    
    public String paymentDate {get; set;}
    public String frequency {get; set;}
    public String recordId {get;set;}
    public string buttonname {get;set;}


    public BPointCheckoutPageController() {
        authKey = ApexPages.currentPage().getParameters().get('authkey').escapeHtml4();
        amount = Decimal.valueOf(ApexPages.currentPage().getParameters().get('amount').escapeHtml4());
        paymentAmount = String.valueOf(amount);
        showAmount = amount.format().contains('.')?amount.format():amount.format()+'.00';
        charge_type = ApexPages.currentPage().getParameters().get('charge_type').escapeHtml4();
        referenceId = ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
        
        buttonname = (charge_type == UTILGateway.RECURRINGKEYWORD) ? 'Subscribe' : 'Charge';

        if(referenceId != 'null' && referenceId != '' && referenceId != null){
            ref_log=[Select Processing_Record_Id__c,Amount__c,Charge_Type__c,Serialized_Record__c,Frequency__c,Recurring_Start_Date__c,Requesting_Url__c from Payment_Log__c where Id=:referenceId WITH SECURITY_ENFORCED Limit 1];
            recordId= (ref_log.size()>0) ? ref_log[0].Processing_Record_Id__c : '';
            paymentDate = (ref_log[0].Recurring_Start_Date__c != null) ?  UTILGateway.convertDatetoString(ref_log[0].Recurring_Start_Date__c) : null;
            frequency = ref_log[0].Frequency__c;
            
            if(recordId != '' && recordId != null){
                payeeDetails = [select id,firstName,LastName,Email,Phone from contact where Id=:recordId WITH SECURITY_ENFORCED Limit 1];
                email = (ref_log.size()>0) ? PayeeDetails[0].Email : '';
                phone = (ref_log.size()>0) ? PayeeDetails[0].Phone : '';
                name = ( ref_log.size()>0) ? ((payeeDetails[0].FirstName != null) ? payeeDetails[0].FirstName+' '+payeeDetails[0].LastName : payeeDetails[0].LastName) : '';
            }
        }
    }

    public PageReference completeTransaction(){
        //result = BpointTxnResponseWrapper.parse(ApexPages.currentPage().getParameters().get('respFromBpoint'));
        //insert everything in log object and pass to post checkout
       /* UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Q_Charge__End_Point__c = '/apex/Q_Charge__BPointCheckoutPage', 
                                                                         Q_Charge__Request_Type__c = 'POST',
                                                                         Q_Charge__HTTP_Response__c = ApexPages.currentPage().getParameters().get('respFromBpoint'),
                                                                         Q_Charge__Gateway_Name__c = UTILGateway.BPOINTWORD,
                                                                         Q_Charge__Charge_Type__c = charge_type))); // Add to Log
        List<Payment_Log__c> paymentLog = UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);*/
        return new PageReference('apex/GatewayPostCheckout?reference='+referenceId);
    } 

}