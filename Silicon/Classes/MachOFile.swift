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
    public private( set ) var architectures: [ String ] = []
    
    public init?( path: String )
    {
        do
        {
            let stream = try BinaryStream( path: path )
            let magic  = try stream.readBigEndianUnsignedInteger()
            
            if magic == 0xCAFEBABE
            {
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
            }
            else if magic == 0xCEFAEDFE
            {
                let cpu = try stream.readLittleEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else if magic == 0xFEEDFACE
            {
                let cpu = try stream.readBigEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else if magic == 0xCFFAEDFE
            {
                let cpu = try stream.readLittleEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else if magic == 0xFEEDFACF
            {
                let cpu = try stream.readBigEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else
            {
                return nil
            }
        }
        catch
        {
            return nil
        }
    }
    
    public static func cpuToArch( type: UInt32 ) -> String
    {
        if type == 7
        {
            return "i386"
        }
        else if type == 7 | 0x01000000
        {
            return "x86_64"
        }
        else if type == 12
        {
            return "arm"
        }
        else if type == 12 | 0x01000000
        {
            return "arm64"
        }
        
        return "<unknown>"
    }
}
