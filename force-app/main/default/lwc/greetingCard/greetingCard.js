import { LightningElement, api } from "lwc";

export default class GreetingCard extends LightningElement {
  @api name = "";
  @api uppercase = false;

  get message() {
    const base = this.name ? `Hello, ${this.name}!` : "Hello, World!";
    return this.uppercase ? base.toUpperCase() : base;
  }
}
