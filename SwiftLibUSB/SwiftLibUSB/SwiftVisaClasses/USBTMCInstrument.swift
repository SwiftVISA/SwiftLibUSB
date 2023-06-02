//
//  USBTMCInstrument.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 6/2/23.
//

import Foundation
import CoreSwiftVISA

class USBTMCInstrument : USBInstrument {
    
}

extension USBTMCInstrument : MessageBasedInstrument {
    func read(until terminator: String, strippingTerminator: Bool, encoding: String.Encoding, chunkSize: Int) throws -> String {
        <#code#>
    }
    
    func readBytes(length: Int, chunkSize: Int) throws -> Data {
        <#code#>
    }
    
    func readBytes(maxLength: Int?, until terminator: Data, strippingTerminator: Bool, chunkSize: Int) throws -> Data {
        
    }
    
    func write(_ string: String, appending terminator: String?, encoding: String.Encoding) throws -> Int {
        
    }
    
    func writeBytes(_ data: Data, appending terminator: Data?) throws -> Int {
        
    }
    
    var attributes: CoreSwiftVISA.MessageBasedInstrumentAttributes {
        get {
            <#code#>
        }
        set(newValue) {
            <#code#>
        }
    }
}
