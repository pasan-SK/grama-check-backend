import ballerina/http;

listener http:Listener serviceListener = new (9090);
service /public_user on serviceListener{

    // isolated resource function post .(@http:Payload PublicUser publicUser, http:Caller caller) returns error? {
    //     return check addPublicUser(publicUser, caller);
    // }

    // isolated resource function get .() returns PublicUser[]|error {
    //     return getAllPublicUsers();
    // }

    isolated resource function post address_check(@http:Payload AddressCheck addressCheckRequest, http:Caller caller) returns error? {
        return addressCheck(caller, addressCheckRequest);
    }
}