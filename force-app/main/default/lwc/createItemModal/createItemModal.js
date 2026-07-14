import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getImageUrl from '@salesforce/apex/UnsplashService.getImageUrl';
import ID_FIELD from '@salesforce/schema/Item__c.Id';
import IMAGE_FIELD from '@salesforce/schema/Item__c.Image__c';

export default class CreateItemModal extends LightningElement {

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSuccess(event) {
        const newItemId = event.detail.id;
        const itemName = event.detail.fields.Name.value;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Item created successfully',
                variant: 'success'
            })
        );

        this.fetchAndSetImage(newItemId, itemName);
    }

    fetchAndSetImage(itemId, itemName) {
        getImageUrl({ query: itemName })
            .then((imageUrl) => {
                if (imageUrl) {
                    const fields = {};
                    fields[ID_FIELD.fieldApiName] = itemId;
                    fields[IMAGE_FIELD.fieldApiName] = imageUrl;

                    const recordInput = { fields };

                    return updateRecord(recordInput);
                }
                return null;
            })
            .then(() => {
                this.dispatchEvent(new CustomEvent('created'));
            })
            .catch((error) => {
                console.error('Failed to fetch/set image', error);
                this.dispatchEvent(new CustomEvent('created'));
            });
    }

    handleError(event) {
        const message =
            event.detail && event.detail.message
                ? event.detail.message
                : 'An error occurred while saving';

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
}