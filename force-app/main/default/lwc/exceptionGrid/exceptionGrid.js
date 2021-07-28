import { LightningElement, api, wire } from 'lwc';
import showExceptionGrid from '@salesforce/apex/ExceptionGridController.showExceptionGrid';

const columns = [
    { label: 'Field Name', fieldName: 'fieldName', type: 'text' },
    { label: 'Error', fieldName: 'isError', type: 'boolean' },
    { label: 'Exception Message', fieldName: 'exceptionMessage', type: 'text' }
];

export default class ExceptionGrid extends LightningElement {
    @api
    recordId;

    columns = columns;

    @wire(showExceptionGrid, { recordId: '$recordId' })
    gridData;
}