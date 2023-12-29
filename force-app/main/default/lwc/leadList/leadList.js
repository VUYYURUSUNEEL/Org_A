import { LightningElement, wire, track } from 'lwc';
import getLeads from '@salesforce/apex/LeadRecordsHandler.getLeads';
import syncContact from '@salesforce/apex/LeadRecordsHandler.syncContact';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const columns = [
    // Define columns as per your requirement
    // Example:
    { label: 'Lead Name', fieldName: 'Name', type: 'text' },
    { label: 'Lead Source', fieldName: 'LeadSource', type: 'text' },
    { label: 'Lead ID', fieldName: 'Id', type: 'text' } 
];

export default class LeadList extends LightningElement {
    @track pagedData = [];
    @track selectedSource = '';
    @track searchTerm = '';
    @track pageNumber = 1;
    @track pageSize = 5; // Default page size
    @track recCount;
    @track error;
    _title = "Contact Sync Information";
    message = "";
    variant = "success";
    totalPages;
    spinnerLoad = false;
    allData = [];
    pageSizeOptions = [5, 10, 25, 50];
    columns = columns;
    diabledFirst = false;
    diabledPrev = false;
    diabledLast = false;
    diabledNext = false;

    @wire(getLeads, { searchTerm: '$searchTerm', selectedSource: '$selectedSource' })
    wiredLeads(result) {
        console.log('res--',result);
        if (result.data) {
            this.allData = JSON.parse(JSON.stringify(result.data));
            this.pageNumber = 1;
            this.pageSize = 5;
            this.diabledFirst = true;
            this.diabledPrev = true;
            this.recCount = this.allData.length;
            this.paginationHelper();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.pagedData = undefined;
        }

        //console.log('pagedData--',this.pagedData);
    }

    connectedCallback() {
        
    }

    get leadSources() {
        // Fetch lead sources dynamically or hardcode options
        // Example:
        return [
            { label: 'All', value: '' },
            { label: 'Web', value: 'Web' },
            { label: 'Phone Inquiry', value: 'Phone Inquiry' },
            { label: 'Partner Referral', value: 'Partner Referral' },
            { label: 'Purchased List', value: 'Purchased List' },
        ];
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.pageNumber = 1; // Reset page number when searching
    }

    handleSourceChange(event) {
        this.selectedSource = event.target.value;
        this.pageNumber = 1; // Reset page number when changing filter
        this.pageSize = 5;
    }

    // Pagination Methods:
    handleFirst(){
        this.pageNumber = 1;
        this.diabledNext = false;
        this.diabledLast = false;
        this.diabledFirst = true;
        this.diabledPrev = true;
        this.paginationHelper();
    }
    handlePrevious(){
        console.log('this.pageNumber--',this.pageNumber);
        this.diabledNext = false;
        this.diabledLast = false;
        this.diabledFirst = false;
        this.diabledPrev = false;
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    handleNext(){
        console.log('this.pageNumber--',this.pageNumber);
        this.diabledNext = false;
        this.diabledLast = false;
        this.diabledFirst = false;
        this.diabledPrev = false;
        this.pageNumber = this.pageNumber +1;
        this.paginationHelper();
    }
    handleLast(){
        this.pageNumber = this.totalPages;
        this.diabledNext = true;
        this.diabledLast = true;
        this.diabledFirst = false;
        this.diabledPrev = false;
        this.paginationHelper();
    }

    handleRecordsPerPage(event){
        console.log(event.target.value)
        this.pageSize =  event.target.value;
        this.paginationHelper();
    }
    
    paginationHelper() {
        this.pagedData = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.recCount / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
            this.diabledNext = false;
            this.diabledLast = false;
            this.diabledFirst = true;
            this.diabledPrev = true;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
            this.diabledNext = true;
            this.diabledLast = true;
            this.diabledFirst = false;
            this.diabledPrev = false;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.recCount) {
                break;
            }
            this.pagedData.push(this.allData[i]);
        }
    }

    handleSyncContact(){
        this.spinnerLoad = true;
        syncContact()
        .then(result=>{
            if(result && result.includes('Error')){
                this.message = 'There is some error in background, Please check with your Adminitstartor.';
                this.variant = 'error';    
            }else if(result){
                this.message = result;
                this.variant = 'success';
            }
            
        })
        .catch(error=>{
            console.log(error);
            this.message = error;
            this.variant = 'error';
        })
        .finally(()=>{
            this.spinnerLoad = false;
            this.showNotification();
        })

    }

    showNotification() {
        const evt = new ShowToastEvent({
        title: this._title,
        message: this.message,
        variant: this.variant,
        });
        this.dispatchEvent(evt);
    }
}