({    
    /*
     * @description do server side call to fetch current data of gateways info on load of the comonent.
     */
    
    //fetch status of gateways upon loading
    doInit: function(component, event, helper){
        component.set("v.showSpinner",true);
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'ezidebit'}); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.GateWayData", response.getReturnValue());  
                component.set("v.showSpinner",false); 
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
        ClientData.Q_Charge__Client_Id__c =(ClientData.Q_Charge__Client_Id__c != undefined)? ClientData.Q_Charge__Client_Id__c.trim():undefined;
        ClientData.Q_Charge__Client_Key__c = (ClientData.Q_Charge__Client_Key__c != undefined)? ClientData.Q_Charge__Client_Key__c.trim():undefined;
        ClientData.Q_Charge__isSandbox__c=(component.get('v.isProduction')==true)?false:true;
        component.set("v.showSpinner",true);
        if((ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length==0) && (ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length==0)){
             var key='Public key & Digital';
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.PkAndSkEzidebit')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;

        }
        //check if client id is  null and the length is not 36 characters
        if(ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length<1)
        {
            var key='Public';
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message":component.get('v.PkEzidebitEmpty')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }else if(ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length<1)
        {
            var key='Digital';
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.SkEzidebitEmpty')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }else if(ClientData.Q_Charge__Client_Id__c==undefined || ClientData.Q_Charge__Client_Id__c.length!=36)
        {
            var key='Public';
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message":component.get('v.PkEzidebit')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }else if(ClientData.Q_Charge__Client_Key__c==undefined || ClientData.Q_Charge__Client_Key__c.length!=36)
        {
            var key='Digital';
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "duration": 10000,
                "message": component.get('v.SkEzidebit')
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
            return;
        }
        if(ClientData.Q_Charge__Schedule_Page_URL__c!=undefined && ClientData.Q_Charge__Schedule_Page_URL__c.trim().length>0){
            var startindex=ClientData.Q_Charge__Schedule_Page_URL__c.indexOf('?')+3;
            var endindex=ClientData.Q_Charge__Schedule_Page_URL__c.indexOf('&');
            var pk=ClientData.Q_Charge__Schedule_Page_URL__c.substring(startindex,endindex);
            
            if(ClientData.Q_Charge__Client_Id__c != pk){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "duration": 10000,
                    "message": "Client Id provided does not match with the key in url, Please check the key."
                });
                toastEvent.fire();
                component.set("v.showSpinner",false);
                return;
            }
        }
        helper.UpdateGateway(component, event);
    }, 
    //change the login details
    ChangeLogin: function(component, event, helper) {  
        component.set("v.isConnected", false); 
        component.set("v.GateWayData.Q_Charge__Client_Id__c","");
        component.set("v.GateWayData.Q_Charge__Client_Key__c","");
        component.set("v.GateWayData.Q_Charge__Schedule_Page_URL__c","");
        
    },
    
})