import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkout from '@salesforce/apex/ItemPurchaseController.checkout';

export default class CartModal extends NavigationMixin(LightningElement) {
    @api cartItems = [];
    @api accountId;

    isProcessing = false;

    get hasItems() {
        return this.cartItems && this.cartItems.length > 0;
    }

    get cartTotal() {
        return this.cartItems.reduce(
            (sum, ci) => sum + ci.Price__c * ci.quantity,
            0
        );
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCheckout() {
        if (!this.hasItems) {
            return;
        }

        this.isProcessing = true;

        const cartPayload = this.cartItems.map((ci) => {
            const plainItem = JSON.parse(JSON.stringify(ci));
            return {
                itemId: plainItem.Id,
                quantity: plainItem.quantity
            };
        });

        const cartItemsJson = JSON.stringify(cartPayload);

        checkout({ accountId: this.accountId, cartItemsJson: cartItemsJson })
            .then((purchaseId) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Purchase created successfully',
                        variant: 'success'
                    })
                );

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: purchaseId,
                        objectApiName: 'Purchase__c',
                        actionName: 'view'
                    }
                });
            })
            .catch((error) => {
                const message =
                    error && error.body && error.body.message
                        ? error.body.message
                        : 'An unknown error occurred';

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Checkout Failed',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }
}