({    
    /*
     * @description do server side call to fetch current data of gateways info on load of the comonent.
     */ 
    doInit: function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'stripe'}); 
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.GateWayData", response.getReturnValue()); 
                component.set("v.showSpinner",false); 
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
    openModel: function(component, event, helper) {  
        component.set("v.isOpen", true);    
    },    
    closeModel: function(component, event, helper) {  
        component.set("v.isOpen", false);
        var isConnected = component.get("v.isConnected");
        if(!isConnected)
            $A.enqueueAction(component.get('c.doInit'));
    }, 
    processLogin: function(component, event, helper) { 
        var stripekey = component.get("v.GateWayData");
        //check if client id is  null
        stripekey.Q_Charge__Client_Id__c = (stripekey.Q_Charge__Client_Id__c != undefined && stripekey.Q_Charge__Client_Id__c.trim() != '' ?  stripekey.Q_Charge__Client_Id__c : undefined) ;
        stripekey.Q_Charge__Client_Key__c = (stripekey.Q_Charge__Client_Key__c != undefined && stripekey.Q_Charge__Client_Key__c.trim() !='' ?  stripekey.Q_Charge__Client_Key__c : undefined) ;
        if(stripekey.Q_Charge__Client_Id__c == undefined || stripekey.Q_Charge__Client_Key__c == undefined){
            var key = (stripekey.Q_Charge__Client_Id__c == undefined && stripekey.Q_Charge__Client_Key__c == undefined ? 'Publishable key and Secret key' :
                       (stripekey.Q_Charge__Client_Id__c == undefined ? 'Publishable key' : 'Secret key' )) ;
            var article = (stripekey.Q_Charge__Client_Id__c == undefined && stripekey.Q_Charge__Client_Key__c == undefined ? 'are' :'is');        
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": "Gateway cannot be setup. "+key+" provided "+article+" empty. please provide a valid "+key+"."
            });
            toastEvent.fire();
            return;
        }
        else if(stripekey.Q_Charge__Client_Id__c != undefined && stripekey.Q_Charge__Client_Id__c.trim() != '' && !stripekey.Q_Charge__Client_Id__c.startsWith("pk_")){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.StripePKInvalid')
            });
            toastEvent.fire();
            return;
        }
        component.set("v.showSpinner",true);
        helper.UpdateGateway(component, event);
    }, 
    ChangeLogin: function(component, event, helper) {  
        component.set("v.isConnected", false); 
        component.set("v.GateWayData.Q_Charge__Client_Id__c","");
        component.set("v.GateWayData.Q_Charge__Client_Key__c","");
        component.set("v.GateWayData.Q_Charge__Optional_Key_1__c","");
    },
})