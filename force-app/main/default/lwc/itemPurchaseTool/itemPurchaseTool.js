import { LightningElement, api, wire } from 'lwc';
import getAccountDetails from '@salesforce/apex/ItemPurchaseController.getAccountDetails';
import getIsCurrentUserManager from '@salesforce/apex/ItemPurchaseController.getIsCurrentUserManager';

export default class ItemPurchaseTool extends LightningElement {
    @api recordId;

    account;
    isManager = false;
    cartItems = [];

    isCartOpen = false;
    isCreateItemOpen = false;

    @wire(getAccountDetails, { accountId: '$recordId' })
    wiredAccount({ data, error }) {
        if (data) {
            this.account = data;
        } else if (error) {
            console.error('Error loading account', error);
        }
    }

    connectedCallback() {
        getIsCurrentUserManager()
            .then((result) => {
                this.isManager = result;
            })
            .catch((error) => {
                console.error('Error checking manager status', error);
            });
    }

    get cartCount() {
        return this.cartItems.reduce((sum, ci) => sum + ci.quantity, 0);
    }

    handleAddToCart(event) {
        const item = event.detail;
        const existing = this.cartItems.find((ci) => ci.Id === item.Id);

        if (existing) {
            this.cartItems = this.cartItems.map((ci) =>
                ci.Id === item.Id ? { ...ci, quantity: ci.quantity + 1 } : ci
            );
        } else {
            this.cartItems = [...this.cartItems, { ...item, quantity: 1 }];
        }
    }

    openCart() {
        this.isCartOpen = true;
    }

    closeCart() {
        this.isCartOpen = false;
    }

    openCreateItem() {
        this.isCreateItemOpen = true;
    }

    closeCreateItem() {
        this.isCreateItemOpen = false;
    }

    handleItemCreated() {
        this.isCreateItemOpen = false;
        this.template.querySelector('c-item-filter-panel')?.refreshItems();
    }
}