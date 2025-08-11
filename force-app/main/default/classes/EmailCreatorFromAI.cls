/**
 * Clean Apex class that takes AI-generated JSON and creates EmailMessage records
 * Handles user context for proper internal/external email linking
 */
public with sharing class EmailCreatorFromAI {
    
    @InvocableMethod(label='Create Emails from AI JSON' description='Creates EmailMessage records from AI-generated JSON with proper user context')
    public static List<EmailCreationResult> createEmailsFromAI(List<EmailCreationRequest> requests) {
        List<EmailCreationResult> results = new List<EmailCreationResult>();
        
        for (EmailCreationRequest request : requests) {
            EmailCreationResult result = new EmailCreationResult();
            
            try {
                // Parse the AI JSON
                EmailDataWrapper emailData = (EmailDataWrapper) JSON.deserialize(request.aiGeneratedJson, EmailDataWrapper.class);
                System.debug('Parsed email data: ' + emailData);
                System.debug('Number of emails: ' + (emailData != null && emailData.emails != null ? String.valueOf(emailData.emails.size()) : 'null'));
                
                if (emailData == null || emailData.emails == null || emailData.emails.isEmpty()) {
                    result.success = false;
                    result.message = 'No email data found in AI response';
                    result.createdCount = 0;
                    results.add(result);
                    continue;
                }
                
                // Create EmailMessage records
                List<EmailMessage> emailsToCreate = new List<EmailMessage>();
                
                for (EmailData email : emailData.emails) {
                    System.debug('Processing email: ' + email);
                    EmailMessage emailRecord = new EmailMessage();
                    
                    // Set required fields
                    emailRecord.Subject = email.subject;
                    emailRecord.TextBody = email.textBody;
                    emailRecord.ThreadIdentifier = email.threadIdentifier;
                    emailRecord.Status = '3'; // Sent status
                    
                    // Handle internal vs. external emails based on user context
                    if (email.isInternal == true) {
                        // Internal email (from running user's organization)
                        emailRecord.FromAddress = request.userEmail;
                        emailRecord.FromName = request.userName;
                        emailRecord.ToAddress = email.toAddress;
                        emailRecord.Incoming = false; // Outgoing from our organization
                        
                    } else {
                        // External email (from external contact)
                        emailRecord.FromAddress = email.fromAddress;
                        emailRecord.FromName = email.fromName;
                        emailRecord.ToAddress = email.toAddress; // Use the original toAddress
                        emailRecord.Incoming = true; // Incoming to our organization
                    }
                    
                    // Parse and set message date
                    if (String.isNotBlank(email.messageDate)) {
                        try {
                            emailRecord.MessageDate = DateTime.valueOf(email.messageDate.replace('T', ' ').replace('Z', ''));
                        } catch (Exception e) {
                            // Default to now if date parsing fails
                            emailRecord.MessageDate = DateTime.now();
                        }
                    } else {
                        emailRecord.MessageDate = DateTime.now();
                    }
                    
                    // Link to the record (Account or Opportunity)
                    if (request.recordType == 'Account') {
                        emailRecord.RelatedToId = request.recordId;
                    } else if (request.recordType == 'Opportunity') {
                        emailRecord.RelatedToId = request.recordId;
                    }
                    
                    emailsToCreate.add(emailRecord);
                    System.debug('Created EmailMessage record: ' + emailRecord);
                }
                
                // Insert all emails
                if (!emailsToCreate.isEmpty()) {
                    try {
                        System.debug('About to insert ' + emailsToCreate.size() + ' EmailMessage records');
                        insert emailsToCreate;
                        System.debug('Successfully inserted EmailMessage records');
                    } catch (Exception e) {
                        System.debug('Error inserting EmailMessage records: ' + e.getMessage());
                        System.debug('Stack trace: ' + e.getStackTraceString());
                        throw e;
                    }
                    
                    result.success = true;
                    result.message = 'Successfully created ' + emailsToCreate.size() + ' email records';
                    result.createdCount = emailsToCreate.size();
                    result.emailIds = new List<String>();
                    for (EmailMessage em : emailsToCreate) {
                        result.emailIds.add(em.Id);
                    }
                } else {
                    result.success = false;
                    result.message = 'No valid emails to create';
                    result.createdCount = 0;
                }
                
            } catch (Exception e) {
                result.success = false;
                result.message = 'Error creating emails: ' + e.getMessage();
                result.createdCount = 0;
                System.debug('EmailCreatorFromAI Error: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Input wrapper class
    public class EmailCreationRequest {
        @InvocableVariable(required=true)
        public String aiGeneratedJson;
        
        @InvocableVariable(required=true)
        public String recordId;
        
        @InvocableVariable(required=true)
        public String recordType;
        
        @InvocableVariable(required=true)
        public String userEmail;
        
        @InvocableVariable(required=true)
        public String userName;
    }
    
    // Output wrapper class
    public class EmailCreationResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public Integer createdCount;
        
        @InvocableVariable
        public List<String> emailIds;
    }
    
    // JSON structure classes
    public class EmailDataWrapper {
        public List<EmailData> emails;
    }
    
    public class EmailData {
        public String subject;
        public String textBody;
        public String fromAddress;
        public String fromName;
        public String toAddress;
        public String messageDate;
        public Boolean incoming;
        public Boolean isInternal;
        public String threadIdentifier;
    }
}