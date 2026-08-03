import { LightningElement, track } from "lwc";

export default class EmployeeParent extends LightningElement {
  employee = {
    name: "Rahul",
    department: "Salesforce",
    dir: {
      name: "Sourabh"
    }
  };
  @track empName = "Sourabh";

  handleNameChange(event) {
    console.log(this.employee);
    this.empName = event.target.value;
    if (this.empName === "Pratistha") {
      this.employee.dir.name = "ITT";
    }

    console.log(this.employee);
  }

  handleCallChild() {
    // Find child component
    const child = this.template.querySelector("c-employee-child");

    // Call child's public @api method
    child.showMessage();
  }
}
