public with sharing class MessageHandler {
    
    /* *************************** General ****************************/
    public static String apiKeyMissing = 'Checkout cannot be performed. Keys were not found. Please visit EzyCharge Setup tab and verify the credentials.';
    public static string noCredential = 'Invalid login credentials. Please visit EzyCharge Setup tab and verify the credentials.';
    public static string loginFailed = 'Unable to validate login credentials. Please verify the credentials.'; 

    public static string reqFieldAmount = 'You must enter the Amount before processing to charge the payment.';
    public static String amountBelowOneDoller = 'Amount cannot be less than one, please specify a valid Amount.';
    public static string amountDecimalLimit = 'Amount cannot be charged, gateway supports only two decimal places. Please specify Amount accordingly.';
    public static string amountLessThan1Cent = 'Amount cannot be charged, please specify Amount equal or greater than $0.01 (AUD).';
    public static String amountLessThan50Cent = 'Amount cannot be charged, please specify Amount equal or greater than $0.50 (AUD).';
    public static string amountMoreThanLimit = 'Amount cannot be charged, please specify Amount less than or equal to the limit $10,000.00 (AUD).';
	public static string emailRequired = 'Recurring Payment cannot be setup, Contact does not have an email. Please specify an email on the Contact.';
    
    public static string chargeTypeMissing = 'Charge Type field cannot be empty. Please refresh and try again, if you are still running into trouble please contact your system administrator.';
    public static string frequencyMissing = 'You must enter the Installment Type before setting up the Recurring Payment.';
    public static string startDateMissing = 'You must enter the Installment Date before setting up the Recurring Payment.';
    public static String prevStartDate = 'Recurring Payment cannot be setup, gateway does not support an earlier date. Please specify today or future date.';

    public static string invalidRPStatus = 'Unable to update Recurring Payment, Only open Recurring Payment can be updated. Please contact the system administrator.';
    public static String updateRP=' updated successfully in ';//prepend Recurring ID(Name)
    public static String cancelRP=' cancelled successfully';//prepend Recurring ID(Name)
    public static String creditCardUpdatSuccesse = 'Card details successfully updated in ';//append+ Gateway Name
    public static String updateCardfailed = 'Unable to update credit card details due to ';//append reason of failure
    public static String failedUpdateCard = 'Unable to update credit card details. Please click on retry to start the process again.';

    
	public static string wentWrongCatchMsgFun(String exceptionMessage){
        return 'Something went wrong. '+exceptionMessage+'. Please refresh and try again, if you are still running into same issue please contact your system administrator.';
    }
    public static string wentWrongCatchMessage = 'Something went wrong. Please refresh and try again, if you are still running into same issue please contact your system administrator.'; 
    public static string recordNotCreated = 'Something went wrong while creating a record in Salesforce. Please contact the system administrator.' ;

    public static String enableRetry = 'Please click on retry to start the process again.';
    public static String spinnerWait = 'Please wait do not close...';
    public static String spinnerCardValidate = 'Please wait while we validate your credit card details...';
        
    public static string onetimeSuccess = 'Payment is charged successfully.';
    public static string onetimeFailed = 'Payment is not charged due to ';//prepend with issues occure
    public static string onetimePending = 'Payment is currently processing.';

    public static string recurringSuccess = 'Recurring Payment is setup successfully.';
    public static string recurringFailed = 'Recurring Payment is not setup due to '; //prepend with issues occures during setup
    public static string recPayUpdtFailed = 'Recurring Payment is not updated due to ';//prepend with issues occure during update



    /* *************************** Stripe ****************************/
       
    public static String stripeAleardyProcessed = 'Stripe payment is already processed. '; 
    public static String payIntent_cancel = 'Payment processing not successful. Stripe says, this invalidates the intent for future confirmation, and cannot be undone. ';
    public static String payIntent_requires_payment_method = 'Payment processing not successful. Stripe says, Waiting to be attach a payment method. ';
    public static String payIntent_requires_confirmation = 'Payment processing not successful. Stripe says, an intent with a payment method is ready to be confirmed. ';
    public static String payIntent_requires_action = 'Payment processing not successful. Stripe says, Payment method requires additional actions, such as authenticating with 3D Secure.';
    public static String payIntent_processing = 'Payment processing not successful. Stripe says, once required actions are handled, the intent moves to processing. '; 
    public static String payError = 'Payment processing not successful. Stripe says, some required values are missing, please provide  values for processing. '; 
    public static String noTransactionInitated = 'No transaction was initiated for this payment. ';
    public static String stripeTransactionCancelled = 'Stripe transaction was cancelled. Please close the window.';
       
    public static string stripeRPNotUpdated = 'Recurring Payment was not updated in Stripe. ';// prepends with issue during RP update in stripe.
    public static string stripeRPNotCancel = 'Recurring Payment was not cancelled in Stripe. '; //prepends with issue during RP cancel in stripe.
   
    public static string stripeCardNotUpdated = 'Card details was not updated in Stripe. '; // prepends with issue during card update in stripe.
    public static string stripeCardnotSetup = 'Card was not setup in Stripe. '; // prepends with issue during card setup in stripe.
    public static string stripeUnblToGetRPInfo= 'Unable to get Recurring Payment information from Stripe. '; // prepends with issue during fetch RP details in stripe.
    
    public static string setupInfoError(String CheckOutId){//
       return MessageHandler.stripeCardNotUpdated + 'Unable to get card setup information from Stripe. Please ask your Stripe administrator to check '+CheckOutId+' checkout information in Stripe. ';
    }

    /* *************************** Simplify ****************************/
    public static string simplifyRPFailed = 'Recurring Payment is not setup.';//Curently we dont recieve any reason for failure 
    public static string simplifyOneOffFailed = 'Payment is not charged.';//Curently we dont recieve any reason for failure 


    /****************************** Ezidebit************************/
    public static String ezidebitprocessingTimeProductionRecurring = 'Recurring Payment cannot be setup,gateway will not process payments on or after 3:00 PM. Please select a future date.';
    public static String ezidebitprocessingTimeProductionRecurringUpdate = 'Recurring Payment cannot be updated,gateway will not process payments on or after 3:00 PM. Please select a future date.';
    public static String ezidebitprocessingTimeSandbox = 'Ezidebit will not process payments on or after 6:00 PM. Please select a future date.';
    public static String ezidebitprocessingTimeProduction = 'Ezidebit will not process payments on or after 3:00 PM. Please select a future date.';
    //public static String ezidebitamountAboveLimit='The total amount due cannot be more than 10,000(AUD), please specify a amount less than 10,000(AUD).';
    public static String ezidebitEddr='Link to the eDDR page cannot be found, Please specify the eDDR page during authentication.';//remove after demo 
    public static String ezidebitWeekendSetup='Recurring Payment cannot be setup,gateway does not support Recurring Payments on weekends. Please choose a weekday.';
    public static String ezidebitWeekendUpdate='Recurring Payment cannot be updated,gateway does not support Recurring Payments on weekends. Please choose a weekday.';
    public static String ezidebitWeekend='Ezidebit does not support Recurring Payments on weekends. Please choose a weekday.';
    public static String urlEdit = 'Unable to process request. Payment information is not found. Please refresh and try again.';
    public static string invalidParams = 'Unable to process request. Payment information is not found. Please refresh and try again.';//These cases need to be defined well.

    
    /****************************** Payway ************************/
    public static string authFailed = 'Gateway cannot be setup ';//append error messages 
    public static string authFailedPublicKey = 'Gateway cannot be setup, Publishable key is not valid. Please provide a valid Publishable key. ';
    public static string authFailedSecretKey = 'Gateway cannot be setup, Secret key is not valid. Please provide a valid Secret key. ';//Unable to connect to Payway
    public static string merchantInvalidMessage = 'Gateway cannot be setup, Merchant Id did not matched. Please provide a valid Merchant Id. ';
    

    public static String startDateMorethan1Year = 'Recurring Payment cannot be updated. Installment date cannot be a more than 1 year. Please select a date less than 1 year. ';
    public static String startDatelessthan13days ='Recurring Payment cannot be updated. Installment date for a fortnightly Recurring Payment must be within 13 days. Please select a valid date. ';
    public static String startDatelessthan6days = 'Recurring Payment cannot be updated. Installment date for a weekly Recurring Payment must be within 6 days. Please select a valid date. ';
    public static String startDatelessthan1month = 'Recurring Payment cannot be updated. Installment date must be within the last month. Please select a valid date. ';
    
    public static string missingLogId = 'Unable to process request. Payment information is not found. Please refresh and try again.';
    public static string incorrectLogId = 'Unable to process request. Please check the information provided. Please refresh and try again.'; // 'Incorrect log information provided,  ';
    public static string missingRecordID = 'Unable to process request. Contact is not found. Please contact your system administrator.';

    public static string cardValidationFailed = 'Unable to validate credit card due to ';//prepend with the issues occured during validate card.
    public static string cardvalidationPending = '$1.00 AUD charge for card validation is taking time. Recurring Payment is successfully updated into Salesforce.';
    public static string scheduleTransacionPending = 'Card validation is taking time. Recurring Payment is successfully created into Salesforce. ';
    public static string updatedWithWrongCard = 'Recurring Payment is updated with incorrect credit card details.';
    public static String recRetryCardUpdtFailed = 'Unable to perform retry on Recurring Payment. Card details are not updated due to';//Prepend with the issues occured during retry RP

    public static string faildetoCancel = ' unable to cancel due to '; //Prepend RP Id (Name)
    public static string refreshAndTryagain = '. Please refresh and try again. '; // append with response message.
    public static string paymentNotSettled = 'Unable to refund the charged Amount. credit card payments are only refundable after they have settled.';


    /***************************NAB Transact******************************/
    public static string amountAboveLimit = 'Amount cannot be charged, gateway supports Amount less than or equal to $99,999,999.99 (AUD). Please specify Amount less than or equal to limit $99,999,999.99 (AUD).';
    public static String transactionError = 'Transaction not successful. Some fields are missing, please provide required values to complete the transaction.';//These cases need to be defined well.
    public static String noResponseFromNAB = 'No Response from NAB Transact gateway.';
    

    /**************************************************************************************************************/
    //******//                                      Log Action name                                     //********//
    /**************************************************************************************************************/
    
    
    /******************************* General Actions ************************************/
    public static String accessOnetimePage = ' - Request Onetime Checkout Page';
    public static String accessRecPayPage = ' - Request Recurring Payment Checkout Page';
    public static String accessUpdateCardPage = ' - Request Update card Checkout Page';

    public static string onetimeCheckoutfail = ' - Onetime Checkout Failed';
    public static String oneTimeCheckoutComplete =' - Onetime Checkout Complete';
    public static string recPayCheckoutfail = ' - Recurring Payment Checkout Failed';
    public static String recPayCheckoutComplete =' - Recurring Payment Checkout Complete' ;

    public static String checkCredential = ' - Verify the credentials';
    public static string storingResponse = ' - Storing response';
    public static String inativeCustomer = ' - Changing the customer status to inactive'; //stopping customer future payments. 

    public static String createPlan = ' - Creating the plan';
    public static string createRPFailed = ' - Create Recurring Payment Failed';
    public static String createCustomer = ' - Creating the customer';
    public static String cancelRecPay = ' - Cancelling Recurring Payment';
    public static string cancelRecPaySuccess = ' - Cancel Recurring Payment Successful';
    public static String fetchRPDetails = ' - Fetching Customer/Recurring Payment Details from Gateway';

    public static string validateCard = ' - Validating credit card';
    public static string updateCardDetails = ' - Updating credit card details';
    public static string updateCardRequest = ' - Update Card Detail Request';
    public static string updateCardfail = ' - Update Credit Card Detail Failed';

    public static string updateRPFailed = ' - Update Recurring Payment Failed';
    public static string updateRpSuccess = ' - Update Recurring Payment Successful';
    public static String updateRPDetails = ' - Updating Recurring Payment in gateway';

    public static String refundAction = ' - Processing Refund';
    public static string fetchSingleRPTransaction = ' - Fetching single transaction of a customer';
    public static String fetchRecurringPayments = ' - Fetching all transactions of a Customer/Recurring Payment'; 

    public static string processPayment(String gatewayName, String tansactionType){
        return gatewayName+' - Create '+ tansactionType +' Payment';
    } 
    

    /****************************** Payway Actions ******************************/
    public static String checkMerchantid = ' - Verify the Merchant Id';
    public static string requestPostCheckout = ' - Post Checkout Page Requested';


    /***************************** Nab Transact Actions *************************/
    public static string storingCredential= ' - Storing the credentials';
    public static string chargeRecTransaction = ' - Charge Recurring Payment transaction';
    public static string chargeFailed = ' - Charge Failed Transaction';
    public static string onetimeDeclined = ' - OneTime Payment failed';
    public static string retryLog = ' - Log raised for retry payment request';


    /****************************** Ezidebit Actions *****************************/
    public static string retryRPRequest = ' - Retry eDDR Page Request';
    public static String fetchCardDetail = ' - Fetch Card Details from Gateway';
    

    /******************************* Stripe Actions ******************************/
    public static String logUpdateCard = ' - Log raised for updating card on Recurring Payment ';
    public static String checkProductid = ' - Verify the product id';
    public static string verifyCredBeforeStore = ' - Verify the credentials before storing in Salesforce';
    public static string verifyProdIdBeforeStore = ' - Verify the product id in stripe before storing in Salesforce';
    public static string createProdIdBeforeStoe = ' - Creating the product id in stripe before storing in Salesforce';
    public static String oneTimeCheckoutSession = ' - Creating the checkout session for one time charge';
    public static string oneTimeCheckoutResponse = ' - Checkout session response of one time charge';
    public static String chekTransactinStatus = ' - Check the status of transaction';
    public static String checkCheckoutProcessing = ' - Check the processing of checkout';
    public static string checkScheduleSession = ' - Check the Recurring Payment session';
    public static string createScheduleSession = ' - Creating the checkout session for Recurring Payment';
    public static String fetchPayMethodofscheule = ' - Fetch the payment method details of Recurring Payment';
    public static string fetchUpcomingInvoice = ' - Fetch the upcoming invoices of Recurring Payment';
    public static String updateCardSession = ' - Creating the session for update card details';
    public static String fetchSetupIntent = ' - Fetch the response for setup intent';
    public static String updatePaymentMethod = ' - Update payment method with the customer';
    public static String attachPaymentIntent = ' - Attach payment intent to a customer';
    public static string fetchSesionResponse = ' - Fetch the response for session';

}