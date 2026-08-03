import { LightningElement, api } from "lwc";

export default class EmployeeChild extends LightningElement {
  // Public property
  @api employeeName;
  @api employeeDept;

  message = "";

  // Public method
  @api
  showMessage() {
    this.message = "Hello " + this.employeeName + "!";
  }
}
