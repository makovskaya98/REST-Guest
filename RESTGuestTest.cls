/**
 * @Author : Makovskaya Kristina
 * @Date : 30/11/2021
 * @description : This test class performs testing of the methods of the class RESTGuest.
 */
@IsTest
public with sharing class RESTGuestTest {

    @TestSetup
    public static void setup() {
        List<mack_pckg__Guest__c> guests = [
            SELECT Id, Name, mack_pckg__Is_Invited__c, mack_pckg__Contact__c
            FROM mack_pckg__Guest__c
        ];
        List<Contact> contactsList = new List<Contact>();
        for (Integer i = 0; i < 6; i++) {
            contactsList.add(new Contact(FirstName = 'Alex', LastName = 'Lorens' + i));
        }
        insert contactsList;
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact];
        for (Integer i = 1; i <= 3; i++) {
            guests.add(new mack_pckg__Guest__c(mack_pckg__Contact__c = contacts[i].Id));
        }
        for (Integer i = 4; i < 6; i++) {
            guests.add(new mack_pckg__Guest__c(mack_pckg__Contact__c = contacts[i].Id, mack_pckg__Is_Invited__c = false));
        }
        insert (List<SObject>) guests;
        List<SObject> temporaryKeyList = new List<SObject>();
        temporaryKeyList.add(new mack_pckg__Temporary_keys__c(Name = 'Alex', mack_pckg__Secret_key__c = 'H54jdhsnd789'));
        insert temporaryKeyList;
    }

    @IsTest public static void getRecords() {
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c/';
        request.httpMethod = 'GET';
        RestContext.request = request;
        List<mack_pckg__Guest__c> guest = RESTGuest.getRecords();
        System.assertEquals(guest.size(), 5);
    }

    @IsTest public static void getRecordByName() {
        System.debug([SELECT Name FROM Contact]);
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c';
        request.httpMethod = 'GET';
        request.addParameter('name', 'Alex Lorens3');
        RestContext.request = request;
        System.debug(RestContext.request);
        List<mack_pckg__Guest__c> guest = RESTGuest.getRecords();
        System.assertEquals(guest.size(), 1);
    }

    @IsTest public static void getRecordByNotInvited() {
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c';
        request.httpMethod = 'GET';
        request.addParameter('notinvited', '');
        RestContext.request = request;
        System.debug(RestContext.request);
        List<mack_pckg__Guest__c> guest = RESTGuest.getRecords();
        System.assertEquals(guest.size(), 2);
    }

    @IsTest public static void createGuest() {
        List<SObject> temporaryKey = new List<SObject>();
        temporaryKey.add(new mack_pckg__Temporary_keys__c(
            Name = UserInfo.getUserName(),
            mack_pckg__Secret_key__c = '5ABN5478lmnrO5'
        ));
        insert temporaryKey;
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c';
        request.httpMethod = 'PUT';
        request.addParameter('secretkey', '5ABN5478lmnrO5');
        RestContext.request = request;
        Map<String, String> names = new Map<String, String>{
            'Anna' => 'Lor', 'Brain' => 'Rovs', 'Lara' => 'Cofuld'
        };
        RESTGuest.createGuest(names);
        List<Contact> contacts = [
            SELECT Id, Name
            FROM Contact
            WHERE Name = 'Anna Lor' OR Name = 'Brain Rovs' OR Name = 'Lara Cofuld'
        ];
        System.assertEquals(contacts.size(), 3);
        List<mack_pckg__Guest__c> guests = [
            SELECT Id, mack_pckg__Contact__c, mack_pckg__Is_Invited__c, Name
            FROM mack_pckg__Guest__c
        ];
        Integer counter = 0;
        for (mack_pckg__Guest__c guest : guests) {
            for (Contact contact : contacts) {
                if (guest.mack_pckg__Contact__c == contact.Id) {
                    counter++;
                }
            }
        }
        System.assertEquals(counter, 3);
    }

    @IsTest public static void cancelInvitation() {
        List<SObject> temporaryKey = new List<SObject>();
        temporaryKey.add(new mack_pckg__Temporary_keys__c(
            Name = UserInfo.getUserName(),
            mack_pckg__Secret_key__c = '5ABN5478lmnrO5'
        ));
        insert temporaryKey;
        String name = 'Alex Lorens2';
        mack_pckg__Guest__c guestBefore = [
            SELECT Id, Name, mack_pckg__Contact__r.Name, mack_pckg__Is_Invited__c
            FROM mack_pckg__Guest__c
            WHERE mack_pckg__Contact__r.Name = :name
            LIMIT 1
        ];
        System.debug(guestBefore);
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c';
        request.httpMethod = 'DELETE';
        request.addParameter('secretkey', '5ABN5478lmnrO5');
        RestContext.request = request;
        System.assertEquals(guestBefore.mack_pckg__Is_Invited__c, true);
        RESTGuest.cancelInvitation(guestBefore.mack_pckg__Contact__r.Name);
        mack_pckg__Guest__c guestAfter = [
            SELECT Id, Name, mack_pckg__Contact__r.Name, mack_pckg__Is_Invited__c
            FROM mack_pckg__Guest__c
            WHERE mack_pckg__Contact__r.Name = :name
            LIMIT 1
        ];
        System.debug(guestAfter);
        System.assertEquals(guestAfter.mack_pckg__Is_Invited__c, false);
    }

    @IsTest public static void removeGuest() {
        List<SObject> temporaryKey = new List<SObject>();
        temporaryKey.add(new mack_pckg__Temporary_keys__c(
            Name = UserInfo.getUserName(),
            mack_pckg__Secret_key__c = '5ABN5478lmnrO5'
        ));
        insert temporaryKey;
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c';
        request.httpMethod = 'DELETE';
        request.addParameter('secretkey', '5ABN5478lmnrO5');
        RestContext.request = request;
        RESTGuest.removeGuest();
        List<mack_pckg__Guest__c> guests = [
            SELECT Id, mack_pckg__Contact__c, mack_pckg__Is_Invited__c, Name
            FROM mack_pckg__Guest__c
            WHERE Name = :UserInfo.getUserName()
        ];
        System.assertEquals(guests.size(), 0);
    }

    @IsTest public static void getTemporaryKey() {
        mack_pckg__Secret_words__mdt secretDatas = [
            SELECT Id, MasterLabel, DeveloperName
            FROM mack_pckg__Secret_words__mdt
            WHERE MasterLabel = 'Finn'
            LIMIT 1
        ];
        RestRequest request = new RestRequest();
        request.requestURI =
            'https://yandexby5-dev-ed.lightning.force.com/services/apexrest/mack_pckg/mack_pckg__Guest__c';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RESTGuest.getTemporaryKey(secretDatas.DeveloperName);
        List<mack_pckg__Temporary_keys__c> temporaryKeys = [
            SELECT Id, Name, mack_pckg__Secret_key__c, mack_pckg__isValid__c, LastModifiedDate
            FROM mack_pckg__Temporary_keys__c
        ];
        System.assertEquals(temporaryKeys.size(), 2);
    }
}