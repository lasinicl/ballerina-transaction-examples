import ballerina/io;
import ballerinax/java.jdbc;
import ballerina/lang.'transaction as transactions;

string xaDatasourceName = "org.h2.jdbcx.JdbcDataSource";

public function main() returns error? {
    // The JDBC Client for the first H2 database.
    jdbc:Client dbClient1 = check new (url = "jdbc:h2:file:" +
                            "./xa-transactions/testdb1", user = "test",
                            password = "test", options =
                            {datasourceName: xaDatasourceName});
    // The JDBC Client for the second H2 database.
    jdbc:Client dbClient2 = check new (url = "jdbc:h2:file:" +
                            "./xa-transactions/testdb2", user = "test",
                            password = "test", options =
                            {datasourceName: xaDatasourceName});

    // Create the `Employee` table in the first database.
    _ = check dbClient1->execute("CREATE TABLE IF NOT EXISTS EMPLOYEE " +
                                  "(ID INT, NAME VARCHAR(30))");
    // Create the `Salary` table in the second database.
    _ = check dbClient2->execute("CREATE TABLE IF NOT EXISTS SALARY " +
                                 "(ID INT, VALUE FLOAT)");

    // Populate the tables with the records.
    var e1 = check dbClient1->execute("INSERT INTO EMPLOYEE " +
                                      "VALUES (1, 'Anne')");
    var e2 = check dbClient2->execute("INSERT INTO SALARY " +
                                      "VALUES (1, 25000.00)");

    // The transaction block initiates the transaction.
    transaction {
        // Execute the database operations within the transaction
        // to update records in the `Employee` and `Salary` tables.
        var customer = dbClient1->execute("UPDATE EMPLOYEE " +
                                       "SET NAME='Annie' WHERE ID=1");
        var salary = dbClient2->execute("UPDATE SALARY " +
                                       "SET VALUE=30000 WHERE ID=1");

        // Return information about the current transaction.
        transactions:Info transInfo = transactions:info();
        io:println("Transaction Info: ", transInfo);

        // Perform the commit operation of the current transaction.
        var commitResult = commit;
        if commitResult is () {
            // Operations to be executed if the transaction is committed
            // successfully.
            io:println("Transaction committed");
            io:println("Employee Updated: ", customer);
            io:println("Salary Updated: ", salary);
        } else {
            // Operations to be executed if the transaction commit failed.
            io:println("Transaction failed");
        }
    }

    // Close the JDBC clients.
    checkpanic dbClient1.close();
    checkpanic dbClient2.close();
}

// expected output
// [ballerina/http] started HTTP/WS listener 192.168.1.18:37049
// Transaction Info: {"xid":[100,102,53,49,98,55,54,99,45,55,54,51,49,45,52,52,102,101,45,57,50,98,102,45,97,98,50,97,55,54,102,51,49,49,101,49],"retryNumber":0,"startTime":2020-12-14 18:50:21,175,"prevAttempt":null}
// Transaction committed
// Employee Updated: {"affectedRowCount":1,"lastInsertId":null}
// Salary Updated: {"affectedRowCount":1,"lastInsertId":null}
