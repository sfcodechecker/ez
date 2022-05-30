public with sharing class GateWaySetup {
    
    /**    Make code security compatible to get clean report fro scanner  **/
    
    
    // fetch the specific gateway details if not found returns instance of metadata.
    @AuraEnabled
    public static Gateway_Detail__c SpecificGatewayDetails(String gateWayName){
        Gateway_Detail__c eachGateway = new Gateway_Detail__c(); 
        String Response = '';
        
        try{
            gateWayName = gateWayName.replaceAll(' ', '_').toLowerCase(); // replaces the blank space with underscore(_) and convert into lower case.
            
            eachGateway = UTILGateway.decodeKeys(gateWayName);
            if(gateWayName == UTILGateway.StripeWord && eachGateway != null) {                
                Response = (StripeManager.isConnected ? 'valid' : StripeManager.detachedReason);
            }else if(gateWayName == UTILGateway.PaywayWord && eachGateway != null)  { 
                Response = (PaywayManager.isConnected ? 'valid' : PaywayManager.detachedReason);                                          
            }else if(gateWayName == UTILGateway.EzidebitWord && eachGateway !=null){
                Response=(EzidebitManager.isConnected ? 'valid' : EzidebitManager.detachedReason);  
            }else if(gateWayName == UTILGateway.BpointWord && eachGateway!=null){
                Response=(BPointManager.isConnected ? 'valid' : BPointManager.detachedReason);
            }else if(gateWayName == UTILGateway.NabTransWord && eachGateway!=null){
                Response = (NABTransactManager.isConnected ? 'valid' : NABTransactManager.detachedReason);
            }else if(gateWayName == UTILGateway.SimplifyWord && eachGateway!=null){
                Response=(SimplifyManager.isConnected) ? 'valid' : SimplifyManager.detachedReason;
            }
            else{
                // fo other gateways
                eachGateway = new Gateway_Detail__c();  
            }
            if(Response == 'valid'){
                if(eachGateway?.Client_Id__c != null){                
                    Integer index = Integer.ValueOf(eachGateway.Client_Id__c.length()/7);
                    eachGateway.Client_Id__c = eachGateway.Client_Id__c.left(index)+'...'+eachGateway.Client_Id__c.right(index);
                }
                if(eachGateway?.Client_Key__c != null){                
                    Integer index = Integer.ValueOf(eachGateway.Client_Key__c.length()/7);
                    eachGateway.Client_Key__c = eachGateway.Client_Key__c.left(index)+'...'+eachGateway.Client_Key__c.right(index);
                }
                if(eachGateway?.HostedPayments_PublicKey__c != null){                
                    Integer index = Integer.ValueOf(eachGateway.HostedPayments_PublicKey__c.length()/7);
                    eachGateway.HostedPayments_PublicKey__c = eachGateway.HostedPayments_PublicKey__c.left(index)+'...'+eachGateway.HostedPayments_PublicKey__c.right(index);
                }
                if(eachGateway?.HostedPayments_PrivateKey__c != null){                
                    Integer index = Integer.ValueOf(eachGateway.HostedPayments_PrivateKey__c.length()/7);
                    eachGateway.HostedPayments_PrivateKey__c = eachGateway.HostedPayments_PrivateKey__c.left(index)+'...'+eachGateway.HostedPayments_PrivateKey__c.right(index);
                }
                if(eachGateway.Schedule_Page_URL__c != null){
                    Integer index = Integer.ValueOf(eachGateway.Schedule_Page_URL__c.length()/7);
                    eachGateway.Schedule_Page_URL__c = eachGateway.Schedule_Page_URL__c.left(index)+'...'+eachGateway.Schedule_Page_URL__c.right(index);
                }
            }
            if(Response != 'valid'){ 
                eachGateway = new Gateway_Detail__c(); 
            }                
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            return eachGateway;
        }Catch(Exception ex){ 
            return eachGateway; 
        } 
    }
    
    
    // fetch the specific gateway details if not found returns instance of metadata.
    @AuraEnabled
    public static String UpdateGatewayDetails(Gateway_Detail__c Gateway, String GateWayName){ 
        System.debug(Gateway);
        try{
            GateWayName = GateWayName.replaceAll(' ', '_').toLowerCase(); // replaces the blank space with underscore(_) and convert into lower case.
            Gateway.Name__c = GateWayName;
            String gateWayResponse = '';
            if([Select Id from Gateway_Detail__c Where Name__c != Null].size()==0){
                Gateway.Default__c=true;
            }
            
            if(GateWayName == UTILGateway.StripeWord){
                gateWayResponse = StripeManager.PostCredentails(Gateway);
            }else if(GateWayName == UTILGateway.PaywayWord){   
                gateWayResponse = PaywayManager.validateCredentials(Gateway,true);
            }else if(GateWayName == UTILGateway.EzidebitWord){
                gateWayResponse = EzidebitManager.validateCredentials(Gateway,true); 
            }else if(GateWayName == UTILGateway.BpointWord){
                gateWayResponse = BPointManager.validateCredentials(Gateway);        
            }else if(GateWayName == UTILGateway.NabTransWord){
                gateWayResponse = NABTransactManager.PostCredentials(Gateway);
            }else if(GateWayName == UTILGateway.SimplifyWord){
                gateWayResponse=SimplifyManager.validateCredentials(Gateway,true);
            }
            if(gateWayResponse.startsWith('valid')){
                UTILGateway.encodeKeys(Gateway);
                if(UTILPermission.CheckSingleObject('Q_Charge__Gateway_Detail__c','Upsert')) 
                    Database.upsert(new List<Gateway_Detail__c>{Gateway},Gateway_Detail__c.Name__c, true);
            } 
            UTILGateway.MaintainLog(UTILGateway.PayLogSet_JSON);
            return gateWayResponse;
        }Catch(Exception ex){ 
            return MessageHandler.wentWrongCatchMessage+' Due to: '+ex.getMessage()+''+ex.getLineNumber();
        }
    }
    
    
    
    
    // fetch the specific gateway details if not found returns instance of metadata.
    /*  @AuraEnabled
public static String AuthenticateNAB(Gateway_Detail__c Gateway, Boolean Environment){       
return NABTransactManager.AuthenticateAPIcode(Gateway, Environment);
}
*/
    /*@AuraEnabled
    public static string AuthenticateSimplify(Gateway_Detail__c Gateway) {
        Gateway.Q_Charge__Name__c = UTILGateway.SIMPLIFYWORD;
        Gateway.Q_Charge__Optional_Key_1__c = String.valueOf(Crypto.getRandomInteger());
        UTILGateway.encodeKeys(Gateway);
        if(UTILPermission.CheckSingleObject('Q_Charge__Gateway_Detail__c','Upsert')) 
            Database.upsert(new List<Gateway_Detail__c>{Gateway},Gateway_Detail__c.Name__c, true);
        return SimplifyManager.getAuthorizationCode(Gateway.Q_Charge__Optional_Key_1__c);
    }*/
    
    
    // Sends an Exception email to support.    
    @AuraEnabled
    public static void sendExceptionEmail(String emailBody){
        EmailHandler.sendEmailTo('Error occurred during the process', emailBody, null, false);
    }
    
    /*********Get Active Payment Gateways*********/
    @AuraEnabled
    public static List<ChargeNowController.ComboClass> getActivePaymentList(){
        try {
            List<ChargeNowController.ComboClass> paymentGateways=ChargeNowController.ActivePaymentList();
            return paymentGateways;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /************Sets gateway as default and changes the status of default gateway*************/
    @AuraEnabled
    public static Boolean setDefaultGateway(String GatewayName){
        Boolean returnFlag=false;
        GatewayName=GatewayName.toLowerCase().replaceAll(' ', '_');
        try {
            if(UTILPermission.CheckSingleObject('Q_Charge__Gateway_Detail__c', 'update')){
                List<Gateway_Detail__c> gatewayDetails = [Select Name__c,Default__c from Gateway_Detail__c With SECURITY_ENFORCED];
                for(Gateway_Detail__c gateway : gatewayDetails){
                    if(gateway.Name__c != GatewayName && gateway.Default__c != false){
                        gateway.Default__c=false;                        
                    }else if(gateway.Name__c == GatewayName){
                        gateway.Default__c=true;
                        returnFlag=true;
                    }
                }
                update gatewayDetails;
            }
            return returnFlag;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}