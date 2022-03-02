/**
 * @Author : Makovskaya Kristina
 * @Date : 30/11/2021
 * @description : This class contains methods for working with rest api.
 */
@RestResource(UrlMapping='/mack_pckg__Guest__c/*')
global with sharing class RESTGuest {
    public static String CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    /**
     * This method executes a get request and returns a list of users.
     * @return List<mack_pckg__Guest__c>
     */
    @HttpGet
    global static List<mack_pckg__Guest__c> getRecords() {
        RestRequest request = RestContext.request;
        String addParam = '';
        String name = request.params.get('name');
        if (request.params.get('name') != null) {
            addParam = 'WHERE mack_pckg__Contact__r.Name = :name';
        }
        if (request.params.get('notinvited') != null) {
            addParam = 'WHERE mack_pckg__Is_Invited__c = FALSE';
        }
        return Database.query(
            'SELECT Id, Name, mack_pckg__Contact__r.Name, mack_pckg__Is_Invited__c ' +
            'FROM mack_pckg__Guest__c ' +
            addParam
        );
    }
    /**
     * This method executes a put request and inserts new contacts with the passed names
     * and inserts new users if the secretkey parameter is passed correctly.
     * @param names Map<String, String> names) (first name, last name)
     */
    @HttpPut
    global static void createGuest(Map<String, String> names) {
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact LIMIT 10000];
        Map<Id, String> mapContactsById = new Map<Id, String>();
        List<SObject> newGuest = new List<SObject>();
        List<Contact> newContacts = new List<Contact>();
        if (temporaryKeyIsValid()) {
            for (Contact contact : contacts) {
                mapContactsById.put(contact.Id, contact.FirstName + ' ' + contact.LastName);
            }
            for (Id contactId : mapContactsById.keySet()) {
                List<String> firstNameAndLastName = mapContactsById.get(contactId).split(' ');
                if (names.get(firstNameAndLastName.get(0)) == firstNameAndLastName.get(1)) {
                    newContacts.add(new Contact(Id = contactId, FirstName = firstNameAndLastName.get(0), LastName = firstNameAndLastName.get(1)));
                    names.remove(firstNameAndLastName.get(0));
                }
            }
            for (String firstName : names.keySet()) {
                newContacts.add(new Contact(FirstName = firstName, LastName = names.get(firstName)));
            }
            upsert newContacts;
            for (Contact contact : newContacts) {
                newGuest.add(new mack_pckg__Guest__c(mack_pckg__Contact__c = contact.Id));
            }
            insert newGuest;
        }
    }
    /**
     * This method executes a Patch request.
     * If the secret key parameter is passed correctly and the key is valid, then the guest is canceled by invitation.
     * @param name
     */
    @HttpPatch
    global static void cancelInvitation(String name) {
        List<mack_pckg__Guest__c> guests = [
            SELECT Id, Name, mack_pckg__Contact__r.Name, mack_pckg__Contact__c, mack_pckg__Is_Invited__c
            FROM mack_pckg__Guest__c
            WHERE mack_pckg__Contact__r.Name = :name
            LIMIT 10000
        ];
        if (temporaryKeyIsValid()) {
            for (mack_pckg__Guest__c guest : guests) {
                guest.mack_pckg__Is_Invited__c = false;
            }
            update(List<SObject>) guests;
        }
    }
    /**
     * This method executes a Delete request.
     * If the secret key parameter is passed correctly and the key is valid, then the guest is deleted.
     */
    @HttpDelete
    global static void removeGuest() {
        RestRequest request = RestContext.request;
        List<mack_pckg__Guest__c> guests = [
            SELECT Id, mack_pckg__Contact__c, mack_pckg__Is_Invited__c, Name, LastModifiedDate
            FROM mack_pckg__Guest__c
            WHERE Name = :request.params.get('name')
            LIMIT 10000
        ];
        if (temporaryKeyIsValid()) {
            delete (List<SObject>) guests;
        }
    }
    /**
     * This method executes a Post request and accepts a secret word.
     * If the word exists in the table, a new generated key is returned.
     * @param secretWord
     * @return
     */
    @HttpPost
    global static String getTemporaryKey(String secretWord) {
        List<mack_pckg__Secret_words__mdt> secretDatas = [
            SELECT Id, MasterLabel, DeveloperName
            FROM mack_pckg__Secret_words__mdt
        ];
        List<mack_pckg__Temporary_keys__c> temporaryKeys = [
            SELECT Id, Name, mack_pckg__Secret_key__c, mack_pckg__isValid__c, LastModifiedDate
            FROM mack_pckg__Temporary_keys__c
        ];
        List<mack_pckg__Temporary_keys__c> addTemporaryKeys = new List<mack_pckg__Temporary_keys__c>();
        List<mack_pckg__Temporary_keys__c> updateTemporaryKeys = new List<mack_pckg__Temporary_keys__c>();
        Map<String, mack_pckg__Temporary_keys__c> mapTemporaryKeysByIds = new Map<String, mack_pckg__Temporary_keys__c>();
        Boolean isValid = false;
        String generatedData = '';
        for (mack_pckg__Secret_words__mdt secretData : secretDatas) {
            if (secretData.MasterLabel == 'Finn' || secretData.MasterLabel == 'Jake' && secretData.DeveloperName == secretWord) {
                while (generatedData.length() < 15) {
                    Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), CHARS.length());
                    generatedData += CHARS.substring(idx, idx + 1);
                    isValid = true;
                }
            }
        }
        for (mack_pckg__Temporary_keys__c temporaryKey : temporaryKeys) {
            mapTemporaryKeysByIds.put(temporaryKey.Name, temporaryKey);
        }
        if (generatedData != null && isValid == true) {
            for (mack_pckg__Temporary_keys__c temporaryKey : temporaryKeys) {
                if (temporaryKey.Name == UserInfo.getUserName()) {
                    if (System.now() >= temporaryKey.LastModifiedDate.addMinutes(1)) {
                        temporaryKey.mack_pckg__Secret_key__c = generatedData;
                        updateTemporaryKeys.add(temporaryKey);
                    }
                } else {
                    if (mapTemporaryKeysByIds.get(UserInfo.getUserName()) == null) {
                        addTemporaryKeys.add(new mack_pckg__Temporary_keys__c(
                            Name = UserInfo.getUserName(),
                            mack_pckg__Secret_key__c = generatedData
                        ));
                    }
                }
            }
            if (addTemporaryKeys != null) {
                insert (List<SObject>) addTemporaryKeys;
            }
            if (updateTemporaryKeys != null) {
                update (List<SObject>) updateTemporaryKeys;
            }
        }
        return generatedData;
    }
    /**
     * This method executes an sql query to get a temporary key for the current user.
     * @return mack_pckg__Temporary_keys__c
     */
    public static mack_pckg__Temporary_keys__c getTemporaryKey() {
        return [
            SELECT Id, Name, mack_pckg__Secret_key__c, mack_pckg__isValid__c, LastModifiedDate
            FROM mack_pckg__Temporary_keys__c
            WHERE Name = :UserInfo.getUserName()
            LIMIT 1
        ];
    }
    /**
     * This method checks the temporary key for validity.
     * @return Boolean
     */
    public static Boolean temporaryKeyIsValid() {
        RestRequest request = RestContext.request;
        mack_pckg__Temporary_keys__c temporaryKey = getTemporaryKey();
        Boolean isValid = false;
        if (request.params.get('secretkey') == temporaryKey.mack_pckg__Secret_key__c) {
            if (System.now() >= temporaryKey.LastModifiedDate && System.now() <= temporaryKey.LastModifiedDate.addMinutes(1)) {
                isValid = true;
            }
        }
        return isValid;
    }
}