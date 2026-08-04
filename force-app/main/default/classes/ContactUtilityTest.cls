@isTest
private class ContactUtilityTest {
  @isTest
  static void createsContact() {
    Test.startTest();
    Contact con = ContactUtility.createContact('Ada', 'Lovelace', 'ada@example.com');
    Test.stopTest();

    System.assertNotEquals(null, con.Id, 'createContact should insert and return the record');
    Contact requeried = [SELECT FirstName, LastName, Email FROM Contact WHERE Id = :con.Id];
    System.assertEquals('Ada', requeried.FirstName, 'first name should match');
    System.assertEquals('Lovelace', requeried.LastName, 'last name should match');
  }

  @isTest
  static void getsContacts() {
    insert new Contact(FirstName = 'Grace', LastName = 'Hopper', Email = 'grace@example.com');

    Test.startTest();
    List<Contact> contacts = ContactUtility.getContacts();
    Test.stopTest();

    System.assertEquals(1, contacts.size(), 'getContacts should return the inserted contact');
    System.assertEquals('Hopper', contacts[0].LastName, 'returned contact should match');
  }
}
