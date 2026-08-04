public with sharing class ContactUtility {
  @AuraEnabled(cacheable=true)
  public static List<Contact> getContacts() {
    return [
      SELECT Id, FirstName, LastName, Email
      FROM Contact
      WITH USER_MODE
      ORDER BY LastName
      LIMIT 10
    ];
  }

  @AuraEnabled
  public static Contact createContact(
    String firstName,
    String lastName,
    String email
  ) {
    Contact con = new Contact(
      FirstName = firstName,
      LastName = lastName,
      Email = email
    );

    insert as user con;
    return con;
  }
}
