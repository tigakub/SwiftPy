//
//  MTestModule.h
//  SwiftPy
//
//  Created by Edward Janne on 1/13/23.
//

#ifndef MTestModule_h
#define MTestModule_h

#import <Foundation/Foundation.h>

// Creates module and installs it in Python's table of built-in modules
void setUpMTestModule(void (^closure)(void));

// Performs clean up
void tearDownMTestModule(void);

// Objective C class to encapsulate a Swift closure
@interface MTestModule: NSObject {
}

// Constructor which takes a closure as an argument
- (id) init: (void (^)(void)) iClosure;

// Message which invokes the encapsulated closure
- (void) callback;

@end

#endif /* MTestModule_h */
