public with sharing class GatewayReceiptPageController {
    
    /*********************** variables ********************************/
    public String amount{get;set;}
    public String paymentStatus{get;set;}
    public String paymentResponse{get;set;}
    public String paymentId{get;set;}
    public String installPeriod{get;set;}
    public String establishmentDate{get;set;}
    public String nextInstallmentDate{get;set;}  
    public String returnUrl{get;set;}
    public String responseText{get;set;}
    public String chargeType{get;set;}
    public String renderPanel;
    public String logReferenceId;
    public List<Payment_Log__c> receiptLog;
    public String requestUrl{get;set;}
    ReceiptWrapper receiptWrap = new ReceiptWrapper();
    public String status{get;set;}
    
    
    //multiple querries can be reduced
    public GatewayReceiptPageController(){
        try{
            receiptLog = new List<Payment_Log__c>();
            logReferenceId = ApexPages.currentPage().getParameters().get('reference').escapeHtml4();
            if(logReferenceId != '' && logReferenceId != null){
                receiptLog = [Select Id, Name, Amount__c,Gateway_name__c, Serialized_Record__c ,Retry_Schedule_URL__c, Charge_Type__c, Payload__c, Processing_Record_Id__c 
                From Payment_Log__c 
                Where Id =: logReferenceId WITH SECURITY_ENFORCED limit 1];
                if(receiptLog[0].Gateway_name__c==UTILGateway.STRIPEWORD){
                   status = ApexPages.currentPage().getParameters().get('status').escapeHtml4();
                }else{
                    status='accept';
                }
            }else {
                paymentResponse = MessageHandler.missingLogId;
            }
            If(receiptLog.size() > 0){
                receiptWrap = (ReceiptWrapper)JSON.deserialize(receiptLog[0].Serialized_Record__c, ReceiptWrapper.Class);
                //amount = String.valueOf(receiptWrap.amount);
                
                amount =(receiptWrap.amount != null) ? receiptWrap.amount.format().contains('.')?receiptWrap.amount.format():receiptWrap.amount.format()+'.00' : '';
                
                if(receiptWrap.paymentId != null){
                    paymentId = receiptWrap.paymentId;
                }

                requestUrl=receiptWrap.requestUrl;
                paymentStatus = receiptWrap.paymentStatus;
                paymentResponse = receiptWrap.paymentResponse;
                chargeType = receiptWrap.chargeType;
				                
                if(chargeType == UTILGateway.RECURRINGKEYWORD){
                    establishmentDate = receiptWrap.establishmentDate.format();
                    installPeriod = receiptWrap.installPeriod;
                    renderPanel = receiptWrap.renderPanel;

                    if(paymentStatus == 'Payment Approved'){
                        nextInstallmentDate= receiptWrap.nextInstallmentDate.format();
                    }
                }
            }
            else{
                paymentResponse = MessageHandler.incorrectLogId;
            }
        }
        catch(Exception Exc){
            EmailHandler.sendExceptionEmail('GatewayReceiptPageController',Exc,null);
        }
    }
    
    public void retryTransaction(){
        try{         
            UTILGateway.PayLogSet_JSON.add(JSON.serialize(new Payment_Log__c(Gateway_Name__c = receiptLog[0].Gateway_Name__c,Processing_Record_Id__c = receiptLog[0].Processing_Record_Id__c, Amount__c = receiptLog[0].Amount__c, Action__c = receiptLog[0].Gateway_Name__c+' - Retrying ' +receiptLog[0].Charge_Type__c , Charge_Type__c = receiptLog[0].Charge_Type__c,Transaction_Status__c = 'Void', Payload__c = receiptLog[0].Payload__c, Serialized_Record__c = receiptLog[0].Serialized_Record__c)));
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            if(receiptLog[0].Retry_Schedule_URL__c == null || receiptLog[0].Retry_Schedule_URL__c == ''){
                returnUrl = receiptWrap.requestUrl+''+logReferenceId;
            }else if(receiptLog[0].Retry_Schedule_URL__c != ''){
                returnUrl = receiptLog[0].Retry_Schedule_URL__c;
            }else{
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, MessageHandler.wentWrongCatchMessage));
            }
        }
        catch(Exception ex){
            EmailHandler.sendExceptionEmail('GatewayReceiptPageController', ex, false);
        }
    }
}