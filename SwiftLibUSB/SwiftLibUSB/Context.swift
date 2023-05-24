//
//  Context.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

struct Context {
    var libContext: OpaquePointer
    
    init() throws {
        var context: OpaquePointer? = nil;
        let error = withUnsafeMutablePointer(to: &context, libusb_init)
        if (error == 0) {
            libContext = context.unsafelyUnwrapped
        } else {
            throw USBError.from(code: error)
        }
    }
}
