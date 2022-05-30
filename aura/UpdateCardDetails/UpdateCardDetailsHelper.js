({  
    getRecurringRecord : function(component,event){
      var action=component.get("c.getRecurringRecord");
      action.setParams({"recordId":component.get("v.recordId")});
      action.setCallback(this,function(response){
          var state=response.getState();
          var resultRecord=response.getReturnValue();
          if(state==='SUCCESS'){
            component.set('v.RecurringDetails',resultRecord);
            var checkIsConnected = component.get("c.isGatewayConnected");
            checkIsConnected.setParams({"gatewayName":resultRecord.Q_Charge__Gateway_Name__c});
            checkIsConnected.setCallback(this,function(response){
                  var state = response.getState();
                  var result = response.getReturnValue();
                  if(state === "SUCCESS"){
                      if(result == false){
                          $A.enqueueAction(component.get('c.closeModel'));
                          component.set('v.showModel',false);
                          var toastEvent = $A.get("e.force:showToast");
                          toastEvent.setParams({"type":"warning","message": component.get('v.UpdateCardDetailsOnDisconnectedGateway')});
                          toastEvent.fire();
                          return;
                      }else if(resultRecord.Q_Charge__Status__c=='Cancelled' || resultRecord.Q_Charge__Status__c=='Closed'){
                          component.set('v.showModel', false);
                          var toastEvent = $A.get("e.force:showToast");
                          toastEvent.setParams({"type":"warning","message": component.get('v.UpdateCardFailedRPClosed')});
                          toastEvent.fire();
                          $A.enqueueAction(component.get('c.closeModel'));
                          return;
                      }else if(resultRecord.Q_Charge__Refund_Status__c=='Awaiting'){
                          component.set("v.showSpinner",false);
                          component.set('v.showModel', true);
                          var toastEvent = $A.get("e.force:showToast");
                          toastEvent.setParams({"type":"warning","message": component.get('v.RefundPendingWhileUpdateCard')});
                          toastEvent.fire();
                      }
                      else{
                        component.set('v.showModel', true);
                        component.set('v.showSpinner', false);

                      }
                      if(resultRecord.Q_Charge__Gateway_Name__c == 'nab transact'){
                          component.set('v.showModel', true);
                          component.set("v.showSpinner",false);
                          var geTransactionStatus = component.get("c.geTransactionStatus");
                          geTransactionStatus.setParams({"recordId":component.get("v.recordId")});
                          geTransactionStatus.setCallback(this, function(response){
                              var state = response.getState();
                              var result = response.getReturnValue();
                              if(state === 'SUCCESS'){
                                  if(result == true){
                                      component.set('v.showMsg', true);
                                  }
                                  if(resultRecord.Q_Charge__Refund_Status__c=='Awaiting'){
                                          var toastEvent = $A.get("e.force:showToast");
                                          toastEvent.setParams({"type":"warning","message": component.get('v.RefundPendingWhileUpdateCard')});
                                          toastEvent.fire();
                                      }
                              }
                          });
                          $A.enqueueAction(geTransactionStatus);
                      }
                  }
            });
            $A.enqueueAction(checkIsConnected);
            component.set('v.isDisabled',false);
        }else{
              this.ParseError(component,event,response);
          }
      });
      $A.enqueueAction(action);

    },
    updateCardDetails : function(component,event){
        component.set("v.showSpinner",true);
        var action=component.get("c.updateCardDetails");
        action.setParams({
            existingRPId:component.get("v.recordId"),
            requestUrl:window.location.href
        });
        action.setCallback(this,function(response){
             var state=response.getState();
             var result=response.getReturnValue();
             if(state === "SUCCESS"){
                 if(result.includes('/apex')){
                    var WindWidth = 800;
                    var WindHeight = 800;
                    var left = (screen.width - WindWidth) / 2;
                    var top = (screen.height - WindHeight) / 2;
                    window.open(result, 'EzyCharge Payments | EzyCharge','width=' + WindWidth + ', height=' + WindHeight + ', top=' + top + ', left=' + left);
                    $A.get("e.force:closeQuickAction").fire();
                 }else{
                    component.set("v.showSpinner",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"error","message": result});
                    toastEvent.fire();
                 }
             }else{
                 this.ParseError(component,event,response); 
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