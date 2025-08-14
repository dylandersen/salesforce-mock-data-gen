@isTest
public class KnowledgeArticleGeneratorTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data if needed for Knowledge Articles
        // This might include setting up data categories or record types
    }
    
    @isTest
    static void testCreateArticlesFromJson_Success() {
        // Test successful knowledge article creation
        
        String validJson = '[' +
            '{' +
                '"title": "How to Reset Password",' +
                '"summary": "Step-by-step guide for password reset",' +
                '"question": "How do I reset my password?",' +
                '"answer": "To reset your password, follow these steps: 1. Click forgot password...",' +
                '"urlName": "how-to-reset-password",' +
                '"language": "en_US",' +
                '"articleType": "How_To",' +
                '"dataCategory": "User_Guide",' +
                '"dataCategoryGroup": "Support"' +
            '},' +
            '{' +
                '"title": "Troubleshooting Login Issues",' +
                '"summary": "Common login problems and solutions",' +
                '"question": "Why can\'t I log in?",' +
                '"answer": "Common login issues include: 1. Incorrect username/password...",' +
                '"urlName": "troubleshooting-login-issues",' +
                '"language": "en_US",' +
                '"articleType": "Troubleshooting",' +
                '"dataCategory": "Technical_Support",' +
                '"dataCategoryGroup": "Support"' +
            '}' +
        ']';
        
        KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest request = 
            new KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest();
        request.topicArea = 'Software Support';
        request.articleJsonData = validJson;
        request.expectedArticleCount = 2;
        request.industry = 'Technology';
        
        Test.startTest();
        List<KnowledgeArticleGenerator.KnowledgeArticleGenerationResult> results = 
            KnowledgeArticleGenerator.createArticlesFromJson(new List<KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        KnowledgeArticleGenerator.KnowledgeArticleGenerationResult result = results[0];
        
        System.assertEquals(true, result.success, 'Expected successful creation');
        System.assertEquals(2, result.articlesCreated, 'Expected 2 articles created');
        System.assert(result.message.contains('Successfully created 2 knowledge articles'), 'Expected success message');
        System.assert(String.isNotBlank(result.articleIdList), 'Expected article IDs');
        
        // Verify articles were actually created
        List<Knowledge__kav> createdArticles = [SELECT Id, Title, Summary FROM Knowledge__kav];
        System.assertEquals(2, createdArticles.size(), 'Expected 2 articles in database');
        
        // Verify article content
        Knowledge__kav article1 = createdArticles[0];
        System.assertEquals('How to Reset Password', article1.Title, 'Expected correct title');
        System.assertEquals('Step-by-step guide for password reset', article1.Summary, 'Expected correct summary');
    }
    
    @isTest
    static void testCreateArticlesFromJson_BlankTopicArea() {
        // Test with blank topic area
        
        KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest request = 
            new KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest();
        request.topicArea = '';
        request.articleJsonData = '[]';
        
        Test.startTest();
        List<KnowledgeArticleGenerator.KnowledgeArticleGenerationResult> results = 
            KnowledgeArticleGenerator.createArticlesFromJson(new List<KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        KnowledgeArticleGenerator.KnowledgeArticleGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals('Topic Area is required', result.message, 'Expected error message');
        System.assertEquals(0, result.articlesCreated, 'Expected no articles created');
    }
    
    @isTest
    static void testCreateArticlesFromJson_BlankJsonData() {
        // Test with blank JSON data
        
        KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest request = 
            new KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest();
        request.topicArea = 'Software Support';
        request.articleJsonData = '';
        
        Test.startTest();
        List<KnowledgeArticleGenerator.KnowledgeArticleGenerationResult> results = 
            KnowledgeArticleGenerator.createArticlesFromJson(new List<KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        KnowledgeArticleGenerator.KnowledgeArticleGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals('Knowledge Article JSON data is required', result.message, 'Expected error message');
        System.assertEquals(0, result.articlesCreated, 'Expected no articles created');
    }
    
    @isTest
    static void testCreateArticlesFromJson_InvalidJson() {
        // Test with invalid JSON format
        
        String invalidJson = 'invalid json format';
        
        KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest request = 
            new KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest();
        request.topicArea = 'Software Support';
        request.articleJsonData = invalidJson;
        
        Test.startTest();
        List<KnowledgeArticleGenerator.KnowledgeArticleGenerationResult> results = 
            KnowledgeArticleGenerator.createArticlesFromJson(new List<KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        KnowledgeArticleGenerator.KnowledgeArticleGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assert(result.message.contains('Invalid JSON format'), 'Expected JSON error message');
        System.assertEquals(0, result.articlesCreated, 'Expected no articles created');
    }
    
    @isTest
    static void testCreateArticlesFromJson_WrongArticleCount() {
        // Test with wrong expected article count
        
        String validJson = '[' +
            '{' +
                '"title": "How to Reset Password",' +
                '"summary": "Step-by-step guide for password reset",' +
                '"question": "How do I reset my password?",' +
                '"answer": "To reset your password, follow these steps...",' +
                '"urlName": "how-to-reset-password",' +
                '"language": "en_US",' +
                '"articleType": "How_To"' +
            '}' +
        ']';
        
        KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest request = 
            new KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest();
        request.topicArea = 'Software Support';
        request.articleJsonData = validJson;
        request.expectedArticleCount = 3; // Expecting 3 but JSON has 1
        
        Test.startTest();
        List<KnowledgeArticleGenerator.KnowledgeArticleGenerationResult> results = 
            KnowledgeArticleGenerator.createArticlesFromJson(new List<KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        KnowledgeArticleGenerator.KnowledgeArticleGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assert(result.message.contains('Expected 3 articles but received 1'), 'Expected count mismatch message');
        System.assertEquals(0, result.articlesCreated, 'Expected no articles created');
    }
    
    @isTest
    static void testCreateArticlesFromJson_EmptyJsonArray() {
        // Test with empty JSON array
        
        String emptyJson = '[]';
        
        KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest request = 
            new KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest();
        request.topicArea = 'Software Support';
        request.articleJsonData = emptyJson;
        
        Test.startTest();
        List<KnowledgeArticleGenerator.KnowledgeArticleGenerationResult> results = 
            KnowledgeArticleGenerator.createArticlesFromJson(new List<KnowledgeArticleGenerator.KnowledgeArticleGenerationRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result');
        KnowledgeArticleGenerator.KnowledgeArticleGenerationResult result = results[0];
        
        System.assertEquals(false, result.success, 'Expected failure');
        System.assertEquals('No valid knowledge article data found in JSON', result.message, 'Expected no data message');
        System.assertEquals(0, result.articlesCreated, 'Expected no articles created');
    }
}
