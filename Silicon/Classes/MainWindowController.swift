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

public class MainWindowController: NSWindowController
{
    @objc public private( set ) dynamic var loading  = false
    @objc public private( set ) dynamic var appCount = UInt64( 0 )
    
    @IBOutlet public private( set ) dynamic var arrayController: NSArrayController!
    
    public override var windowNibName: NSNib.Name?
    {
        "MainWindowController"
    }
    
    public override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.arrayController.sortDescriptors = [
            NSSortDescriptor( key: "name", ascending: true ),
            NSSortDescriptor( key: "path", ascending: true )
        ]
    }
    
    @IBAction public func reload( _ sender: Any? )
    {
        if self.loading
        {
            return
        }
        
        self.loading  = true
        self.appCount = 0
        
        DispatchQueue.global( qos: .userInitiated ).async
        {
            self.findApps()
            
            DispatchQueue.main.async
            {
                self.loading = false
            }
        }
    }
    
    private func findApps()
    {
        guard let enumerator = FileManager.default.enumerator( atPath: "/" ) else
        {
            return
        }
        
        for e in enumerator
        {
            guard var path = e as? String else
            {
                continue
            }
            
            path = "/\( path )"
            
            if path.hasPrefix( "/Volumes" )
            {
                continue
            }
            
            if path.hasSuffix( ".app" ) == false
            {
                continue
            }
            
            if let app = App( path: path )
            {
                if app.architectures.contains( "arm64" )
                {
                    continue
                }
                
                DispatchQueue.main.async
                {
                    self.arrayController.addObject( app )
                    
                    self.appCount += 1
                }
            }
        }
    }
}
