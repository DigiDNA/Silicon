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

public class DropView: NSView
{
    public var onDrag: ( ( [ URL ] ) -> Bool )?
    public var onDrop: ( ( [ URL ] ) -> Bool )?
    
    @objc public private( set ) dynamic var dragging  = false
    @objc public                dynamic var allowDrop = true
    {
        didSet
        {
            self.unregisterDraggedTypes()
            
            if self.allowDrop
            {
                self.registerForDraggedTypes( [ .fileURL ] )
            }
        }
    }
    
    public override func awakeFromNib()
    {
        if self.allowDrop
        {
            self.registerForDraggedTypes( [ .fileURL ] )
        }
    }
    
    public override func draggingEntered( _ sender: NSDraggingInfo ) -> NSDragOperation
    {
        if self.onDrop == nil || self.allowDrop == false
        {
            return []
        }
        
        if let onDrag = self.onDrag
        {
            guard let urls = sender.draggingPasteboard.readObjects( forClasses: [ NSURL.self ], options: nil ) as? [ URL ] else
            {
                return []
            }
            
            if onDrag( urls ) == false
            {
                return []
            }
        }
        
        self.dragging = true
        
        return .copy
    }
    
    public override func draggingExited( _ sender: NSDraggingInfo? )
    {
        self.dragging = false
    }
    
    public override func draggingEnded( _ sender: NSDraggingInfo )
    {
        self.dragging = false
    }
    
    public override func performDragOperation( _ sender: NSDraggingInfo ) -> Bool
    {
        if self.allowDrop == false
        {
            return false
        }
        
        guard let onDrop = self.onDrop else
        {
            return false
        }
        
        guard let urls = sender.draggingPasteboard.readObjects( forClasses: [ NSURL.self ], options: nil ) as? [ URL ] else
        {
            return false
        }
        
        return onDrop( urls )
    }
}
