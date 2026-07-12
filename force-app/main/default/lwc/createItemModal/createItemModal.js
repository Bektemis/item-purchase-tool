import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateItemModal extends LightningElement {
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Item created successfully',
                variant: 'success'
            })
        );

        this.dispatchEvent(new CustomEvent('created'));
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