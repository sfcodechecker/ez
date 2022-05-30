public with sharing class StripeCheckoutController {
    
    public String publisher_key {get;set;}
    public String session_id {get;set;} 
    public Boolean GoodToRedirectToStripe {get;set;}
    
    public StripeCheckOutController(){
        GoodToRedirectToStripe = false;
        try{ 
            session_id = ApexPages.currentPage().getParameters().get('session_id');
            if(StripeManager.detachedReason != null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,StripeManager.detachedReason));
            }else{
                publisher_key = StripeManager.StripeGateWay.Client_Id__c;
                if(session_id == null || publisher_key == null)
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,MessageHandler.apiKeyMissing));            
                else
                    GoodToRedirectToStripe = true;
            }
        } /*catch(UTIL_Permission.PermsException e){ // Permission issues will not send the email.
            GoodToRedirectToStripe = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'Checkout cannot be performed. '+e.getMessage()));
        }*/ catch(Exception ex){
            GoodToRedirectToStripe = false;
            EmailHandler.sendExceptionEmail('StripeCheckOutController',ex,null);
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'Checkout cannot be performed. '+ex.getMessage()));
        }
    } 
}