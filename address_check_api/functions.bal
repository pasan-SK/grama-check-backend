import ballerinax/mongodb;
import ballerina/http;

configurable string db_username = ?;
configurable string db_pwd = ?;
configurable string db_name = ?;
configurable string public_user_collection_name = ?;

public type PublicUser record {|
    anydata _id?;
    string email;
    string first_name;
    string last_name;
    string nic;
    string[] address;
    string gramasevaka_area;
    string phone_num;
|};

public type AddressCheck record {|
    string email;
    string[] address;
    string gramasevaka_area;
    string isValid?;
|};

final mongodb:Client mongoCli = check new ({connection: {url: string `mongodb+srv://${db_username}:${db_pwd}@gramacheckcluster.used77d.mongodb.net/?retryWrites=true&w=majority`}});

isolated function addPublicUser(PublicUser publicUser) returns string|error {
    
    map<json> newPublicUser = { "email": publicUser.email, "first_name": publicUser.first_name, "last_name": publicUser.last_name, "nic": publicUser.nic, "address": publicUser.address, "gramasevaka_area": publicUser.gramasevaka_area, "phone_num": publicUser.phone_num };

    // TODO: Need to check the whether there is an user with the same email first !!!!
    check mongoCli->insert(newPublicUser, public_user_collection_name, db_name);
    
    return "Added the public user successfully";
}

isolated function getAllPublicUsers() returns PublicUser[]|error {
    
    PublicUser[] publicUsers = [];
    stream<PublicUser, error?> resultStream = check mongoCli->find(public_user_collection_name, db_name, rowType = PublicUser);
    check from PublicUser publicUser in resultStream
        do {
            publicUsers.push(publicUser);
        };
    check resultStream.close();
    
    return publicUsers;
}

isolated function addressCheck(http:Caller caller, AddressCheck addressCheckRequest) returns error? {
    
    http:Response response = new;

    string addressCheckEmail = addressCheckRequest.email;
    string[] addressCheckAddress = addressCheckRequest.address;
    string addressCheckGramasevakaArea = addressCheckRequest.gramasevaka_area;

    stream<PublicUser, error?> resultStream = check mongoCli->find(public_user_collection_name, db_name, filter = { "email": addressCheckEmail }, rowType = PublicUser);   

    PublicUser[] publicUsers = [];
    check from PublicUser publicUser in resultStream
        do {
            publicUsers.push(publicUser);
        };
    check resultStream.close();

    if (publicUsers.length() == 0) {
        response.statusCode = 400;
        response.setPayload("Couldn't find the user with the given email");
        check caller->respond(response);
        return;
    } else if (publicUsers.length() > 1) {
        response.statusCode = 400;
        response.setPayload("Multiple users found with the given email");
        check caller->respond(response);
        return;
    } else {
        
        PublicUser publicUser = publicUsers[0];
        string[] publicUserAddress = publicUser.address;
        string publicUserGramasevakaArea = publicUser.gramasevaka_area;

        if (publicUserAddress == addressCheckAddress && publicUserGramasevakaArea == addressCheckGramasevakaArea) {
            response.statusCode = 200;
            response.setPayload("Address is valid");
            check caller->respond(response);
            return;
        } else {
            response.statusCode = 400;
            response.setPayload("Address is invalid");
            check caller->respond(response);
            return;
        }
    }
}
