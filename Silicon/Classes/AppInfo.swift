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

public class AppInfo
{
    public enum Kind
    {
        case macOS
        case iOS
    }
    
    public let info:       [ String : Any ]
    public let executable: URL
    public let kind:       Kind
    
    private class func readPropertyList( at path: String ) -> [ String : Any ]?
    {
        if let data = FileManager.default.contents( atPath: path )
        {
            return try? PropertyListSerialization.propertyList( from: data, options: [], format: nil ) as? [ String : Any ]
        }
        
        return nil
    }
    
    private class func getExecutableName( from info: [ String : Any ], path: String ) -> String?
    {
        if let e = info[ "CFBundleExecutable" ] as? String, e != "WRAPPEDPRODUCTNAME"
        {
            return e
        }
                
        return ( ( path as NSString ).lastPathComponent as NSString ).deletingPathExtension
    }
    
    public init?( path: String )
    {
        let macOS = "\( path )/Contents/Info.plist"
        let iOS   = "\( path )/WrappedBundle/Info.plist"
        
        if FileManager.default.fileExists( atPath: macOS )
        {
            guard let info = AppInfo.readPropertyList( at: macOS ),
                  let exec = AppInfo.getExecutableName( from: info, path: path )
            else
            {
                return nil
            }
            
            self.info       = info
            self.executable = URL( fileURLWithPath: "\( path )/Contents/MacOS/\( exec )" )
            self.kind       = .macOS
        }
        else if FileManager.default.fileExists( atPath: iOS )
        {
            guard let info = AppInfo.readPropertyList( at: iOS ),
                  let exec = AppInfo.getExecutableName( from: info, path: path )
            else
            {
                return nil
            }
            
            self.info       = info
            self.executable = URL( fileURLWithPath: "\( path )/WrappedBundle/\( exec )" )
            self.kind       = .iOS
        }
        else
        {
            return nil
        }
    }
}
