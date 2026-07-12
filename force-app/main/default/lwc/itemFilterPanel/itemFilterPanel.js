import { LightningElement, wire, api } from 'lwc';
import getItems from '@salesforce/apex/ItemPurchaseController.getItems';
import { refreshApex } from '@salesforce/apex';

const TYPE_OPTIONS = [
    { label: 'All Types', value: '' },
    { label: 'Electronics', value: 'Electronics' },
    { label: 'Furniture', value: 'Furniture' },
    { label: 'Clothing', value: 'Clothing' },
    { label: 'Books', value: 'Books' }
];

const FAMILY_OPTIONS = [
    { label: 'All Families', value: '' },
    { label: 'Home', value: 'Home' },
    { label: 'Office', value: 'Office' },
    { label: 'Outdoor', value: 'Outdoor' },
    { label: 'Kids', value: 'Kids' }
];

export default class ItemFilterPanel extends LightningElement {
    searchTerm = '';
    typeFilter = '';
    familyFilter = '';

    items = [];
    wiredItemsResult;

    typeOptions = TYPE_OPTIONS;
    familyOptions = FAMILY_OPTIONS;

    @wire(getItems, {
        searchTerm: '$searchTerm',
        typeFilter: '$typeFilter',
        familyFilter: '$familyFilter'
    })
    wiredItems(result) {
        this.wiredItemsResult = result;
        if (result.data) {
            this.items = result.data;
        } else if (result.error) {
            console.error('Error loading items', result.error);
        }
    }

    get itemCount() {
        return this.items ? this.items.length : 0;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleTypeChange(event) {
        this.typeFilter = event.detail.value;
    }

    handleFamilyChange(event) {
        this.familyFilter = event.detail.value;
    }

    handleCartAdd(event) {
        this.dispatchEvent(new CustomEvent('cartadd', { detail: event.detail }));
    }

    @api
    refreshItems() {
        return refreshApex(this.wiredItemsResult);
    }
}