import ballerina/lang.'transaction as transactions;
import ballerina/io;

// Defines the rollback handlers, which are triggered once the
// rollback statement is executed.
isolated function onRollbackFunc(transactions:Info info, error? cause,
                        boolean willRetry) {
    io:println("Rollback handler #1 executed.");
}

isolated function onRollbackFunc2(transactions:Info info, error? cause,
                         boolean willRetry) {
    io:println("Rollback handler #2 executed.");
}

// Defines the commit handler, which gets triggered once the
// commit action is executed.
isolated function onCommitFunc(transactions:Info info) {
    io:println("Commit handler executed.");
}

public function main() returns error? {
    // The `transaction` block initiates the transaction.
    transaction {
        // Register the rollback handler to the transaction context.
        // Multiple rollback handlers can be registered and they
        // are executed in reverse order.
        transactions:onRollback(onRollbackFunc);
        transactions:onRollback(onRollbackFunc2);

        // Register the commit handler to the transaction context.
        // Multiple commit handlers can be registered and they
        // are executed in reverse order.
        transactions:onCommit(onCommitFunc);

        // Returns information about the current transaction.
        transactions:Info transInfo = transactions:info();
        io:println("Transaction Info: ", transInfo);

        // Invokes the local participant.
        var res = erroneousOperation();
        if res is error {
            // The local participant execution fails.
            io:println("Local participant error.");
            rollback;
        } else {
            io:println("Local participant successfully executed.");
            var commitRes = check commit;
        }
    }
}

function erroneousOperation() returns error? {
    io:println("Invoke local participant function.");
    return error("Simulated Failure");
}

// expected output
// Transaction Info: {"xid":[50,50,98,100,101,48,54,53,45,49,50,98,97,45,52,52,97,99,45,98,48,50,100,45,57,97,99,49,50,51,100,53,49,57,56,53],"retryNumber":0,"startTime":1600688819823,"prevAttempt":null}
// Invoke local participant function.
// Local participant error.
// Rollback handler #2 executed.
// Rollback handler #1 executed.