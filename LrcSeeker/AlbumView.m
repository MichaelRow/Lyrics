//
//  AlbumView.m
//  LrcSeeker
//
//  Created by Eru on 15/10/21.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "AlbumView.h"

@implementation AlbumView

@synthesize artwork;
@synthesize artworkData;
@synthesize artworkTempPath;
@synthesize artworkName;

-(id)initWithFrame:(NSRect)frameRect {
    NSLog(@"AlbumView init");
    self=[super initWithFrame:frameRect];
    defaults=[NSUserDefaults standardUserDefaults];
    if (self) {
        NSString *cachesDir=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        tempDir=[cachesDir stringByAppendingPathComponent:@"LrcSeeker"];
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    if (artwork) {
        NSRect bounds=[self bounds];
        NSSize imageSize=[artwork size];
        drawingRect.origin=NSZeroPoint;
        if (imageSize.width>=imageSize.height) {
            if (imageSize.width>bounds.size.width) {
                drawingRect.size.width=bounds.size.width;
                drawingRect.size.height=bounds.size.width/imageSize.width*imageSize.height;
                drawingRect.origin.y=(bounds.size.height-drawingRect.size.height)/2;
            }
        }
        else {
            if (imageSize.height>bounds.size.height) {
                drawingRect.size.height=bounds.size.height;
                drawingRect.size.width=bounds.size.height/imageSize.height*imageSize.width;
                drawingRect.origin.x=(bounds.size.width-drawingRect.size.width)/2;
            }
        }
        [artwork drawInRect:drawingRect];
    }
    else {
        [[NSColor whiteColor] set];
        drawingRect=[self bounds];
        [NSBezierPath fillRect:drawingRect];
        [[NSColor grayColor] set];
        [NSBezierPath setDefaultLineWidth:1];
        [NSBezierPath strokeRect:[self bounds]];
    }
    
    //draw rough edge for artwork bounds
    if (([[self window] firstResponder]==self) && ([NSGraphicsContext currentContextDrawingToScreen])) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        if (artwork) {
            [NSBezierPath fillRect:drawingRect];
        }
        else {
            [NSBezierPath fillRect:[self bounds]];
        }
        [NSGraphicsContext restoreGraphicsState];
    }
}

-(void)noSelectionImage {
    date = [NSDate date];
    artworkTempPath=[[NSBundle mainBundle] pathForResource:@"no_selection" ofType:@"png"];
    artworkName=@"No_Selection_Img";
    artworkData=[[NSData alloc] initWithContentsOfFile:artworkTempPath];
    [self setArtwork:[[NSImage alloc] initWithData:artworkData]];
    [self setNeedsDisplay:YES];
}

-(void)noFoundImage {
    date = [NSDate date];
    artworkTempPath=[[NSBundle mainBundle] pathForResource:@"not_found" ofType:@"png"];
    artworkName=@"Not_Found_Img";
    artworkData=[[NSData alloc] initWithContentsOfFile:artworkTempPath];
    [self setArtwork:[[NSImage alloc] initWithData:artworkData]];
    [self setNeedsDisplay:YES];
}

#pragma mark - NSResponder

-(BOOL)acceptsFirstResponder {
    return YES;
}

-(BOOL)resignFirstResponder {
    [self setNeedsDisplay:YES];
    return YES;
}

-(BOOL)becomeFirstResponder {
    [self setNeedsDisplay:YES];
    return YES;
}

-(void)keyDown:(NSEvent *)theEvent {
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

-(void)insertTab:(id)sender {
    [[self window] selectKeyViewFollowingView:self];
}

-(void)insertBacktab:(id)sender {
    [[self window] selectKeyViewPrecedingView:self];
}

#pragma mark - Pasteboard & Drag & Copy

-(void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    NSLog(@"AlbumView:Get data to paste");
    [item setData:[snapshotArtwork TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}

-(void)writeToPasteboard:(NSPasteboard*)pb {
    [pb clearContents];
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    NSArray *pasteTypes = [NSArray arrayWithObjects:NSPasteboardTypeTIFF, nil];
    [item setDataProvider:self forTypes:pasteTypes];
    [pb writeObjects:[NSArray arrayWithObject:item]];
    snapshotArtwork=artwork;
    NSLog(@"AlbumView:Preparing image for copy");
}

-(IBAction)copy:(id)sender {
    if (artwork==nil) {
        return;
    }
    NSPasteboard* pb=[NSPasteboard generalPasteboard];
    [self writeToPasteboard:pb];
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationCopy;
}

#pragma mark - Mouse Events

-(void)mouseDown:(NSEvent *)theEvent {
    mouseDownEvent=theEvent;
}

//-(void)rightMouseDown:(NSEvent *)theEvent {
//    NSMenu* rightClickMenu=[[NSMenu alloc] initWithTitle:@"Contextual Menu"];
//    [rightClickMenu insertItemWithTitle:NSLocalizedString(@"DOWNLOAD_ARTWORK", nil) action:@selector(downloadArtwork) keyEquivalent:@"" atIndex:0];
//    [NSMenu popUpContextMenu:rightClickMenu withEvent:theEvent forView:self];
//}

-(void)mouseDragged:(NSEvent *)theEvent {
    
    //Artwork only to be dragged when dragging distance was long enough.
    NSPoint downPoint=[mouseDownEvent locationInWindow];
    NSPoint dragPoint=[theEvent locationInWindow];
    float distance=hypotf(downPoint.x-dragPoint.x, downPoint.y-dragPoint.y);
    if (distance<6 || artwork==nil) {
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:artworkTempPath isDirectory:nil]) {
        [artworkData writeToFile:artworkTempPath atomically:NO];
    }
    NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:self.artwork];
    [dragItem setDraggingFrame:drawingRect contents:artwork];
    [self beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:theEvent source:self];
    [self dragFile:artworkTempPath fromRect:drawingRect slideBack:YES event:mouseDownEvent];
}

#pragma mark - Accessors

-(void)setArtwork:(NSImage *)theImage {
    date = [NSDate date];
    artwork=theImage;
    [self setNeedsDisplay:YES];
}

-(void)setArtWorkWithURL:(NSURL *)theURL andArtworkName:(NSString *) theName{
    date = [NSDate date];
    NSDate *dateWhenLoading = date;
    artworkName=[theName copy];
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask=[session dataTaskWithURL:theURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data || error) {
            NSLog(@"AblumView:Failed to get Artwork data");
            [self noFoundImage];
            return;
        }
        if ([date isEqualToDate:dateWhenLoading]) {
            artworkData=data;
            artwork=[[NSImage alloc] initWithData:data];
            artworkTempPath=[tempDir stringByAppendingPathComponent:[theURL lastPathComponent]];
            [self setNeedsDisplay:YES];
            return;
        }
    }];
    [dataTask resume];
}

@end
