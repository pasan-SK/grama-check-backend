import ballerina/log;
import ballerinax/trigger.slack;
import ballerina/http;
// import ballerina/http;

configurable string slack_token = ?;
configurable string slack_verification_token = ?;

slack:ListenerConfig configuration = {
    verificationToken: slack_verification_token
};

public type Challenge record {|
    string token;
    string challenge;
    string 'type;
|};

listener slack:Listener slackListener = new (configuration);

isolated service slack:UserChangeService on slackListener {
    isolated remote function onUserChange(slack:GenericEventWrapper payload) returns error? {
        log:printInfo("New Message");
    }
    isolated resource function post .(@http:Payload Challenge challenge) returns string {
        return challenge.challenge;
    }
    // isolated remote function onMessage(slack:Message message) returns error? {
    //     log:printInfo("New Message");
    //     log:printInfo(message.api_app_id);
    //     return ();
    // }
}

// isolated service slack:MessageService on slackListener {
//     isolated remote function onMessage(slack:Message payload) returns error? {
//         log:printInfo("New Message");
//         log:printInfo(message.api_app_id);
//         return ();
//     }

// }
// isolated function onStartup() {
//     log:printInfo("Service started.");
// }

// isolated function onShutdown() {
//     log:printInfo("Service stopped.");
// }

