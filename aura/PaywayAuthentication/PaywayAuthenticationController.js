({    
/*
     * @description do server side call to fetch current data of gateways info on load of the comonent.
     */
    
    //fetch status of gateways upon loading
    doInit: function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'payway'}); 
        action.setCallback(this,function(response){
            var errorMsg = '';
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
        var ClientData=component.get("v.GateWayData");
        component.set("v.showSpinner",true);
        ClientData.Q_Charge__Client_Id__c =(ClientData.Q_Charge__Client_Id__c != undefined)? ClientData.Q_Charge__Client_Id__c.trim():undefined;
        ClientData.Q_Charge__Client_Key__c = (ClientData.Q_Charge__Client_Key__c != undefined)? ClientData.Q_Charge__Client_Key__c.trim():undefined;
        ClientData.Q_Charge__Optional_Key_1__c = (ClientData.Q_Charge__Optional_Key_1__c != undefined)? ClientData.Q_Charge__Optional_Key_1__c.trim():undefined;
        if((ClientData.Q_Charge__Optional_Key_1__c ==undefined || ClientData.Q_Charge__Optional_Key_1__c.length<1) && (ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length<1) && (ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length<1))
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.PkMerchantSkPayway')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        if((ClientData.Q_Charge__Optional_Key_1__c  ==undefined || ClientData.Q_Charge__Optional_Key_1__c.length<1) && (ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length<1))
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.PkAndMerchantPayway')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        if((ClientData.Q_Charge__Optional_Key_1__c  ==undefined || ClientData.Q_Charge__Optional_Key_1__c.length<1) && (ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length<1))
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.SkAndMerchantPayway')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        
        if((ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length<1 )&& (ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length<1))
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.PkAndSkPayway')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        
        if(ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length<1)
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.PkPayway')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        //check if client key is  null
        if(ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length<1)
        {

            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.SkPayway')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        //check if merchant ID is  null 
        if(ClientData.Q_Charge__Optional_Key_1__c ==undefined || ClientData.Q_Charge__Optional_Key_1__c.length<1)
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.MerchantIdPayway')
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
        component.set("v.GateWayData.Q_Charge__Client_Id__c","");
        component.set("v.GateWayData.Q_Charge__Client_Key__c","");
        component.set("v.GateWayData.Q_Charge__Optional_Key_1__c","");
    },
    
})