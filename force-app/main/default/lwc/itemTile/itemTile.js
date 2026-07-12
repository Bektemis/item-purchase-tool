import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ItemTile extends LightningElement {
    @api item;
    isDetailModalOpen = false;

    get isOutOfStock() {
        return !this.item || this.item.Available_Quantity__c <= 0;
    }

    get addButtonLabel() {
        return this.isOutOfStock ? 'Out of Stock' : 'Add';
    }

    openDetails() {
        this.isDetailModalOpen = true;
    }

    closeDetails() {
        this.isDetailModalOpen = false;
    }

    handleAdd() {
        this.dispatchEvent(new CustomEvent('add', { detail: this.item }));

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Added to Cart',
                message: this.item.Name + ' was added to your cart',
                variant: 'success'
            })
        );
    }
}