/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2020 DigiDNA - www.imazing.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Foundation

public class MachOFile
{
    public enum Architecture: String {
        case i386
        case x86_64
        case arm
        case arm64
        case ppc
        case unknown = "<unknown>"
    }
    
    public private( set ) var architectures: [ Architecture ] = []
    
    public init?( path: String )
    {
        do
        {
            try setupArchitectures(path: path)
        }
        catch
        {
            return nil
        }
    }
}


// MARK: - Helpers

extension MachOFile {
    
    public var isAppleSiliconReady: Bool {
        includesAppleArchitecture
    }
    
    public var architecturesName: String {
        [
            uniqueArchitectureName,
            universalName,
            legacyArchitecturesNames
        ].compactMap { $0 }.first ?? "Unknown"
    }
}

extension MachOFile.Architecture {
    
    public var name: String {
        switch self {
        case .arm64:
            return "Apple"
        case .x86_64:
            return "Intel 64"
        case .i386:
            return "Intel 32"
        case .ppc:
            return "PowerPC"
        default:
            return "Unknown"
        }
    }
    
    public var isApple: Bool {
        self == .arm64
    }
    
    public var isIntel32: Bool {
        self == .i386
    }
    
    public var isIntel64: Bool {
        self == .x86_64
    }
    
    public var isIntel: Bool {
        isIntel32 || isIntel64
    }
    
    public var isPPC: Bool {
        self == .ppc
    }
}

// MARK: - Private

extension MachOFile {
    
    private enum Error: Swift.Error {
        case failedToReadArchitectures
    }
    
    private var isUniqueArchitecture: Bool {
        architectures.count == 1
    }
    
    private var includesAppleArchitecture: Bool {
        architectures.filter({ $0.isApple }).count > 0
    }
    
    private var includesIntelArchitecture: Bool {
        architectures.filter({ $0.isIntel }).count > 0
    }
    
    private var includesIntel32Architecture: Bool {
        architectures.filter({ $0.isIntel32 }).count > 0
    }
    
    private var includesIntel64Architecture: Bool {
        architectures.filter({ $0.isIntel64 }).count > 0
    }
    
    private var includesPPCArchitecture: Bool {
        architectures.filter({ $0.isPPC }).count > 0
    }
    
    private var includesLegacyArchitectures: Bool {
        includesPPCArchitecture || includesIntelArchitecture
    }
    
    private var universalName: String? {
        includesAppleArchitecture ? "Universal" : nil
    }
    
    private var ppcName: String? {
        includesPPCArchitecture ? "PowerPC" : nil
    }
    
    private var intelName: String? {
        if includesIntel32Architecture && includesIntel64Architecture {
            return "Intel 32/64"
        } else if includesIntel32Architecture {
            return "Intel 32"
        } else if includesIntel64Architecture {
            return "Intel 64"
        } else {
            return nil
        }
    }
    
    private var legacyArchitecturesNames: String? {
        if !includesAppleArchitecture && includesLegacyArchitectures {
            return [ppcName, intelName]
                .compactMap { $0 }
                .joined(separator: "/")
        } else {
            return nil
        }
    }
    
    private var uniqueArchitectureName: String? {
        isUniqueArchitecture ? architectures.first?.name : nil
    }
    
    private func setupArchitectures ( path: String ) throws {
        let stream = try BinaryStream( path: path )
        let magic  = try stream.readBigEndianUnsignedInteger()
        
        switch magic {
        case 0xCAFEBABE:
            let count = try stream.readBigEndianUnsignedInteger()
            
            for _ in 0 ..< count
            {
                let cpu = try stream.readBigEndianUnsignedInteger()
                let _   = try stream.readBigEndianUnsignedInteger()
                let _   = try stream.readBigEndianUnsignedInteger()
                let _   = try stream.readBigEndianUnsignedInteger()
                let _   = try stream.readBigEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
        case 0xCEFAEDFE:
            let cpu = try stream.readLittleEndianUnsignedInteger()
            
            self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
        case 0xFEEDFACE:
            let cpu = try stream.readBigEndianUnsignedInteger()
            
            self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
        case 0xCFFAEDFE:
            let cpu = try stream.readLittleEndianUnsignedInteger()
            
            self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
        case 0xFEEDFACF:
            let cpu = try stream.readBigEndianUnsignedInteger()
            
            self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
        default:
            throw Error.failedToReadArchitectures
        }
    }
    
    private static func cpuToArch( type: UInt32 ) -> Architecture
    {
        switch type {
        case 7:
            return .i386
        case 7 | 0x01000000:
            return .x86_64
        case 12:
            return .arm
        case 12 | 0x01000000:
            return .arm64
        case 18:
            return .ppc
        default:
            return .unknown
        }
    }
}
