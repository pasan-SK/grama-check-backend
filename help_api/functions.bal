import ballerinax/mongodb;
import ballerina/http;
import ballerinax/slack;

configurable string db_username = ?;
configurable string db_pwd = ?;
configurable string db_name = ?;
configurable string help_collection_name = ?;
configurable string public_user_collection_name = ?;
configurable string slack_bot_oauth_token = ?;
configurable string grama_check_channel_name = ?;

slack:ConnectionConfig slackConfig = {
    auth: {
        token: slack_bot_oauth_token
    }
};
final slack:Client slackClient = check new(slackConfig);

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

public type HelpDocument record {|
    anydata _id?;
    string public_user_email;
    string msg;
    string gramasevaka_area;
    string status;
    string reply;
|};

public type SlackMsg record {|
    string public_user_email;
    string msg;
    string gramasevaka_area;
|};

public type HelpStatusUpdateRequest record {|
    string public_user_email;
    string msg;
    string gramasevaka_area;
    string newStatus;
    string reply;
|};

public type HelpReplyUpdateRequest record {|
    string public_user_email;
    string msg;
    string gramasevaka_area;
    string status;
    string newReply;
|};

public type AddressCheck record {|
    string email;
    string[] address;
    string gramasevaka_area;
|};

final mongodb:Client mongoCli = check new ({connection: {url: string `mongodb+srv://${db_username}:${db_pwd}@gramacheckcluster.used77d.mongodb.net/?retryWrites=true&w=majority`}});



isolated function addHelpDocument(http:Caller caller, HelpDocument helpDocument) returns error? {
    
    map<json> newHelpDocument = { "public_user_email": helpDocument.public_user_email, "msg": helpDocument.msg, "gramasevaka_area": helpDocument.gramasevaka_area, "status": helpDocument.status, "reply": helpDocument.reply };

    HelpDocument[] helpDocuments = [];
    stream<HelpDocument, error?> resultStream = check mongoCli->find(help_collection_name, db_name, rowType = HelpDocument, filter = { "public_user_email": helpDocument.public_user_email, "msg": helpDocument.msg });
    check from HelpDocument doc in resultStream
        do {
            helpDocuments.push(doc);
        };
    check resultStream.close();

    http:Response response = new;
    if helpDocuments.length() > 0 {
        response.statusCode = 400;
        response.setPayload("Same user has already added the same help msg");
        check caller->respond(response);
        return;
    } else {
        check mongoCli->insert(newHelpDocument, help_collection_name, db_name);
        response.statusCode = 201;
        response.setPayload("Added the help document successfully");
        check caller->respond(response);
        return;
    }
}

isolated function getAllHelpDocuments() returns HelpDocument[]|error {
    
    HelpDocument[] helpDocuments = [];
    stream<HelpDocument, error?> resultStream = check mongoCli->find(help_collection_name, db_name, rowType = HelpDocument);
    check from HelpDocument helpDocument in resultStream
        do {
            helpDocuments.push(helpDocument);
        };
    check resultStream.close();
    
    return helpDocuments;   
}

isolated function getAllHelpDocumentsOfUser(string public_user_email) returns HelpDocument[]|error {
    
    HelpDocument[] helpDocuments = [];
    stream<HelpDocument, error?> resultStream = check mongoCli->find(help_collection_name, db_name, filter = { "public_user_email": public_user_email }, rowType = HelpDocument);
    check from HelpDocument helpDocument in resultStream
        do {
            helpDocuments.push(helpDocument);
        };
    check resultStream.close();
    
    return helpDocuments;   
}


isolated function updateHelpDocStatus(http:Caller caller, HelpStatusUpdateRequest helpStatusUpdateRequest) returns error? {
    
    http:Response response = new;

    HelpDocument[] helpDocuments = [];
    stream<HelpDocument, error?> resultStream = check mongoCli->find(help_collection_name, db_name, rowType = HelpDocument, filter = { "public_user_email": helpStatusUpdateRequest.public_user_email, "msg": helpStatusUpdateRequest.msg });
    check from HelpDocument doc in resultStream
        do {
            helpDocuments.push(doc);
        };
    check resultStream.close();

    if helpDocuments.length() > 1 {
        response.statusCode = 400;
        response.setPayload("Duplicates help entries present with same user and msg");
        check caller->respond(response);
        return;
    } else if helpDocuments.length() == 0 {
        response.statusCode = 400;
        response.setPayload("No such help document found in the database");
        check caller->respond(response);
        return;
    } else {
        HelpDocument helpDocument = helpDocuments[0];
        map<json> updatedHelpDocument = {"public_user_email": helpStatusUpdateRequest.public_user_email, "msg": helpStatusUpdateRequest.msg, "gramasevaka_area": helpDocument.gramasevaka_area, "status": helpStatusUpdateRequest.newStatus, "reply": helpDocument.reply };
        // int intResult = check mongoCli->update(updatedHelpDocument, help_collection_name, db_name, filter = { "public_user_email": helpStatusUpdateRequest.public_user_email, "msg": helpStatusUpdateRequest.msg });
        int _ = check mongoCli->delete(help_collection_name, db_name, filter = { "public_user_email": helpStatusUpdateRequest.public_user_email, "msg": helpStatusUpdateRequest.msg });
        check mongoCli->insert(updatedHelpDocument, help_collection_name, db_name);

        response.setPayload("Updated the help document status successfully");
        check caller->respond(response);
        return;
    }
}


isolated function updateHelpDocReply(http:Caller caller, HelpReplyUpdateRequest helpReplyUpdateRequest) returns error? {
    
    http:Response response = new;

    HelpDocument[] helpDocuments = [];
    stream<HelpDocument, error?> resultStream = check mongoCli->find(help_collection_name, db_name, rowType = HelpDocument, filter = { "public_user_email": helpReplyUpdateRequest.public_user_email, "msg": helpReplyUpdateRequest.msg });
    check from HelpDocument doc in resultStream
        do {
            helpDocuments.push(doc);
        };
    check resultStream.close();

    if helpDocuments.length() > 1 {
        response.statusCode = 400;
        response.setPayload("Duplicates help entries present with same user and msg");
        check caller->respond(response);
        return;
    } else if helpDocuments.length() == 0 {
        response.statusCode = 400;
        response.setPayload("No such help document found in the database");
        check caller->respond(response);
        return;
    } else {
        HelpDocument helpDocument = helpDocuments[0];
        map<json> updatedHelpDocument = {"public_user_email": helpReplyUpdateRequest.public_user_email, "msg": helpReplyUpdateRequest.msg, "gramasevaka_area": helpDocument.gramasevaka_area, "status": helpDocument.status, "reply": helpReplyUpdateRequest.newReply };
        // int intResult = check mongoCli->update(updatedHelpDocument, help_collection_name, db_name, filter = { "public_user_email": helpStatusUpdateRequest.public_user_email, "msg": helpStatusUpdateRequest.msg });
        int _ = check mongoCli->delete(help_collection_name, db_name, filter = { "public_user_email": helpReplyUpdateRequest.public_user_email, "msg": helpReplyUpdateRequest.msg });
        check mongoCli->insert(updatedHelpDocument, help_collection_name, db_name);

        response.setPayload("Updated the help document status successfully");
        check caller->respond(response);
        return;
    }
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

isolated function putSlackMsg(http:Caller caller, SlackMsg slackMsg) returns error? {
    http:Response response = new;
    
    slack:Message messageParams = {
        channelName: grama_check_channel_name,
        text: "New issue posted",
        blocks: [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "New issue from " + slackMsg.public_user_email + " in " + slackMsg.gramasevaka_area + " gramasevaka area : \n" + slackMsg.msg
                }
            }
        ],
        mrkdwn: true
    };

    string|error threadID = slackClient->postMessage(messageParams);
    if (threadID is error) {
        response.statusCode = 500;
        response.setPayload("Error while sending the message");
        check caller->respond(response);
        return;
    } else {
        response.statusCode = 200;
        response.setPayload("Message sent successfully");
        check caller->respond(response);
        return;
    }
}



