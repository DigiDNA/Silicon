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
    @objc public private( set ) dynamic var started        = false
    @objc public private( set ) dynamic var loading        = false
    @objc public private( set ) dynamic var empty          = false
    @objc public private( set ) dynamic var appsFolderOnly = true
    @objc public private( set ) dynamic var appCount       = UInt64( 0 )
    
    @IBOutlet public private( set ) dynamic var arrayController: NSArrayController!
    @IBOutlet public private( set ) dynamic var dropView:        DropView!
    
    public override var windowNibName: NSNib.Name?
    {
        "MainWindowController"
    }
    
    public override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.arrayController.sortDescriptors = [
            NSSortDescriptor( key: "name", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ),
            NSSortDescriptor( key: "path", ascending: true )
        ]
        
        self.window?.setContentBorderThickness( 0, for: .minY )
        
        self.dropView.onDrag = { _ in return true }
        self.dropView.onDrop =
        {
            urls in
            
            guard let window = self.window, let url = urls.first else
            {
                NSSound.beep()
                
                return false
            }
            
            guard let app = App( path: url.path ) else
            {
                let alert = NSAlert()
                
                alert.messageText     = "Not an Application"
                alert.informativeText = "The file you dropped was not detected as a macOS application."
                
                alert.beginSheetModal( for: window, completionHandler: nil )
                
                return false
            }
            
            if app.architectures.contains( "arm64" )
            {
                let alert = NSAlert()
                
                alert.messageText     = "Apple Silicon Supported"
                alert.informativeText = "The application will run natively on Apple Silicon hardware."
                
                alert.beginSheetModal( for: window, completionHandler: nil )
                
                return true
            }
            
            let alert = NSAlert()
            
            alert.messageText     = "No Apple Silicon Support"
            alert.informativeText = "The application will be emulated on Apple Silicon hardware."
            
            alert.beginSheetModal( for: window, completionHandler: nil )
            
            return false
        }
    }
    
    @IBAction public func reload( _ sender: Any? )
    {
        if self.loading
        {
            return
        }
        
        self.window?.setContentBorderThickness( 32, for: .minY )
        
        self.started  = true
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
        let root = self.appsFolderOnly ? "/Applications" : "/"
        
        guard let enumerator = FileManager.default.enumerator( atPath: root ) else
        {
            return
        }
        
        for e in enumerator
        {
            guard var path = e as? String else
            {
                continue
            }
            
            path = "\( root )/\( path )"
            
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
