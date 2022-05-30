({    
    /*
     * @description do server side call to fetch current data of gateways info on load of the comonent.
     */ 
    doInit: function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'NAB Transact'}); 
        action.setCallback(this,function(response){
            component.set("v.showSpinner",false);
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
        var isConnected=component.get("v.isConnected");
        if(!isConnected)
            $A.enqueueAction(component.get('c.doInit'));
    }, 
    processLogin: function(component, event, helper) { 
        var api_key=component.get("v.GateWayData");
        api_key.Q_Charge__isSandbox__c=(component.get('v.isProduction')==true)?false:true;
        //check if client id is  null
        api_key.Q_Charge__Client_Id__c = (api_key.Q_Charge__Client_Id__c != undefined && api_key.Q_Charge__Client_Id__c.trim() != '' ?  api_key.Q_Charge__Client_Id__c : undefined) ;
        api_key.Q_Charge__Client_Key__c = (api_key.Q_Charge__Client_Key__c != undefined && api_key.Q_Charge__Client_Key__c.trim() !='' ?  api_key.Q_Charge__Client_Key__c : undefined) ;
        if(api_key.Q_Charge__Client_Id__c == undefined || api_key.Q_Charge__Client_Key__c == undefined){
            var key = (api_key.Q_Charge__Client_Id__c == undefined && api_key.Q_Charge__Client_Key__c == undefined ? 'Merchant Id and Transaction Password' :
                       (api_key.Q_Charge__Client_Id__c == undefined ? 'Merchant Id' : 'Transaction Password' )) ;
            var article = (api_key.Q_Charge__Client_Id__c == undefined && api_key.Q_Charge__Client_Key__c == undefined ? 'are' :'is');        
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": "Gateway cannot be setup. "+key+" provided "+article+" empty. Please provide a valid "+key+"."
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
    },
    handleUserChange: function(component, event) {
        var isChecked = component.find('checkuser').get('v.checked');
    },
    
})