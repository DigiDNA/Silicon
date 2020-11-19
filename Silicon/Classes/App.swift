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

import Cocoa

@objc public class App: NSObject
{
    @objc public private( set ) var name:                String
    @objc public private( set ) var path:                String
    @objc public private( set ) var version:             String?
    @objc public private( set ) var icon:                NSImage?
    @objc public private( set ) var architectures:       [ String ]
    @objc public private( set ) var isAppleSiliconReady: Bool
    @objc public private( set ) var architecture:        String
    
    public init?( path: String )
    {
        var isDir = ObjCBool( booleanLiteral: false )
        
        if FileManager.default.fileExists( atPath: path, isDirectory: &isDir ) == false || isDir.boolValue == false
        {
            return nil
        }
        
        self.name  = FileManager.default.displayName( atPath: path )
        self.path  = path
        self.icon  = NSWorkspace.shared.icon( forFile: path )
        let name   = ( ( path as NSString ).lastPathComponent as NSString ).deletingPathExtension
        let binary = "\( self.path )/Contents/MacOS/\( name )"
        
        if FileManager.default.fileExists( atPath: binary ) == false
        {
            return nil
        }
        
        guard let macho = MachOFile( path: binary ) else
        {
            return nil
        }
        
        self.architectures = macho.architectures
        
        if macho.architectures.contains( "arm64" ) && macho.architectures.contains( "x86_64" )
        {
            self.isAppleSiliconReady = true
            self.architecture        = "Universal"
        }
        else if self.architectures.contains( "arm64" )
        {
            self.isAppleSiliconReady = true
            self.architecture        = "Apple"
        }
        else if self.architectures.contains( "x86_64" )
        {
            self.isAppleSiliconReady = false
            self.architecture        = "Intel"
        }
        else
        {
            self.isAppleSiliconReady = false
            self.architecture        = "Unknown"
        }
    }
    
    @IBAction public func showInFinder( _ sender: Any? )
    {
        NSWorkspace.shared.selectFile( self.path, inFileViewerRootedAtPath: "/" )
    }
}
