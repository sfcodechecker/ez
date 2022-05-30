public with sharing class EmailHandler {
    
    Static String SubjectHeader = 'EzyCharge: ';
    Static String PackageName = 'EzyCharge';
    Static String SupportEmail = 'support@atlascons.com.au';
    
    //Email to any email address with comma seperated or single email.
    public static void sendEmailTo(String emailSubject, String emailBody, String emailAddress, Boolean IncludeLoggedUser)
    {    
        emailAddress = (emailAddress == null ? SupportEmail : emailAddress);
        emailAddress = (IncludeLoggedUser != null && IncludeLoggedUser ? emailAddress+','+UserInfo.getUserEmail() : emailAddress);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emailAddress.split(',');
        message.setSubject(SubjectHeader+''+emailSubject);
        message.plainTextBody = emailBody +'\n\nFrom Organisation: \nOrganisation: '+UserInfo.getOrganizationName()+' ('+UserInfo.getOrganizationId()
            +')\nUser: '+UserInfo.getName()+' ('+UserInfo.getUserId()+')\nPackage Name: '+PackageName;//+System.requestVersion()+')';
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
    }
    
    //Email to any support address with exception occurred.
    public static void sendExceptionEmail(String ClassName, Exception ex, Boolean IncludeLoggedUser)
    {    
        String emailAddress = SupportEmail;
        emailAddress = (IncludeLoggedUser != null && IncludeLoggedUser ? emailAddress+','+UserInfo.getUserEmail() : emailAddress);
        String emailBody = 'Exception from: '+ClassName; 
        emailBody += '\n\nErrors: \nError Line Number: '+ex.getLineNumber();
        emailBody += '\nError Message: '+ex.getMessage()+' ('+ex.getTypeName()+')';
        emailBody += '\nError Date: '+System.Now();
        emailBody += '\nStack Trace: '+ex.getStackTraceString();

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emailAddress.split(',');
        message.setSubject(SubjectHeader+'Exception');
        message.plainTextBody = emailBody +'\n\nFrom Organisation: \nOrganisation: '+UserInfo.getOrganizationName()+' ('+UserInfo.getOrganizationId()
            +')\nUser: '+UserInfo.getName()+' ('+UserInfo.getUserId()+')\nPackage Name: '+PackageName;//+System.requestVersion()+')';
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
    }
    
    //send daily report mail to admins of the org
    public static void sendReportEmail(String emailSubject, String emailBody, String emailAddress, Boolean IncludeLoggedUser, List<Messaging.Emailfileattachment> reportAttachment)
    {
        //emailAddress = (emailAddress == null ? SupportEmail : emailAddress);
        //emailAddress = (IncludeLoggedUser != null && IncludeLoggedUser ? emailAddress+','+UserInfo.getUserEmail() : emailAddress);
        emailAddress = UserInfo.getUserEmail();
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emailAddress.split(',');
        message.setSubject(SubjectHeader+''+emailSubject);
        message.plainTextBody = emailBody +'\n\nFrom Organisation: \nOrganisation: '+UserInfo.getOrganizationName()+' ('+UserInfo.getOrganizationId()
            +')\nUser: '+UserInfo.getName()+' ('+UserInfo.getUserId()+')\nPackage Name: '+PackageName;//'('+System.requestVersion()+')';
        //message.setFileAttachments (new Messaging.EmailFileAttachment []{reportAttachment});
        message.setFileAttachments(reportAttachment);
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
    }

    // Send DML and Permission Exception Email to admins.
    public static void sendExceptionEmailtoAdmin(String ClassName, Exception ex, Boolean IncludeLoggedUser)
    { 
        String emailAddress ='';
        ID sysAdmProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' WITH SECURITY_ENFORCED].Id;
        List<User> sysAdm = [SELECT id, Email FROM User WHERE ProfileId = :sysAdmProfile WITH SECURITY_ENFORCED];
        for(Integer i = 0; i < sysAdm.size(); i++){
            emailAddress += sysAdm[i].Email;
            if(sysAdm.size() - 1 > i){
                emailAddress += ',';
            }
        }   
        emailAddress = (IncludeLoggedUser != null && IncludeLoggedUser ? emailAddress+','+UserInfo.getUserEmail() : emailAddress);
        String emailBody = 'Exception from: '+ClassName; 
        emailBody += '\n\nErrors: \nError Line Number: '+ex.getLineNumber();
        emailBody += '\nError Message: '+ex.getMessage()+' ('+ex.getTypeName()+')';
        emailBody += '\nError Date: '+System.Now();
        emailBody += '\nStack Trace: '+ex.getStackTraceString();

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emailAddress.split(',');
        message.setSubject(SubjectHeader+'Exception');
        message.plainTextBody = emailBody +'\n\nFrom Organisation: \nOrganisation: '+UserInfo.getOrganizationName()+' ('+UserInfo.getOrganizationId()
            +')\nUser: '+UserInfo.getName()+' ('+UserInfo.getUserId()+')\nPackage Name: '+PackageName;
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
    }
}