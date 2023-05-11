import ballerina/http;

listener http:Listener serviceListener = new (9090);
service /public_user on serviceListener{

    isolated resource function post .(@http:Payload PublicUser publicUser) returns ()|string|error {
        return check addPublicUser(publicUser);
    }

    isolated resource function get .() returns PublicUser[]|error? {
        return getAllPublicUsers();
    }

    isolated resource function post address_check(@http:Payload AddressCheck addressCheckRequest, http:Caller caller) returns ()|error? {
        return addressCheck(caller, addressCheckRequest);
    }
}

service /help on serviceListener{

    isolated resource function post .(@http:Payload HelpDocument helpDocument, http:Caller caller) returns error? {
        return addHelpDocument(caller, helpDocument);
    }

    isolated resource function get .() returns HelpDocument[]|error {
        return getAllHelpDocuments();        
    }

    isolated resource function get of_user(string public_user_email) returns HelpDocument[]|error {
        return getAllHelpDocumentsOfUser(public_user_email);        
    }

    isolated resource function put update_status(@http:Payload HelpStatusUpdateRequest helpStatusUpdateRequest, http:Caller caller) returns error? {
        return updateHelpDocStatus(caller, helpStatusUpdateRequest);
    }

    isolated resource function put update_reply(@http:Payload HelpReplyUpdateRequest helpReplyUpdateRequest, http:Caller caller) returns error? {
        return updateHelpDocReply(caller, helpReplyUpdateRequest);
    }
}
