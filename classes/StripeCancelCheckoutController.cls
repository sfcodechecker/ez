public with sharing class StripeCancelCheckoutController {
    
    public String refreshPage{get;set;}
    public String responseMessage{get;set;}
    public String record_id{get;set;}

    public StripeCancelCheckoutController() {        
        record_id = ApexPages.currentPage().getParameters().get('record_id').escapeHtml4(); 
        responseMessage = MessageHandler.updateCardfailed+MessageHandler.stripeTransactionCancelled;
    }
    
    public void completeSuccess(){        
        if(ApexPages.currentPage().getParameters().get('requestedURL').escapeHtml4() != null)
            refreshPage = EncodingUtil.urlDecode(ApexPages.currentPage().getParameters().get('requestedURL').escapeHtml4(),'UTF-8');
        else 
            refreshPage = URL.getSalesforceBaseUrl().toExternalForm().substringAfter('//')+'/'+record_id;
    }
}