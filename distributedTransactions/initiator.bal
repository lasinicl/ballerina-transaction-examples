import ballerina/http;
import ballerina/log;
import ballerina/lang.'transaction as transactions;

// This is the initiator of the distributed transaction.
service / on new http:Listener(8080) {
    resource function get init(http:Caller conn, http:Request req) {
        http:Response res = new;
        log:printInfo("Initiating transaction...");
        // When transaction statement starts, a distributed transaction context is created.
        transaction {
            // Print the information about the current transaction.
            log:printInfo("Started transaction: " +
                          transactions:info().toString());

            // When a participant is called, the transaction context is propagated and
            // that participant joins the distributed transaction.
            boolean successful = callBusinessService();
            if (successful) {
                res.statusCode = http:STATUS_OK;
                // Run the `2-phase commit coordination` protocol.
                // All participants are prepared and depending on the joint outcome,
                // either a `notify commit` or `notify abort` will be sent to the participants.
                var commitResult = commit;
                if commitResult is () {
                    log:printInfo("Transaction committed");
                } else {
                    log:printError("Transaction failed");
                }
            } else {
                res.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                log:printError("Internal Server Error");
                rollback;
            }
        }

        // Send the response back to the client.
        var result = conn->respond(res);
        if (result is error) {
            log:printError("Could not send response back to client",
            'error = result);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

// This is the business function call to the participant.
transactional function callBusinessService() returns @tainted boolean {
    http:Client participantEP = checkpanic new (
                                    "http://localhost:8889/stockquote/" +
                                    "update/updateStockQuote");

    // Generate the payload.
    float price = 100.00;
    json bizReq = {symbol: "GOODS", price: price};

    // Send the request to the backend service.
    http:Request req = new;
    req.setJsonPayload(bizReq);
    http:Response|error result = participantEP->post("", req);
    log:printInfo("Got response from bizservice");
    if (result is http:Response) {
        return result.statusCode == http:STATUS_OK;
    } else {
        return false;
    }
}

// expected output
// [ballerina/http] started HTTP/WS listener 192.168.1.18:37869
// [ballerina/http] started HTTP/WS listener 0.0.0.0:8080
// time = 2020-12-15 21:19:15,787 level = INFO  module = "" message = "Initiating transaction..."
// time = 2020-12-15 21:19:15,820 level = INFO  module = "" message = "Started transaction: {"xid":[54,50,57,53,51,55,101,101,45,50,100,52,49,45,52,55,56,52,45,57,98,49,102,45,98,57,98,57,97,57,51,50,54,50,99,97],"retryNumber":0,"startTime":2020-12-15 21:19:15,801,"prevAttempt":null}"
// time = 2020-12-15 21:19:16,315 level = INFO  module = "" message = "Got response from bizservice"
// time = 2020-12-15 21:19:16,373 level = INFO  module = "" message = "Transaction committed"
// time = 2020-12-15 21:19:16,376 level = INFO  module = "" message = "Sent response back to client"
