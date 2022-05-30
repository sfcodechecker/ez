({    
    /*
     * @description do server side call to fetch current data of gateways info on load of the comonent.
     */ 
    doInit: function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'BPoint'}); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.GateWayData", response.getReturnValue());  
                var res = component.get("v.GateWayData"); 
                if(res.Id != undefined){ 
                    var isProduction = (res.Q_Charge__isSandbox__c==true)?false:true;
                    component.set('v.isProduction',isProduction) 
                    component.set("v.isConnected", true); 
                    helper.FireEvent(component,event,res.Q_Charge__Default__c);
                }
                component.set("v.showSpinner",false);
            }else {
                helper.ParseError(component, event, response);
                component.set("v.showSpinner",false);
            }               
        });
        $A.enqueueAction(action);
    },
    openModel: function(component, event, helper) {
        component.set("v.isOpen", true); 
    },
    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
        var isConnected=component.get("v.isConnected");
        if(!isConnected)
            $A.enqueueAction(component.get('c.doInit'));
    }, 
    processLogin: function(component, event, helper) {    
        var ClientData=component.get("v.GateWayData");
        var isProduction = component.get('v.isProduction');
        ClientData.Q_Charge__isSandbox__c= (isProduction==true)?false:true;
        component.set("v.showSpinner",true);
        ClientData.Q_Charge__Client_Id__c = ClientData.Q_Charge__Client_Id__c==undefined?ClientData.Q_Charge__Client_Id__c:ClientData.Q_Charge__Client_Id__c.trim();
        ClientData.Q_Charge__Optional_Key_1__c = ClientData.Q_Charge__Optional_Key_1__c == undefined ? ClientData.Q_Charge__Optional_Key_1__c:ClientData.Q_Charge__Optional_Key_1__c.trim();
        ClientData.Q_Charge__Client_Key__c = ClientData.Q_Charge__Client_Key__c == undefined ? ClientData.Q_Charge__Client_Key__c : ClientData.Q_Charge__Client_Key__c.trim();
        if((ClientData.Q_Charge__Client_Id__c ==undefined || ClientData.Q_Charge__Client_Id__c.length<1) && (ClientData.Q_Charge__Optional_Key_1__c==undefined || ClientData.Q_Charge__Optional_Key_1__c.length<1) && (ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length<1))
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.UsrMrchntpassBpoint')
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
                "message": component.get('v.PkAndMerchantBpoint')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        if((ClientData.Q_Charge__Optional_Key_1__c ==undefined || ClientData.Q_Charge__Optional_Key_1__c.trim().length<1) && (ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.trim().length<1))
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.SkAndMerchantBpoint')
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
                "message": component.get('v.UsrAndPassBpoint')
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
                "message": component.get('v.UsrBpoint')
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
                "message": component.get('v.PassBpoit')
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
                "message": component.get('v.MerchantBpoint')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        helper.UpdateGateway(component, event);
    }, 
    ChangeLogin: function(component, event, helper) {
        component.set("v.isConnected", false); 
        component.set("v.GateWayData.Q_Charge__Client_Id__c","");
        component.set("v.GateWayData.Q_Charge__Optional_Key_1__c","");
        component.set("v.GateWayData.Q_Charge__Client_Key__c","");
        component.set("v.isProduction",false);
    },
})