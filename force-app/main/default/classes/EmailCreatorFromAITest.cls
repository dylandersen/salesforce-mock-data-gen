/**
 * Test class for EmailCreatorFromAI
 */
@isTest
public class EmailCreatorFromAITest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCity = 'San Francisco',
            BillingCountry = 'United States',
            BillingState = 'California'
        );
        insert testAccount;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(3),
            AccountId = testAccount.Id
        );
        insert testOpp;
    }
    
    @isTest
    static void testCreateEmailsFromAI_Success() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with valid JSON
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Test Email","textBody":"This is a test email body.","fromAddress":"test@example.com","fromName":"Test User","toAddress":"recipient@example.com","messageDate":"2025-01-15T10:30:00Z","incoming":false,"isInternal":false,"threadIdentifier":"test-thread-123","externalContact":{"firstName":"Test","lastName":"User","email":"test@example.com","title":"Manager","company":"Test Company"}}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertEquals(1, result.createdCount, 'Should create 1 email');
        System.assertEquals(1, result.emailIds.size(), 'Should return 1 email ID');
        
        // Verify EmailMessage was created
        List<EmailMessage> createdEmails = [SELECT Subject, TextBody, FromAddress, FromName, ToAddress, RelatedToId FROM EmailMessage WHERE RelatedToId = :testAccount.Id];
        System.assertEquals(1, createdEmails.size(), 'Should create 1 EmailMessage record');
        
        EmailMessage email = createdEmails[0];
        System.assertEquals('Test Email', email.Subject, 'Subject should match');
        System.assertEquals('This is a test email body.', email.TextBody, 'Body should match');
        System.assertEquals('test@example.com', email.FromAddress, 'From address should match');
        System.assertEquals('Test User', email.FromName, 'From name should match');
        System.assertEquals('recipient@example.com', email.ToAddress, 'To address should match');
        System.assertEquals(testAccount.Id, email.RelatedToId, 'Should be related to test account');
    }
    
    @isTest
    static void testCreateEmailsFromAI_MultipleEmails() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with multiple emails
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Email 1","textBody":"First email","fromAddress":"user1@example.com","fromName":"User One","toAddress":"recipient@example.com","messageDate":"2025-01-15T10:30:00Z","incoming":false,"isInternal":false,"threadIdentifier":"thread-1","externalContact":{"firstName":"User","lastName":"One","email":"user1@example.com","title":"Director","company":"Company One"}},{"subject":"Email 2","textBody":"Second email","fromAddress":"user2@example.com","fromName":"User Two","toAddress":"recipient@example.com","messageDate":"2025-01-16T10:30:00Z","incoming":true,"isInternal":false,"threadIdentifier":"thread-1","externalContact":{"firstName":"User","lastName":"Two","email":"user2@example.com","title":"Manager","company":"Company Two"}}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertEquals(2, result.createdCount, 'Should create 2 emails');
        System.assertEquals(2, result.emailIds.size(), 'Should return 2 email IDs');
        
        // Verify EmailMessages were created
        List<EmailMessage> createdEmails = [SELECT Subject FROM EmailMessage WHERE RelatedToId = :testAccount.Id ORDER BY Subject];
        System.assertEquals(2, createdEmails.size(), 'Should create 2 EmailMessage records');
        System.assertEquals('Email 1', createdEmails[0].Subject, 'First email subject should match');
        System.assertEquals('Email 2', createdEmails[1].Subject, 'Second email subject should match');
    }
    
    @isTest
    static void testCreateEmailsFromAI_OpportunityRecord() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create test request for opportunity
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testOpp.Id;
        request.recordType = 'Opportunity';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Opportunity Email","textBody":"Email related to opportunity","fromAddress":"sales@example.com","fromName":"Sales Rep","toAddress":"prospect@example.com","messageDate":"2025-01-15T10:30:00Z","incoming":false,"isInternal":false,"threadIdentifier":"opp-thread","externalContact":{"firstName":"Sales","lastName":"Rep","email":"sales@example.com","title":"Sales Representative","company":"Sales Company"}}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertEquals(1, result.createdCount, 'Should create 1 email');
        
        // Verify EmailMessage was created and linked to opportunity
        List<EmailMessage> createdEmails = [SELECT RelatedToId FROM EmailMessage WHERE RelatedToId = :testOpp.Id];
        System.assertEquals(1, createdEmails.size(), 'Should create 1 EmailMessage record');
        System.assertEquals(testOpp.Id, createdEmails[0].RelatedToId, 'Should be related to test opportunity');
    }
    
    @isTest
    static void testCreateEmailsFromAI_EmptyJSON() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with empty emails array
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(false, result.success, 'Should fail with empty emails');
        System.assertEquals('No email data found in AI response', result.message, 'Should return appropriate error message');
        System.assertEquals(0, result.createdCount, 'Should create 0 emails');
    }
    
    @isTest
    static void testCreateEmailsFromAI_InvalidJSON() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with invalid JSON
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = 'invalid json string';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(false, result.success, 'Should fail with invalid JSON');
        System.assertEquals(0, result.createdCount, 'Should create 0 emails');
        System.assert(result.message.contains('Error creating emails'), 'Should return error message');
    }
    
    @isTest
    static void testCreateEmailsFromAI_InvalidDateFormat() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with invalid date format
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Test Email","textBody":"Test body","fromAddress":"test@example.com","fromName":"Test User","toAddress":"recipient@example.com","messageDate":"invalid-date","incoming":false,"isInternal":false,"threadIdentifier":"test-thread","externalContact":{"firstName":"Test","lastName":"User","email":"test@example.com","title":"Manager","company":"Test Company"}}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results - should still succeed but use current time for date
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should succeed despite invalid date');
        System.assertEquals(1, result.createdCount, 'Should create 1 email');
        
        // Verify EmailMessage was created with current date
        List<EmailMessage> createdEmails = [SELECT MessageDate FROM EmailMessage WHERE RelatedToId = :testAccount.Id];
        System.assertEquals(1, createdEmails.size(), 'Should create 1 EmailMessage record');
        System.assertNotEquals(null, createdEmails[0].MessageDate, 'Should have a valid message date');
    }
    
    @isTest
    static void testCreateEmailsFromAI_MissingDateField() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with missing date field
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Test Email","textBody":"Test body","fromAddress":"test@example.com","fromName":"Test User","toAddress":"recipient@example.com","incoming":false,"isInternal":false,"threadIdentifier":"test-thread","externalContact":{"firstName":"Test","lastName":"User","email":"test@example.com","title":"Manager","company":"Test Company"}}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results - should succeed and use current time
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should succeed despite missing date');
        System.assertEquals(1, result.createdCount, 'Should create 1 email');
        
        // Verify EmailMessage was created with current date
        List<EmailMessage> createdEmails = [SELECT MessageDate FROM EmailMessage WHERE RelatedToId = :testAccount.Id];
        System.assertEquals(1, createdEmails.size(), 'Should create 1 EmailMessage record');
        System.assertNotEquals(null, createdEmails[0].MessageDate, 'Should have a valid message date');
    }
    
    @isTest
    static void testCreateEmailsFromAI_EmailMessageRelations() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with external email (to running user)
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'test@company.com';
        request.userName = 'Test User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Test Email","textBody":"This is a test email body.","fromAddress":"external@example.com","fromName":"External Contact","toAddress":"test@company.com","messageDate":"2025-01-15T10:30:00Z","incoming":true,"isInternal":false,"threadIdentifier":"test-thread-123"}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertEquals(1, result.createdCount, 'Should create 1 email');
        
        // Verify EmailMessage was created
        List<EmailMessage> createdEmails = [SELECT Id, Subject, FromAddress, FromName, ToAddress, Incoming FROM EmailMessage WHERE RelatedToId = :testAccount.Id];
        System.assertEquals(1, createdEmails.size(), 'Should create 1 EmailMessage record');
        
        // Verify EmailMessage fields are correct
        EmailMessage email = createdEmails[0];
        System.assertEquals('Test Email', email.Subject, 'Subject should match');
        System.assertEquals('external@example.com', email.FromAddress, 'From address should be external contact');
        System.assertEquals('External Contact', email.FromName, 'From name should be external contact');
        System.assertEquals('test@company.com', email.ToAddress, 'To address should be current user');
        System.assertEquals(true, email.Incoming, 'Should be incoming email');
    }
    
    @isTest
    static void testCreateEmailsFromAI_InternalEmail() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test request with internal email (from running user)
        EmailCreatorFromAI.EmailCreationRequest request = new EmailCreatorFromAI.EmailCreationRequest();
        request.recordId = testAccount.Id;
        request.recordType = 'Account';
        request.userEmail = 'internal@company.com';
        request.userName = 'Internal User';
        request.aiGeneratedJson = '{"emails":[{"subject":"Internal Email","textBody":"This is an internal email","fromAddress":"external@example.com","fromName":"External Contact","toAddress":"external@example.com","messageDate":"2025-01-15T10:30:00Z","incoming":false,"isInternal":true,"threadIdentifier":"internal-thread"}]}';
        
        Test.startTest();
        List<EmailCreatorFromAI.EmailCreationResult> results = EmailCreatorFromAI.createEmailsFromAI(new List<EmailCreatorFromAI.EmailCreationRequest>{request});
        Test.stopTest();
        
        // Verify results
        EmailCreatorFromAI.EmailCreationResult result = results[0];
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertEquals(1, result.createdCount, 'Should create 1 email');
        
        // Verify EmailMessage was created with internal user context
        List<EmailMessage> createdEmails = [SELECT Id, FromAddress, FromName, ToAddress, Incoming FROM EmailMessage WHERE RelatedToId = :testAccount.Id];
        System.assertEquals(1, createdEmails.size(), 'Should create 1 EmailMessage record');
        
        EmailMessage email = createdEmails[0];
        System.assertEquals('internal@company.com', email.FromAddress, 'From address should be internal user email');
        System.assertEquals('Internal User', email.FromName, 'From name should be internal user name');
        System.assertEquals('external@example.com', email.ToAddress, 'To address should be external contact');
        System.assertEquals(false, email.Incoming, 'Should be outgoing (not incoming)');
    }
}