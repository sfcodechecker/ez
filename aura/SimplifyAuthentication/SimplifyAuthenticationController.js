({    
    /*
    * @description do server side call to fetch current data of gateways info on load of the comonent.
    */
    
    //fetch status of gateways upon loading
    doInit: function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'simplify'}); 
        action.setCallback(this,function(response){
            component.set("v.showSpinner",false);
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.GateWayData", response.getReturnValue());  
                var res = component.get("v.GateWayData");
                if(res.Id != undefined){ 
                    component.set("v.isConnected", true); 
                    helper.FireEvent(component,event,res.Q_Charge__Default__c);
                }                   
            }else {
                helper.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    //open the input model
    openModel: function(component, event, helper) {  
        component.set("v.isOpen", true);    
    },   
    //close the input model 
    closeModel: function(component, event, helper) {  
        component.set("v.isOpen", false);
        var isConnected=component.get("v.isConnected");
        if(!isConnected)
        $A.enqueueAction(component.get('c.doInit'));
    }, 
    //process the login details
    processLogin: function(component, event, helper) { 
        component.set("v.showSpinner",true);

        var ClientData=component.get("v.GateWayData");
        ClientData.Q_Charge__HostedPayments_PublicKey__c =(ClientData.Q_Charge__HostedPayments_PublicKey__c != undefined)? ClientData.Q_Charge__HostedPayments_PublicKey__c.trim():undefined;
        ClientData.Q_Charge__HostedPayments_PrivateKey__c = (ClientData.Q_Charge__HostedPayments_PrivateKey__c != undefined)? ClientData.Q_Charge__HostedPayments_PrivateKey__c.trim():undefined;
        //check if pubilc key of hosted page is empty
        if((ClientData.Q_Charge__HostedPayments_PublicKey__c == undefined || ClientData.Q_Charge__HostedPayments_PublicKey__c.length==0) && 
            (ClientData.Q_Charge__HostedPayments_PrivateKey__c == undefined || ClientData.Q_Charge__HostedPayments_PrivateKey__c.length==0))
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.PkAndSkSimplify')
                });
                toastEvent.fire();
                component.set("v.showSpinner",false);
                return;
            } else if(ClientData.Q_Charge__HostedPayments_PublicKey__c == undefined || ClientData.Q_Charge__HostedPayments_PublicKey__c.length==0) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.PkSimplify')
                });
                toastEvent.fire();
                
                component.set("v.showSpinner",false);

                return;
            }else if(ClientData.Q_Charge__HostedPayments_PrivateKey__c == undefined || ClientData.Q_Charge__HostedPayments_PrivateKey__c.length==0){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.SkSimplify')
                });
                toastEvent.fire();
                component.set("v.showSpinner",false);
                return;
            }else if(ClientData.Q_Charge__HostedPayments_PrivateKey__c == ClientData.Q_Charge__HostedPayments_PublicKey__c){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.PkSKSameSimplify')
                });
                toastEvent.fire();
                component.set("v.showSpinner",false);
                return;
            }
            var hostedpaymentKey=ClientData.Q_Charge__HostedPayments_PublicKey__c;
            var SandboxKey=hostedpaymentKey.split('_');
            if(SandboxKey[0]=='sbpb'){
                ClientData.Q_Charge__isSandbox__c=true;
            }else if(SandboxKey[0]=='lvpb'){
                ClientData.Q_Charge__isSandbox__c=false;
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.PkInvalidSimplify')
                });
                toastEvent.fire();
                component.set("v.showSpinner",false);
                return;
            }

            helper.UpdateGateway(component, event);
            
        }, 
        //change the login details
        ChangeLogin: function(component, event, helper) {  
            component.set("v.isConnected", false); 
            component.set("v.GateWayData.Q_Charge__HostedPayments_PublicKey__c","");
            component.set("v.GateWayData.Q_Charge__HostedPayments_PrivateKey__c","");
        },

        validateCredentials: function(component, event, helper){
            component.set("v.GateWayData.Q_Charge__HostedPayments_PublicKey__c","");
            component.set("v.GateWayData.Q_Charge__HostedPayments_PrivateKey__c","");
            component.set("v.isOpen", false);
        },
        
    })