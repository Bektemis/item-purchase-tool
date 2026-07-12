public with sharing class ItemPurchaseController {

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [
            SELECT Id, Name, AccountNumber, Industry
            FROM Account
            WHERE Id = :accountId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(String searchTerm, String typeFilter, String familyFilter) {
        String search = '%' + String.escapeSingleQuotes(searchTerm) + '%';

        String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, Available_Quantity__c ' +
                        'FROM Item__c ' +
                        'WHERE Name LIKE :search';

        if (String.isNotBlank(typeFilter)) {
            query += ' AND Type__c = :typeFilter';
        }
        if (String.isNotBlank(familyFilter)) {
            query += ' AND Family__c = :familyFilter';
        }

        query += ' ORDER BY Name ASC';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getIsCurrentUserManager() {
        User currentUser = [
            SELECT Id, Is_Manager__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        return currentUser.Is_Manager__c;
    }

    @AuraEnabled
    public static Id checkout(Id accountId, List<CartItem> cartItems) {

        if (cartItems == null || cartItems.isEmpty()) {
            throw new AuraHandledException('Корзина пуста.');
        }

        Set<Id> itemIds = new Set<Id>();
        for (CartItem ci : cartItems) {
            itemIds.add(ci.itemId);
        }

        Map<Id, Item__c> itemsMap = new Map<Id, Item__c>([
            SELECT Id, Name, Price__c, Available_Quantity__c
            FROM Item__c
            WHERE Id IN :itemIds
        ]);

        List<String> errors = new List<String>();
        for (CartItem ci : cartItems) {
            Item__c item = itemsMap.get(ci.itemId);

            if (item == null) {
                errors.add('Товар не найден: ' + ci.itemId);
                continue;
            }

            if (ci.quantity == null || ci.quantity <= 0) {
                errors.add('Некорректное количество для товара: ' + item.Name);
                continue;
            }

            if (item.Available_Quantity__c == null || item.Available_Quantity__c < ci.quantity) {
                errors.add('Недостаточно товара на складе: ' + item.Name +
                            ' (доступно: ' + item.Available_Quantity__c + ', запрошено: ' + ci.quantity + ')');
            }
        }

        if (!errors.isEmpty()) {
            throw new AuraHandledException(String.join(errors, '; '));
        }

        Purchase__c purchase = new Purchase__c(
            Account__c = accountId
        );
        insert purchase;

        List<Purchase_Line__c> linesToInsert = new List<Purchase_Line__c>();
        List<Item__c> itemsToUpdate = new List<Item__c>();

        Decimal totalItemsCount = 0;
        Decimal grandTotal = 0;

        for (CartItem ci : cartItems) {
            Item__c item = itemsMap.get(ci.itemId);

            Purchase_Line__c line = new Purchase_Line__c(
                Purchase_Id__c = purchase.Id,
                Item_Id__c = item.Id,
                Amount__c = ci.quantity,
                Unit_Cost__c = item.Price__c
            );
            linesToInsert.add(line);

            totalItemsCount += ci.quantity;
            grandTotal += (item.Price__c * ci.quantity);

            Item__c itemToUpdate = new Item__c(
                Id = item.Id,
                Available_Quantity__c = item.Available_Quantity__c - ci.quantity
            );
            itemsToUpdate.add(itemToUpdate);
        }

        insert linesToInsert;

        update itemsToUpdate;

        return purchase.Id;
    }

    public class CartItem {
        @AuraEnabled public Id itemId;
        @AuraEnabled public Integer quantity;
    }
}