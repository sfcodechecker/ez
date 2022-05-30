({
    //function to get the status of the gateways
    getGateway: function(component, event){
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'simplify' }); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.GateWayData", response.getReturnValue());
                var result=response.getReturnValue();
                if(result.Id!=null){
                    component.set("v.isOpen", true);   
                    component.set("v.isConnected",true);
                }
                
            }else {
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    //function to authenticate the gateway
    UpdateGateway: function(component, event){
        var action = component.get("c.UpdateGatewayDetails");    
        console.log('Inside here');    
        action.setParams({'Gateway' : component.get("v.GateWayData"),'GateWayName':'simplify'}); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            component.set("v.showSpinner",false);
            console.log(response);
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();      
                if(result=='valid'){
                    component.set("v.isOpen", false);
                    component.set("v.isConnected", true);
                    $A.enqueueAction(component.get('c.doInit'));
                        var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "duration": "10000",
                        "message": 'Simplify '+component.get('v.GatewayConnected')
                    });
                    toastEvent.fire();

                }else if(result.includes('auth.invalid.keys')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.GatewayConnectionFailed')
                });
                toastEvent.fire();
                return;
                }else if(result.includes('auth.bad.sig')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    "type": "warning",
                    "duration": "10000",
                    "message": component.get('v.GatewayConnectionFailed')
                });
                toastEvent.fire();
                return;
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    "type": "error",
                    "duration": "10000",
                    "message": result
                });
                toastEvent.fire();
                return;
                }
                this.FireEvent(component,event,res.Q_Charge__Default__c);
            }else {
                console.log("Enetered helper 2");
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    FireEvent:function(component,event,isTrue){
        var successfulAuthentication=component.getEvent('successfulAuthentication');
        successfulAuthentication.setParams({
            label:"SIMPLIFY",
            value:"SIMPLIFY",
            isdefault:isTrue
        });
        successfulAuthentication.fire();
    },
    //function to parse the error messages
    ParseError: function(component, event, response){
        var errorMsg = '';
        var state = response.getState();
        if(state == 'ERROR'){            
            let errors = response.getError();
            let errorData = JSON.parse(errors[0].message);
            errorMsg = errorData.exception_Message_StackTrace;
            console.error(errorData.exception_Message_StackTrace);
            //General error toast message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "duration": 10000,
                "message":component.get('v.SomethingWentWrong')
            });
            toastEvent.fire();
        } else{            
            let errors = response.getError();
            let message = 'Unknown error. '; // Default error message
            // Retrieve the error message sent by the server
            var i;
            if (errors && Array.isArray(errors) && errors.length > 0) {
                for (i = 0; i < errors.length; i++) { 
                    message = message +'Error'+ i + ':' + errors[i].message;
                }
            }
            // Display the message
            console.error(message); errorMsg = message;            
            //General error toast message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "duration": 10000,
                "message": component.get('v.SomethingWentWrong')
            });
            toastEvent.fire();            
        }
        var sendError = component.get("c.sendExceptionEmail");
        sendError.setParams({"emailBody": errorMsg });
        $A.enqueueAction(sendError);
    }
})