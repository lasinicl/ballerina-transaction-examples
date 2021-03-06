import ballerina/io;

public function main() returns error? {
    // The retry statement provides a general-purpose retry.
    // facility, which is independent of the transactions.
    // Here, retrying happens according to the default retry manager
    // since there is no custom retry manager being passed to 
    // the retry operation.
    // As defined, retrying happens for maximum 3 times.
    retry (3) {
        io:println("Attempting execution...");
        // Calls a function, which simulates an error scenario to 
        // trigger the retry operation.
        check doWork();
    }

    int i = 0;

    // You can pass a retry manager class as a type parameter.
    retry<MyRetryManager>(2) {
       io:println("Attempting execution...");
       i += 1;
       if(i < 2) {
           fail error("Custom Error");
       }
       io:println("Work completed.");
    }
}

int count = 0;

// The function, which may return an error.
function doWork() returns error? {
    if count < 1 {
        count += 1;
        // Return a retriable error so that
        // the default retry manager retries.
        return error error:Retriable("Execution Error");
    } else {
        io:println("Work completed.");
    }
}

// Sample retry manager class with an arbitrarily logic.
public class MyRetryManager {
   private int count;
   public function init(int count = 3) {
       self.count = count;
   }
   public function shouldRetry(error? e) returns boolean {
     if e is error && self.count >  0 {
        self.count -= 1;
        return true;
     } else {
        return false;
     }
   }
}

// expected output
// Attempting execution...
// Attempting execution...
// Work completed.
// Attempting execution...
// Attempting execution...
// Work completed..
