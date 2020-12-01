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
    @objc public private( set ) dynamic var started          = false
    @objc public private( set ) dynamic var loading          = false
    @objc private               dynamic var stop             = false
    @objc public private( set ) dynamic var appsFolderOnly   = true
    @objc public private( set ) dynamic var recurseIntoApps  = false
    @objc public private( set ) dynamic var excludeAppleApps = false
    @objc public private( set ) dynamic var appCount         = UInt64( 0 )
    @objc public private( set ) dynamic var archFilter       = 0
    {
        didSet
        {
            if self.archFilter == 1
            {
                self.archFilteredApps.filterPredicate = NSPredicate( format: "isAppleSiliconReady=NO" )
            }
            else if self.archFilter == 2
            {
                self.archFilteredApps.filterPredicate = NSPredicate( format: "isAppleSiliconReady=YES" )
            }
            else
            {
                self.archFilteredApps.filterPredicate = nil
            }
        }
    }
    
    @IBOutlet public private( set ) dynamic var allApps:          NSArrayController!
    @IBOutlet public private( set ) dynamic var archFilteredApps: NSArrayController!
    @IBOutlet public private( set ) dynamic var arrayController:  NSArrayController!
    @IBOutlet public private( set ) dynamic var dropView:         DropView!
    
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
                alert.alertStyle      = .critical
                
                alert.beginSheetModal( for: window, completionHandler: nil )
                
                return true
            }
            
            if app.isAppleSiliconReady
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
            alert.alertStyle      = .critical
            
            alert.beginSheetModal( for: window, completionHandler: nil )
            
            return true
        }
    }
    
    public func stopLoading()
    {
        self.stop = true
    }
    
    @IBAction public func newDocument( _ sender: Any? )
    {
        let reset =
        {
            self.appCount   = 0
            self.archFilter = 0
            self.loading    = false
            self.stop       = false
            self.started    = false
        }
        
        if self.loading
        {
            self.stop = true
            
            DispatchQueue.global( qos: .userInitiated ).async
            {
                while self.loading
                {
                    Thread.sleep( forTimeInterval: 0.1 )
                }
                
                DispatchQueue.main.async
                {
                    reset()
                }
            }
        }
        else
        {
            reset()
        }
    }
    
    @IBAction public func reload( _ sender: Any? )
    {
        if self.loading
        {
            NSSound.beep()
            
            return
        }
        
        self.window?.setContentBorderThickness( 32, for: .minY )
        
        self.started  = true
        self.loading  = true
        self.appCount = 0
        
        self.allApps.remove( contentsOf: self.allApps.content as? [ Any ] ?? [] )
        
        DispatchQueue.global( qos: .userInitiated ).async
        {
            self.findApps()
            
            DispatchQueue.main.async
            {
                self.loading = false
            }
        }
    }
    
    @IBAction private func revealApp( _ sender: Any? )
    {
        guard let app = self.arrayController.selectedObjects.first as? App else
        {
            NSSound.beep()
            
            return
        }
        
        app.showInFinder( sender )
    }
    
    private func findApps()
    {
        if self.appsFolderOnly
        {
            let paths = NSSearchPathForDirectoriesInDomains( .applicationDirectory, .allDomainsMask, true )
            
            for path in paths
            {
                self.findApps( in: path )
            }
        }
        else
        {
            self.findApps( in: "/" )
        }
    }
    
    private func findApps( in directory: String )
    {
        guard let enumerator = FileManager.default.enumerator( atPath: directory ) else
        {
            return
        }
        
        var e = enumerator.nextObject()
        
        while e != nil
        {
            if self.stop
            {
                return
            }
            
            autoreleasepool
            {
                guard var path = e as? String else
                {
                    e = enumerator.nextObject()
                    
                    return
                }
                
                path = ( directory as NSString ).appendingPathComponent( path )
                
                if path.hasPrefix( "/Volumes" )
                {
                    e = enumerator.nextObject()
                    
                    return
                }
                
                if path.hasSuffix( ".app" ) == false
                {
                    e = enumerator.nextObject()
                    
                    return
                }
                
                if self.recurseIntoApps == false
                {
                    enumerator.skipDescendents()
                }
                
                if let app = App( path: path )
                {
                    DispatchQueue.main.async
                    {
                        if self.excludeAppleApps && ( app.bundleID?.starts( with: "com.apple." ) ?? false  )
                        {
                            return
                        }
                        
                        self.allApps.addObject( app )
                        
                        self.appCount += 1
                    }
                }
                
                e = enumerator.nextObject()
            }
        }
    }
}
