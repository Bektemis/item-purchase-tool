@isTest
private class UnsplashServiceTest {

    private class UnsplashSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results":[{"urls":{"regular":"https://images.unsplash.com/test-photo"}}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class UnsplashEmptyResultsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results":[]}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class UnsplashErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            return res;
        }
    }

    @isTest
    static void testGetImageUrlSuccess() {
        Test.setMock(HttpCalloutMock.class, new UnsplashSuccessMock());

        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('bicycle');
        Test.stopTest();

        System.assertEquals('https://images.unsplash.com/test-photo', imageUrl);
    }

    @isTest
    static void testGetImageUrlEmptyResults() {
        Test.setMock(HttpCalloutMock.class, new UnsplashEmptyResultsMock());

        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('nonexistentitem12345');
        Test.stopTest();

        System.assertEquals(null, imageUrl);
    }

    @isTest
    static void testGetImageUrlApiError() {
        Test.setMock(HttpCalloutMock.class, new UnsplashErrorMock());

        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('bicycle');
        Test.stopTest();

        System.assertEquals(null, imageUrl);
    }

    @isTest
    static void testGetImageUrlBlankQuery() {
        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('');
        Test.stopTest();

        System.assertEquals(null, imageUrl);
    }
}