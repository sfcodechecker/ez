({
	retryTransaction : function(component, event) {
		var action = component.get('c.retryCurrentTransaction');
		action.setParams({"recordId":component.get('v.recordId')});
		action.setCallback(this,function(response){
			var state = response.getState();
            console.log(state);
            console.log(response.getReturnValue());
            component.set('v.showSpinner',false);
			if(state==='SUCCESS'){
                var result=response.getReturnValue();
                console.log(result);
				if(result.includes('Successful')){
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"success","message": component.get('v.TransactionSuccessful')});
                    toastEvent.fire();
                }
				else{
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"error","message": result});
                    toastEvent.fire();
                }
			}else{
				helper.ParseError(component,event,response);   
			   }
		});
		$A.enqueueAction(action);
	},

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