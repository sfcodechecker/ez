({
    //function for fetching the status of Payway gateway
    getGateway: function(component, event){
        var action = component.get("c.SpecificGatewayDetails");        
        action.setParams({'gateWayName' : 'payway' }); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.GateWayData", response.getReturnValue()); 
                component.set("v.isOpen", true);
            }
            else 
            {
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },
    
    //Function for authenticating gateway
    UpdateGateway: function(component, event){
        var action = component.get("c.UpdateGatewayDetails");        
        action.setParams({'Gateway' : component.get("v.GateWayData"),
                          'GateWayName' : 'payway' }); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            var state = response.getState();
            component.set("v.showSpinner",false);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();   
                if(result == 'valid' || result.startsWith('prod')){                    
                    component.set("v.isOpen", false);
                    component.set("v.isConnected", true);
                    $A.enqueueAction(component.get('c.doInit'));
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"success","message": "Payway "+component.get('v.GatewayConnected')});
                    toastEvent.fire();
                }else{
                    component.set("v.isOpen", true);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type": "warning","duration": 10000,"message": result});
                    toastEvent.fire();
                }
            }else {
                this.ParseError(component, event, response);
            }             
        });
        $A.enqueueAction(action);
    },

    FireEvent:function(component,event,isTrue){
        var successfulAuthentication=component.getEvent('successfulAuthentication');
        successfulAuthentication.setParams({
            label:"PAYWAY",
            value:"PAYWAY",
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
                "message": errorData.messagetoUser
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