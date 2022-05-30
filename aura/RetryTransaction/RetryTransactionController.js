({
	doInit : function(component, event, helper) {
		var action = component.get('c.getTransactionDetails');
		action.setParams({"recordId":component.get('v.recordId')});
		action.setCallback(this, function(response){
			var state = response.getState();
			component.set('v.showSpinner',true);
			if(state === 'SUCCESS'){
				var result = response.getReturnValue();
				if(result.Q_Charge__Gateway_Name__c == 'nab transact'){
					

					if(result.Q_Charge__Transaction_Status__c == 'Cancelled'){
						var toastEvent = $A.get("e.force:showToast");
						toastEvent.setParams({"type":"warning","message": component.get('v.TransactionCancelledRetry')});
						toastEvent.fire();
						$A.get("e.force:closeQuickAction").fire();
					}
					else if(result.Q_Charge__Transaction_Status__c == 'Paid'){
						var toastEvent = $A.get("e.force:showToast");
						toastEvent.setParams({"type":"warning","message": component.get('v.TransactionPaidRetry')});
						toastEvent.fire();
						$A.get("e.force:closeQuickAction").fire();
					}
					else if(result.Q_Charge__Transaction_Status__c == 'Scheduled'){
						var toastEvent = $A.get("e.force:showToast");
						toastEvent.setParams({"type":"warning","message": component.get('v.RetryScheduledTransaction')});
						toastEvent.fire();
						$A.get("e.force:closeQuickAction").fire();
					}
					else if(result.Q_Charge__Gateway_Name__c != null){
						var checkIsConnected = component.get("c.isGatewayConnected");
						checkIsConnected.setParams({"gatewayName":result.Q_Charge__Gateway_Name__c});
						checkIsConnected.setCallback(this,function(response){
								var state = response.getState();
								var result = response.getReturnValue();
								if(state === "SUCCESS"){
									if(result == true){
										component.set('v.showModel',true);
                                        component.set('v.showSpinner',false);
                                        component.set("v.isDisabled",false);
									}
                                    else{
                                        $A.get("e.force:closeQuickAction").fire();
										component.set('v.showModel',false);
										var toastEvent = $A.get("e.force:showToast");
										toastEvent.setParams({"type":"warning","message": component.get('v.RetryTransactionOnDisconnectedGateway')});
										toastEvent.fire();
										return;
                                    }
								}
						});
						$A.enqueueAction(checkIsConnected);
					}
				}
				else{
					component.set('v.showSpinner',true);
					var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"type":"warning","message": component.get('v.FeatureOnlyNAB')});
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
				}
			}else{
				helper.ParseError(component,event,response);
			}
		});
		$A.enqueueAction(action);
	},

	confirm : function(component, event, helper){
		component.set('v.showSpinner',true);
		helper.retryTransaction(component, event);
	},

	closeModal : function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})