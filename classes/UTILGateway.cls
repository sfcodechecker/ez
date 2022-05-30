public with sharing class UTILGateway {
    
    /************** Gateway's Keywords ********************************/
    public static FINAL String STRIPEWORD = 'stripe';
    public static FINAL String PAYWAYWORD = 'payway';
    public static FINAL String NABTRANSWORD = 'nab_transact';
    public static FINAL String EZIDEBITWORD = 'ezidebit';
    public static FINAL String SIMPLIFYWORD = 'simplify';
    public static FINAL String BPOINTWORD = 'bpoint';
    public static Final String ONETIMEKEYWORD = 'OneTime';
    public static FINAL String RECURRINGKEYWORD = 'Recurring';

    public static boolean allowRPUpdate=false;
    
    private static Blob CryptoKey = Blob.valueOf(Q_Charge__Setting__mdt.getInstance('Key').Q_Charge__Encode_Key__c);
    
    public static LIST<String> PayLogSet_JSON = new LIST<String>();
    
    // method to create a logs.
    
    public static List<Payment_Log__c> MaintainLog(LIST<String> PayLog_JSON){
        List<Payment_Log__c> payLogList = new List<Payment_Log__c>();
        for(String eachLog : new SET<String>(PayLog_JSON)){
            payLogList.add((Payment_Log__c)JSON.deserialize(eachLog, Sobject.class));
        }
        if(!payLogList.isEmpty() && UTILPermission.CheckSingleObject('Q_Charge__Payment_Log__c','Create'))
            Database.insert(payLogList, true);
        return payLogList;
    }
    
    /*******Method to encode the keys******/
    public static void encodeKeys(Gateway_Detail__c Gateway){          
        for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Q_Charge__Gateway_Detail__c').getDescribe().fields.getMap().values()){
            if(field.getDescribe().isCustom() && Gateway.get(field.getDescribe().getName()) != null && field.getDescribe().getName() != 'Q_Charge__Name__c' 
               && field.getDescribe().isUpdateable() && field.getDescribe().getType() == Schema.DisplayType.STRING && !(field.getDescribe().getName() == 'Q_Charge__Optional_Key_1__c' && Gateway.Q_Charge__Name__c == SIMPLIFYWORD))
                Gateway.put(field.getDescribe().getName(),EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf(String.valueOf(Gateway.get(field.getDescribe().getName()))))));
        }    
    }
    
    /*************Method to decode the keys************************/
    public static Gateway_Detail__c decodeKeys(String GatewayName){
        Gateway_Detail__c gateway = new Gateway_Detail__c();        
        String query = '';
        for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Q_Charge__Gateway_Detail__c').getDescribe().fields.getMap().values()){
            if(field.getDescribe().isCustom() && field.getDescribe().isAccessible())
                query += ', '+field.getDescribe().getName();
        }        
        gateway =  Database.query('Select Id '+query+' From Gateway_Detail__c where Name__c = :GatewayName WITH SECURITY_ENFORCED limit 1');
        
        for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Q_Charge__Gateway_Detail__c').getDescribe().fields.getMap().values()){
            if(field.getDescribe().isCustom() && gateway.get(field.getDescribe().getName()) != null && field.getDescribe().getName() != 'Q_Charge__Name__c'
               && field.getDescribe().isAccessible() && field.getDescribe().getType() == Schema.DisplayType.STRING && !(field.getDescribe().getName() == 'Q_Charge__Optional_Key_1__c' && GatewayName == SIMPLIFYWORD)){
                   gateway.put(field.getDescribe().getName(),Crypto.decryptWithManagedIV('AES128', CryptoKey, EncodingUtil.base64Decode(String.valueOf(gateway.get(field.getDescribe().getName())))).toString());
               } 
        }
        return gateway;
    }

    /*******Method to encode the Customer keys******/
    public static String encodeCustomerKeys(String Customerkey){          
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', CryptoKey, Blob.valueOf(Customerkey)));
    }

    /*******Method to decode the Customer keys******/
    public static String decodeCustomerKeys(String Customerkey){          
        return Crypto.decryptWithManagedIV('AES128', CryptoKey, EncodingUtil.base64Decode(String.valueOf(Customerkey))).toString();
    }

    /*******Generic method to parse XML *************/
    public static String XMLParser(String XMLResponse)
    {
        if(XMLResponse.contains('<!DOCTYPE') || XMLResponse.contains('!ENTITY') || XMLResponse.contains('!ELEMENT')){
            throw new GatewayException('Xml Response from the NAB Transact server is not of a valid XML.');
        }
        String parsedResponse = '';
        XmlStreamReader reader = new XmlStreamReader(XMLResponse);
        while(reader.hasNext())
        {
            if(reader.getEventType()==XmlTag.DTD){
                throw new GatewayException('Xml Response from the NAB Transact server is not of a valid XML.');
            }
            if(reader.getEventType() == XmlTag.CHARACTERS)
            {
                if(reader.hasText())
                {
                    parsedResponse += reader.getText();
                }
            }
            reader.next();
        }
        return parsedResponse;
    }

     /*********************** Method for converting string type date into date type. ********************************/
     public static Date convertStringtoDate(String nextPaymentDate)
     {
         Map <String, Integer> monthNames = new Map <String, Integer> {'Jan'=>01, 'Feb'=>02, 'Mar'=>03, 'Apr'=>04, 'May'=>05, 'Jun'=>06, 'Jul'=>07, 'Aug'=>08, 'Sep'=>09, 'Oct'=>10, 'Nov'=>11, 'Dec'=>12};
         List <String> stringParts = nextPaymentDate.split(' ');
         date paymentstartDate = date.newinstance(Integer.valueOf(stringParts[2]), monthNames.get(stringParts[1]), Integer.valueOf(stringParts[0]));
         return paymentstartDate;
     }
     
     /*********************** Method for converting string type date into date type. ********************************/
     public static Datetime convertStringtoDateTime(String transactionDate)
     {
         Datetime transactionDateTime;
         Map <String, Integer> monthNames = new Map <String, Integer> {'Jan'=>01, 'Feb'=>02, 'Mar'=>03, 'Apr'=>04, 'May'=>05, 'Jun'=>06, 'Jul'=>07, 'Aug'=>08, 'Sep'=>09, 'Oct'=>10, 'Nov'=>11, 'Dec'=>12};
         List <String> stringParts = transactionDate.replace(':',' ').split(' ');
         if(stringParts.size() > 3){
             transactionDateTime = Datetime.newInstanceGMT(Integer.valueOf(stringParts[2]), monthNames.get(stringParts[1]), Integer.valueOf(stringParts[0]), Integer.valueOf(stringParts[3])-11, Integer.valueOf(stringParts[4]),00);
         } else{
             transactionDateTime = Datetime.newInstanceGMT(Integer.valueOf(stringParts[2]), monthNames.get(stringParts[1]), Integer.valueOf(stringParts[0]));
         }
         return transactionDateTime;
     }
    
     /*********************** Method for converting date into string type. ********************************/
     public static String convertDatetoString(Date datetoConvert){
         
         DateTime dT = DateTime.newInstance(datetoConvert.year(), datetoConvert.month(), datetoConvert.day());
         String dateString = dT.format('dd MMM yyyy');
         return dateString;
     }

     /*********************** Method for generating expiry year drop-down on checkout page . ********************************/
     public static List<String> expiryYearGenerator(){
         List<String> expiryYear = new List<String>();
         Integer currentYear = Date.today().Year();
         for(Integer i=0 ; i<15 ; i++){
            expiryYear.add(String.valueOf(currentYear+i));
         }
         return expiryYear;
     }

     /*********************** Method for generating months of year drop-down on checkout page . ********************************/
     public static List<String> monthsGenerator(){
        List<String> months = new List<String>();
        for(Integer i=1 ; i<=12 ; i++){
            if(i < 10){
                months.add(String.valueOf('0'+i));
            }
            else{
                months.add(String.valueOf(i));
            }
        }
        return months;
    }
    
}