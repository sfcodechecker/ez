({
    UpdateGateway: function(component, event){
        var action = component.get("c.UpdateGatewayDetails");        
        action.setParams({'Gateway' : component.get("v.GateWayData"),
                          'GateWayName' : 'bpoint'}); 
        action.setCallback(this,function(response){
            var errorMsg = '';
            var state = response.getState(); 
            if (state === "SUCCESS") {
                var result = response.getReturnValue(); 
                if(result == 'valid' || result.startsWith('prod')){                    
                    component.set("v.isOpen", false);
                    component.set("v.isConnected", true);
                    var res=component.get("v.GateWayData"); 
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"success","message": "BPoint "+component.get('v.GatewayConnected')});
                    toastEvent.fire();
                    $A.enqueueAction(component.get('c.doInit'));
                    //this.FireEvent(component,event,res.Q_Charge__Default__c);
                }else if(result.includes('Invalid credentials')){
                   component.set("v.isOpen", true);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "warning",
                        "duration": 10000,
                        "message": result
                    });
                    toastEvent.fire(); 
                }else{
                    component.set("v.isOpen", true);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "duration": 10000,
                        "message": result
                    });
                    toastEvent.fire();
                }
                component.set("v.showSpinner",false);
            }else {
                // Configure error toast
                let errors = response.getError();
                let toastParams = {
                    title: "Error",
                    message: "Unknown error", // Default error message
                    type: "error"
                };
                // Pass the error message if any
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    toastParams.message = errors[0].message;
                }
                // Fire error toast
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams(toastParams);
                toastEvent.fire();
                this.ParseError(component, event, response);
                component.set("v.showSpinner",false);
            }             
        });
        $A.enqueueAction(action);
    },
    FireEvent:function(component,event,isTrue){
        var successfulAuthentication=component.getEvent('successfulAuthentication');
        successfulAuthentication.setParams({
            label:"BPOINT",
            value:"BPOINT",
            isdefault:isTrue
        });
        successfulAuthentication.fire();
    },
    ParseError: function(component, event, response){
        var errorMsg = '';
        var state = response.getState();
        if(state == 'ERROR'){            
            let errors = response.getError();
            console.log("errors"+error.message);
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