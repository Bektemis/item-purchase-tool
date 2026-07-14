public with sharing class UnsplashService {

    private static final String ACCESS_KEY = 'sumfizUR_nNrSck6g3yd7ogaglTWMM3b_Mn_sWvfvFo';

    @AuraEnabled
    public static String getImageUrl(String query) {
        if (String.isBlank(query)) {
            return null;
        }

        HttpRequest req = new HttpRequest();
        String endpoint = 'https://api.unsplash.com/search/photos?query='
                            + EncodingUtil.urlEncode(query, 'UTF-8')
                            + '&per_page=1';

        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Client-ID ' + ACCESS_KEY);

        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug('Unsplash callout failed: ' + e.getMessage());
            return null;
        }

        if (res.getStatusCode() != 200) {
            System.debug('Unsplash API returned status: ' + res.getStatusCode());
            return null;
        }

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> results = (List<Object>) result.get('results');

        if (results == null || results.isEmpty()) {
            return null;
        }

        Map<String, Object> firstPhoto = (Map<String, Object>) results[0];
        Map<String, Object> urls = (Map<String, Object>) firstPhoto.get('urls');

        return (String) urls.get('regular');
    }
}