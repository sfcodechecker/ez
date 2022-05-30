({
    /********handle the gateway change from the server********/
    handleGatewayChange: function(component,event){
        var action = component.get('c.setDefaultGateway');
        action.setParams({
            'GatewayName' : component.get('v.selectedGateway'),
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state==='SUCCESS'){
                var result = response.getReturnValue();
                if(result){
                    var toastEvent = $A.get("e.force:showToast");
                    var selectedGateway=component.get('v.selectedGateway');
                    toastEvent.setParams({"type":"success","message":selectedGateway.toUpperCase().replace('_',' ')+" is set as default successfully."});
                    toastEvent.fire();   
                }   
            }else{
                this.ParseError(component,event,response);
            }
        });
        $A.enqueueAction(action);
    },
    
    /************Parses the error from response*********/
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
                "message": errorData
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
                "message": "Something went wrong. Please refresh and try again, still error continues contact Admin."
            });
            toastEvent.fire();            
        }
    }
})