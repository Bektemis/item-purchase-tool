@isTest
private class ItemPurchaseControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account', Industry = 'Technology');
        insert acc;

        Item__c item1 = new Item__c(
            Name = 'Test Item One',
            Description__c = 'Sample description',
            Type__c = 'Electronics',
            Family__c = 'Home',
            Price__c = 100,
            Available_Quantity__c = 10
        );

        Item__c item2 = new Item__c(
            Name = 'Test Item Two',
            Description__c = 'Another description',
            Type__c = 'Furniture',
            Family__c = 'Office',
            Price__c = 50,
            Available_Quantity__c = 5
        );

        insert new List<Item__c>{ item1, item2 };
    }

    @isTest
    static void testGetAccountDetails() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Account result = ItemPurchaseController.getAccountDetails(acc.Id);
        Test.stopTest();

        System.assertEquals(acc.Id, result.Id);
        System.assertEquals('Test Account', result.Name);
    }

    @isTest
    static void testGetItemsNoFilters() {
        Test.startTest();
        List<Item__c> results = ItemPurchaseController.getItems('', null, null);
        Test.stopTest();

        System.assertEquals(2, results.size());
    }

    @isTest
    static void testGetItemsWithSearchTerm() {
        Test.startTest();
        List<Item__c> results = ItemPurchaseController.getItems('Test Item One', null, null);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Test Item One', results[0].Name);
    }

    @isTest
    static void testGetItemsWithTypeFilter() {
        Test.startTest();
        List<Item__c> results = ItemPurchaseController.getItems('', 'Furniture', null);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Test Item Two', results[0].Name);
    }

    @isTest
    static void testGetItemsWithFamilyFilter() {
        Test.startTest();
        List<Item__c> results = ItemPurchaseController.getItems('', null, 'Home');
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Test Item One', results[0].Name);
    }

    @isTest
    static void testGetIsCurrentUserManager() {
        Test.startTest();
        Boolean isManager = ItemPurchaseController.getIsCurrentUserManager();
        Test.stopTest();

        System.assertNotEquals(null, isManager);
    }

    @isTest
    static void testCheckoutSuccessSingleItem() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id, Available_Quantity__c FROM Item__c WHERE Name = 'Test Item One' LIMIT 1];

        ItemPurchaseController.CartItem cartItem = new ItemPurchaseController.CartItem();
        cartItem.itemId = item.Id;
        cartItem.quantity = 3;

        Test.startTest();
        Id purchaseId = ItemPurchaseController.checkout(acc.Id, new List<ItemPurchaseController.CartItem>{ cartItem });
        Test.stopTest();

        System.assertNotEquals(null, purchaseId);

        Purchase__c purchase = [SELECT Id, Account__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(acc.Id, purchase.Account__c);

        List<Purchase_Line__c> lines = [
            SELECT Id, Purchase_Id__c, Item_Id__c, Amount__c, Unit_Cost__c
            FROM Purchase_Line__c
            WHERE Purchase_Id__c = :purchaseId
        ];
        System.assertEquals(1, lines.size());
        System.assertEquals(3, lines[0].Amount__c);

        Item__c updatedItem = [SELECT Available_Quantity__c FROM Item__c WHERE Id = :item.Id];
        System.assertEquals(7, updatedItem.Available_Quantity__c);
    }

    @isTest
    static void testCheckoutSuccessMultipleItems() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Item__c> items = [SELECT Id, Available_Quantity__c FROM Item__c];

        List<ItemPurchaseController.CartItem> cartItems = new List<ItemPurchaseController.CartItem>();
        for (Item__c item : items) {
            ItemPurchaseController.CartItem ci = new ItemPurchaseController.CartItem();
            ci.itemId = item.Id;
            ci.quantity = 2;
            cartItems.add(ci);
        }

        Test.startTest();
        Id purchaseId = ItemPurchaseController.checkout(acc.Id, cartItems);
        Test.stopTest();

        List<Purchase_Line__c> lines = [
            SELECT Id FROM Purchase_Line__c WHERE Purchase_Id__c = :purchaseId
        ];
        System.assertEquals(2, lines.size());
    }

    @isTest
    static void testCheckoutInsufficientStock() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Test Item One' LIMIT 1];

        ItemPurchaseController.CartItem cartItem = new ItemPurchaseController.CartItem();
        cartItem.itemId = item.Id;
        cartItem.quantity = 999;

        Boolean exceptionThrown = false;
        String errorMessage = '';

        Test.startTest();
        try {
            ItemPurchaseController.checkout(acc.Id, new List<ItemPurchaseController.CartItem>{ cartItem });
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown);
    }

    @isTest
    static void testCheckoutEmptyCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ItemPurchaseController.checkout(acc.Id, new List<ItemPurchaseController.CartItem>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown);
    }

    @isTest
    static void testCheckoutZeroQuantity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Test Item One' LIMIT 1];

        ItemPurchaseController.CartItem cartItem = new ItemPurchaseController.CartItem();
        cartItem.itemId = item.Id;
        cartItem.quantity = 0;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ItemPurchaseController.checkout(acc.Id, new List<ItemPurchaseController.CartItem>{ cartItem });
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown);
    }
}