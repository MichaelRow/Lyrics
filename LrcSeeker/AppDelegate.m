//
//  AppDelegate.m
//  LrcSeeker
//
//  Created by Eru on 15/10/20.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate

+ (void)initialize {
    NSMutableDictionary *registerDefaults=[NSMutableDictionary dictionary];
    [registerDefaults setObject:[NSNumber numberWithBool:YES] forKey:LSAutofillAndSearchWhenLaunched];
    [registerDefaults setObject:[NSNumber numberWithBool:YES] forKey:LSQuitWhenClosed];
    [registerDefaults setObject:[NSNumber numberWithBool:YES] forKeyedSubscript:LSLyricStyle];
    [registerDefaults setObject:@"" forKey:LSLrcPath];
    [registerDefaults setObject:@"" forKey:LSArtworkPath];
    [registerDefaults setObject:[NSNumber numberWithInteger:0] forKey:LSLrcPathIndex];
    [registerDefaults setObject:[NSNumber numberWithInteger:0] forKey:LSArtworkPathIndex];
    [registerDefaults setObject:[NSNumber numberWithBool:NO] forKey:LSWhetherConvertChinese];
    [registerDefaults setObject:[NSNumber numberWithInteger:0] forKey:LSChineseConvertTpye];
    [registerDefaults setObject:@"Helvetica" forKey:LSFontName];
    [registerDefaults setObject:[NSNumber numberWithFloat:14] forKey:LSFontSize];
    [registerDefaults setObject:[NSNumber numberWithInteger:0] forKey:LSServerIndex];
    [[NSUserDefaults standardUserDefaults] registerDefaults:registerDefaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleError:) name:ErrorOccuredNotification object:nil];
    [songListView setDoubleAction:@selector(showLyricPreview:)];
    xiami=[[Xiami alloc] init];
    ttpod=[[TTPod alloc] init];
    qianqian=[[QianQian alloc] init];
    geciMe=[[GeCiMe alloc] init];
    songs=[[NSMutableArray alloc]init];
    iTunes=[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    [albumView noSelectionImage];
    defaults=[NSUserDefaults standardUserDefaults];
    [nc addObserver:self selector:@selector(xiamiLoaded) name:LSXiamiLoadedNotification object:nil];
    [nc addObserver:self selector:@selector(qianqianLoaded) name:LSQianQianLoadedNotification object:nil];
    [nc addObserver:self selector:@selector(ttpodLoaded) name:LSTTPodLoadedNotification object:nil];
    [nc addObserver:self selector:@selector(gecimeLoaded) name:LSGeCiMeLoadedNotification object:nil];
    if ([defaults boolForKey:LSAutofillAndSearchWhenLaunched]) {
        [self autofillSongTitleAndArtist:nil];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // delete all temp files.
    NSString *dir=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *tempDir=[dir stringByAppendingPathComponent:@"LrcSeeker"];
    [[NSFileManager defaultManager] removeItemAtPath:tempDir error:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return [defaults boolForKey:LSQuitWhenClosed];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [[self window] setIsVisible:YES];
    return YES;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "Eru.LrcSeeker" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"Eru.LrcSeeker"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LrcSeeker" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

#pragma mark - NSTableViewDelegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [songs count];
}

-(id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    SongInfos *info=[songs objectAtIndex:row];
    return [info valueForKey:[tableColumn identifier]];
}

-(void)tableViewSelectionDidChange:(NSNotification *) notification {
    [self changeArtwork];
    if ([[hudWindow window] isVisible]) {
        [self showLyricPreview:nil];
    }
}

#pragma mark - source Loaded

-(void) qianqianLoaded {
    NSArray *qianqianSongs = qianqian.currentSongs;
    if (qianqianSongs) {
        [songs addObjectsFromArray:qianqianSongs];
        dispatch_async(dispatch_get_main_queue(), ^{
            [songListView reloadData];
        });
    }
    
}

-(void) ttpodLoaded {
    SongInfos *info = ttpod.songInfos;
    if (info) {
        [songs addObject:info];
        dispatch_async(dispatch_get_main_queue(), ^{
            [songListView reloadData];
        });
    }
}

-(void) xiamiLoaded {
    NSArray *xiamiSongs = xiami.currentSongs;
    if (xiamiSongs) {
        [songs addObjectsFromArray:xiamiSongs];
        dispatch_async(dispatch_get_main_queue(), ^{
            [songListView reloadData];
        });
    }
}

-(void) gecimeLoaded {
    NSArray *gecimeSongs = geciMe.currentSongs;
    if (gecimeSongs) {
        [songs addObjectsFromArray:gecimeSongs];
        dispatch_async(dispatch_get_main_queue(), ^{
            [songListView reloadData];
        });
    }
}

#pragma mark - handle Error

-(void)handleError:(NSNotification *)notification {
    NSString *errorString=[[notification userInfo] objectForKey:ErrorOccuredNotification];
    if (![errorWindow isVisible]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayErrorWindowWithString:errorString];
        });
    }
}

#pragma mark - Interface Method

- (IBAction)sendLrcToLyricsX:(id)sender {
    NSInteger row=[songListView selectedRow];
    if (row==-1 || row>[songs count]-1) {
        return;
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    SongInfos *info=[songs objectAtIndex:row];
    NSString *lrcURLStr=[info lyricURL];
    if ([lrcURLStr isEqualToString:@""] || lrcURLStr==nil) {
        if (![info lyric]) {
            NSLog(@"AppDelegate:no lrc available");
            [self displayErrorWindowWithString:NSLocalizedString(@"NO_LRC_ERROR", nil)];
            return;
        } else {
            [userInfo setObject:info.lyric forKey:@"LyricsContents"];
        }
    } else {
        NSString *lyricsContents = [NSString stringWithContentsOfURL:[NSURL URLWithString:lrcURLStr] encoding:NSUTF8StringEncoding error:nil];
        if (lyricsContents == nil) {
            NSLog(@"Nil lrc");
            return;
        }
        [userInfo setObject:lyricsContents forKey:@"LyricsContents"];
    }
    [userInfo setObject:info.songTitle forKey:@"SongTitle"];
    [userInfo setObject:info.artist forKey:@"Artist"];
    [userInfo setObject:@"LrcSeeker" forKey:@"Sender"];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ExtenalLyricsEvent" object:nil userInfo:userInfo deliverImmediately:true];
    NSLog(@"Sended Notification to LyricsX");
}

-(IBAction)searchLyrics:(id)sender {
    [songs removeAllObjects];
    [songListView reloadData];
    [albumView noSelectionImage];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [qianqian getLyricsWithTitle:convertToSC([songTileTextField stringValue]) artist:convertToSC([artistTextField stringValue])];
        [xiami getLyricsWithTitle:[songTileTextField stringValue] artist:[artistTextField stringValue]];
        [geciMe getLyricsWithTitle:[songTileTextField stringValue] artist:[artistTextField stringValue]];
        [ttpod getLyricsWithTitle:[songTileTextField stringValue] artist:[artistTextField stringValue]];
    });
}

-(IBAction)downloadLyrics:(id)sender {
    NSInteger row=[songListView selectedRow];
    if (row==-1 || row>[songs count]-1) {
        return;
    }
    SongInfos *info=[songs objectAtIndex:row];
    NSString *lrcURLStr=[info lyricURL];
    if ([lrcURLStr isEqualToString:@""] || lrcURLStr==nil) {
        if (![info lyric]) {
            NSLog(@"AppDelegate:no lrc available");
            [self displayErrorWindowWithString:NSLocalizedString(@"NO_LRC_ERROR", nil)];
            return;
        }
    }
    
    NSString *lrcDownloadDirectory = [defaults stringForKey:LSLrcPath];
    NSFileManager *theManager=[NSFileManager defaultManager];
    if ([lrcDownloadDirectory isEqualToString:@""]) {
        __block NSSavePanel *panel=[NSSavePanel savePanel];
        [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"lrc", @"txt", nil]];
        NSString *defaultName=[NSString stringWithFormat:@"%@ - %@.lrc",[info songTitle],[info artist]];
        defaultName = [defaultName stringByReplacingOccurrencesOfString:@"/" withString:@"&"];
        [panel setExtensionHidden:NO];
        [panel setNameFieldStringValue:defaultName];
        NSText *editor=[panel fieldEditor:NO forObject:nil];
        [editor setSelectedRange:NSMakeRange(0, [defaultName length]-4)];
        NSString *desktop=[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
        [panel setDirectoryURL:[NSURL fileURLWithPath:desktop]];
        [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result==NSModalResponseOK) {
                NSURL *newFileURL=[panel URL];
                NSLog(@"AppDelegate:About to download lrc to %@",newFileURL);
                if ([info lyric]) {
                    if ([defaults boolForKey:LSWhetherConvertChinese]) {
                        NSString *convertedLyrics = [self convertLyricsChineseType:info.lyric];
                        [convertedLyrics writeToURL:newFileURL atomically:NO encoding:NSUTF8StringEncoding error:nil];
                    } else {
                        [info.lyric writeToURL:newFileURL atomically:NO encoding:NSUTF8StringEncoding error:nil];
                    }
                }
                else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *lyricsStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:lrcURLStr] encoding:NSUTF8StringEncoding error:nil];
                        if ([defaults boolForKey:LSWhetherConvertChinese]) {
                            NSString *convertedLyrics = [self convertLyricsChineseType:lyricsStr];
                            [convertedLyrics writeToURL:newFileURL atomically:NO encoding:NSUTF8StringEncoding error:nil];
                        } else {
                            [lyricsStr writeToURL:newFileURL atomically:NO encoding:NSUTF8StringEncoding error:nil];
                        }
                    });
                }
            }
            else {
                NSLog(@"AppDelegate:User Canceled Download");
            }
            panel=nil;
        }];
        return;
    }
    else {
        BOOL hasDic;
        BOOL isDic;
        hasDic=[theManager fileExistsAtPath:lrcDownloadDirectory isDirectory:&isDic];
        if (!hasDic) {
            NSLog(@"AppDelegate:Lrc download direcory not exists,Creating.");
            [theManager createDirectoryAtPath:lrcDownloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        else if (!isDic) {
            NSLog(@"AppDelegate:Lrc download path is NOT a dictory!");
            [self displayErrorWindowWithString:NSLocalizedString(@"PATH_IS_NOT_DIC", nil)];
            return;
        }
        NSString *fileName = [[NSString stringWithFormat:@"%@ - %@.lrc",[info songTitle],[info artist]] stringByReplacingOccurrencesOfString:@"/" withString:@"&"];
        NSString *newFileLocation = [lrcDownloadDirectory stringByAppendingPathComponent:fileName];
        if ([theManager fileExistsAtPath: newFileLocation]) {
            int suffix=0;
            do {
                suffix++;
                fileName = [[NSString stringWithFormat:@"%@ - %@ %d.lrc",[info songTitle],[info artist],suffix] stringByReplacingOccurrencesOfString:@"/" withString:@"&"];
                newFileLocation=[lrcDownloadDirectory stringByAppendingPathComponent:fileName];
            } while([theManager fileExistsAtPath: newFileLocation]);
        }
        NSLog(@"AppDelegate:About to download lrc to %@",newFileLocation);
        if ([info lyric]) {
            if ([defaults boolForKey:LSWhetherConvertChinese]) {
                NSString *convertedLyrics = [self convertLyricsChineseType:info.lyric];
                [convertedLyrics writeToFile:newFileLocation atomically:NO encoding:NSUTF8StringEncoding error:nil];
            } else {
                [info.lyric writeToFile:newFileLocation atomically:NO encoding:NSUTF8StringEncoding error:nil];
            }
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *lyricsStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:lrcURLStr] encoding:NSUTF8StringEncoding error:nil];
                if ([defaults boolForKey:LSWhetherConvertChinese]) {
                    NSString *convertedLyrics = [self convertLyricsChineseType:lyricsStr];
                    [convertedLyrics writeToFile:newFileLocation atomically:NO encoding:NSUTF8StringEncoding error:nil];
                } else {
                    [lyricsStr writeToFile:newFileLocation atomically:NO encoding:NSUTF8StringEncoding error:nil];
                }
            });
        }
    }
}

-(IBAction)autofillSongTitleAndArtist:(id)sender{
    @autoreleasepool {
        if ([iTunes isRunning]) {
            if ([[iTunes currentTrack] name]==nil) {
                NSLog(@"AppDelegate:iTunes is not playing now.");
                [self displayErrorWindowWithString:NSLocalizedString(@"ITUNES_NOT_PLAYING", nil)];
            }
            else {
                NSLog(@"AppDelegate:Getting song title and artist form iTunes");
                [songTileTextField setStringValue:[[iTunes currentTrack] name]];
                [artistTextField setStringValue:[[iTunes currentTrack] artist]];
                [self searchLyrics:nil];
            }
        }
        else {
            NSLog(@"AppDelegate:iTunes is not running, fail to fill blanks.");
            [self displayErrorWindowWithString:NSLocalizedString(@"ITUNES_NOT_RUNNING", nil)];
        }
    }
}

-(IBAction)showPreferences:(id)sender {
    if (!preferencesWindow) {
        NSLog(@"AppDelegate:Create preferences window");
        preferencesWindow=[[PreferencesController alloc] init];
    }
    [preferencesWindow showWindow:self];
}

-(IBAction)downloadArtwork:(id)sender {
    NSString *artworkTempPath=[albumView artworkTempPath];
    NSString *artworkName=[albumView artworkName];
    NSData *artworkData=[albumView artworkData];
    NSString *artworkDownloadDirectory = [defaults stringForKey:LSArtworkPath];
    NSString *nameExtension=[artworkTempPath pathExtension];
    NSString *defaultName;
    if ([nameExtension length]==0) {
        defaultName=artworkName;
    }
    else {
        defaultName=[NSString stringWithFormat:@"%@.%@",artworkName,nameExtension];
    }
    if ([artworkDownloadDirectory isEqualToString:@""]) {
        __block NSSavePanel *panel=[NSSavePanel savePanel];
        NSString *desktop=[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
        [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"jpg",@"jpf",@"bmp",@"gif",@"tiff",nil]];
        [panel setDirectoryURL:[NSURL fileURLWithPath:desktop]];
        [panel setNameFieldStringValue:defaultName];
        [panel setExtensionHidden:NO];
        NSText *editor=[panel fieldEditor:NO forObject:nil];
        if ([nameExtension length]==0) {
            [editor setSelectedRange:NSMakeRange(0, [defaultName length])];
        }
        else {
            [editor setSelectedRange:NSMakeRange(0, [defaultName length]-[nameExtension length]-1)];
        }
        [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result==NSModalResponseOK) {
                NSLog(@"AlbumView:About to download artwrok to %@",[panel URL]);
                NSFileManager *fm=[NSFileManager defaultManager];
                if ([fm fileExistsAtPath:artworkTempPath isDirectory:nil]) {
                    [fm copyItemAtPath:artworkTempPath toPath:[[panel URL] path]  error:nil];
                }
                else {
                    [artworkData writeToURL:[panel URL] atomically:NO];
                }
            }
            else {
                NSLog(@"AlbumView:User Canceled Download");
            }
            panel=nil;
        }];
    }
    else {
        NSLog(@"artworkDownloadDictory:%@",artworkDownloadDirectory);
        BOOL hasDic;
        BOOL isDic;
        NSFileManager *fm=[NSFileManager defaultManager];
        hasDic=[fm fileExistsAtPath:artworkDownloadDirectory isDirectory:&isDic];
        if (!hasDic) {
            NSLog(@"AlbumView:Artwork download direcory not exists,Creating.");
            [fm createDirectoryAtPath:artworkDownloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        else if (!isDic) {
            NSLog(@"AlbumView:Artwork download path is NOT a dictory!");
            [self displayErrorWindowWithString:NSLocalizedString(@"PATH_IS_NOT_DIC", nil)];
            return;
        }
        NSString *newFileLocation = [artworkDownloadDirectory stringByAppendingPathComponent:defaultName];
        if ([fm fileExistsAtPath: newFileLocation]) {
            int suffix=0;
            do {
                suffix++;
                newFileLocation=[artworkDownloadDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d.%@",[defaultName stringByDeletingPathExtension],suffix,nameExtension]];
            } while([fm fileExistsAtPath: newFileLocation]);
        }
        NSLog(@"AlbumView:About to download artwork to %@",newFileLocation);
        if ([fm fileExistsAtPath:artworkTempPath isDirectory:nil]) {
            [[NSFileManager defaultManager] copyItemAtPath:artworkTempPath toPath:newFileLocation  error:nil];
        }
        else {
            [artworkData writeToFile:newFileLocation atomically:NO];
        }
    }
}

-(IBAction)checkForUpdate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/MichaelRow/LrcSeeker/releases"]];
}

-(IBAction)showLyricPreview:(id)sender {
    if (!hudWindow) {
        hudWindow=[[HUDController alloc] init];
    }
    if ([songListView selectedRow]==-1 || [songListView selectedRow]>[songs count]) {
        if (![[hudWindow window] isVisible]) {
            return;
        }
        [hudWindow showWindow:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[hudWindow textView] setString:NSLocalizedString(@"NO_SONG_SELECTED", nil)];
        });
        return;
    }
    else {
        if (![[hudWindow window]isVisible]) {
            [hudWindow showWindow:nil];
            [[self window] makeKeyAndOrderFront:nil];
        }
        SongInfos *info=[songs objectAtIndex:[songListView selectedRow]];
        if (info.lyric!=nil) {
            NSString *finalLyrics = info.lyric;
            if ([defaults boolForKey:LSLyricStyle]) {
                finalLyrics = [self optimizedLyric:finalLyrics];
            }
            if ([defaults boolForKey:LSWhetherConvertChinese]) {
                finalLyrics = [self convertLyricsChineseType:finalLyrics];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[hudWindow textView] setString:finalLyrics];
            });
            return;
        }
        else {
            if (info.lyricURL==nil || [info.lyricURL isEqualToString:@""]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[hudWindow textView] setString:NSLocalizedString(@"NO_LRC_AVAILABLE", nil)];
                });
                return;
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *finalLyrics = [NSString stringWithContentsOfURL:[NSURL URLWithString:info.lyricURL] encoding:NSUTF8StringEncoding error:nil];
                    if ([defaults boolForKey:LSLyricStyle]) {
                        finalLyrics = [self optimizedLyric:finalLyrics];
                    }
                    if ([defaults boolForKey:LSWhetherConvertChinese]) {
                        finalLyrics = [self convertLyricsChineseType:finalLyrics];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[hudWindow textView] setString:finalLyrics];
                    });
                });
                return;
            }
        }
    }
}

-(IBAction)fillInArtwork:(id)sender {
    @autoreleasepool {
        NSInteger selectedRow = [songListView selectedRow];
        if (selectedRow == -1 || selectedRow > songs.count) {
            [self displayErrorWindowWithString:NSLocalizedString(@"NO_SELECTION", nil)];
            return;
        }
        NSString *artworkURLString=[[songs objectAtIndex:selectedRow] artWorkURL];
        if (artworkURLString==nil || [artworkURLString isEqualToString:@""]) {
            [self displayErrorWindowWithString:NSLocalizedString(@"NO_ARTWORK_AVAILABLE", nil)];
            return;
        }
        if ([iTunes isRunning] && [[iTunes currentTrack] name]!=nil) {
            if (!artworkFiller) {
                artworkFiller=[[ArtworkFiller alloc] init];
                [artworkFiller showWindow:self];
                [[artworkFiller window] orderOut:self];
            }
            [artworkFiller setNewArtworkWithData:[albumView artworkData] artworkImage:[albumView artwork] name:[albumView artworkName] andTempPath:[albumView artworkTempPath]];
            [artworkFiller setTheITunesArtwork];
            [[self window] beginSheet:[artworkFiller window] completionHandler:nil];
        }
    }
}

-(void)changeArtwork{
    NSLog(@"Start to change artwork");
    NSInteger row=[songListView selectedRow];
    if (row==-1 || row>[songs count]-1) {
        NSLog(@"No selection");
        [albumView noSelectionImage];
        return;
    }
    NSLog(@"Selected row is %ld",row);
    NSString *artworkURLStr=[[songs objectAtIndex:row] artWorkURL];
    NSString *artworkName=[[songs objectAtIndex:row] songTitle];
    if ([artworkURLStr isEqualToString:@""] || artworkURLStr==nil) {
        [albumView noFoundImage];
        return;
    }
    NSURL *artworkURL=[NSURL URLWithString:artworkURLStr];
    NSLog(@"Album URL is %@",artworkURL);
    [albumView setArtWorkWithURL:artworkURL andArtworkName:artworkName];
}

-(void)displayErrorWindowWithString:(NSString *)errorStr {
    [errorWindow setStringValue:errorStr];
    NSRect mainFrame=[[self window] frame];
    NSRect errorWindowFrame=[errorWindow frame];
    NSPoint point;
    point.x=mainFrame.origin.x+(mainFrame.size.width-errorWindowFrame.size.width)/2;
    point.y=mainFrame.origin.y+(mainFrame.size.height-errorWindowFrame.size.height)/2;
    [errorWindow setFrameOrigin:point];
    [errorWindow fadeInAndMakeKeyAndOrderFront:YES];
    [[self window] addChildWindow:errorWindow ordered:NSWindowAbove];
    timer=[NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(hideErrorWindow) userInfo:nil repeats:NO];
}

-(void)hideErrorWindow {
    [timer invalidate];
    timer=nil;
    [errorWindow fadeOutAndOrderOut:YES];
    [[self window] removeChildWindow:errorWindow];
}

#pragma mark - Oter Methods

-(NSString *)convertLyricsChineseType: (NSString *)inputLyrics {
    NSLog(@"Starting to convert Chinese...");
    NSInteger index=[defaults integerForKey:LSChineseConvertTpye];
    NSString *convertedLrc;
    switch (index) {
        case 0:
            convertedLrc=convertToSC(inputLyrics);
            break;
            
        case 1:
            convertedLrc=convertToTC(inputLyrics);
            break;
            
        case 2:
            convertedLrc=convertToTCTW(inputLyrics);
            break;
            
        case 3:
            convertedLrc=convertToTCHK(inputLyrics);
            break;
            
        default:
            break;
    }
    return convertedLrc;
}

-(NSString *)optimizedLyric:(NSString *) inputLyrics {
    NSCharacterSet *newLineCharSet=[NSCharacterSet newlineCharacterSet];
    NSArray *lrcParagraphs=[inputLyrics componentsSeparatedByCharactersInSet:newLineCharSet];
    NSRegularExpression *regexForTimeTags=[NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+:[0-9]+.[0-9]+\\]|\\[[0-9]+:[0-9]+\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *regexForIDTags=[NSRegularExpression regularExpressionWithPattern:@"\\[.*:.*\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableArray *resultLrcParagraphs=[[NSMutableArray alloc] init];
    for (NSString *string in lrcParagraphs) {
        NSArray *timeTagsMatched = [regexForTimeTags matchesInString:string
                                                             options:0
                                                               range:NSMakeRange(0, [string length])];
        if ([timeTagsMatched count]>0) {
            NSInteger index=[[timeTagsMatched lastObject] range].location+[[timeTagsMatched lastObject] range].length;
            NSRange lyricLineRange=NSMakeRange(index, [string length]-index);
            NSString *lyricSentence=[string substringWithRange:lyricLineRange];
            for (NSTextCheckingResult *result in timeTagsMatched) {
                NSRange match=[result range];
                LrcLineModel *lrcLine=[[LrcLineModel alloc] init];
                [lrcLine setLyricSentence:lyricSentence];
                [lrcLine setTimeTag:[string substringWithRange:match]];
                NSInteger currentCount=[resultLrcParagraphs count];
                int j;
                for (j=0; j<currentCount; ++j) {
                    if ([[resultLrcParagraphs objectAtIndex:j] isKindOfClass:[LrcLineModel class]] && lrcLine.msecPosition<[[resultLrcParagraphs objectAtIndex:j] msecPosition]) {
                        [resultLrcParagraphs insertObject:lrcLine atIndex:j];
                        break;
                    }
                }
                if (j==currentCount) {
                    [resultLrcParagraphs addObject:lrcLine];
                }
            }
        }
        else {
            NSUInteger numberOfMatches = [regexForIDTags numberOfMatchesInString:string
                                                                         options:0
                                                                           range:NSMakeRange(0, [string length])];
            if (numberOfMatches>0) {
                continue;
            }
            else {
                [resultLrcParagraphs addObject:string];
            }
        }
    }
    NSMutableString *returnStr=[[NSMutableString alloc] initWithString:@""];
    for (int i=0; i<[resultLrcParagraphs count]; ++i) {
        if ([[resultLrcParagraphs objectAtIndex:i] isKindOfClass:[NSString class]]) {
            [returnStr appendString:[resultLrcParagraphs objectAtIndex:i]];
            if ([[resultLrcParagraphs objectAtIndex:i] isNotEqualTo:@""]) {
                [returnStr appendString:@"\n"];
            }
        }
        else {
            [returnStr appendString:[[resultLrcParagraphs objectAtIndex:i] lyricSentence]];
            [returnStr appendString:@"\n"];
        }
    }
    return returnStr;
}

#pragma mark - ContextMenuDelegate

- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows {
    [[self window] makeFirstResponder:songListView];
    return tableViewMenu;
}

#pragma mark - menu delegate

- (void)menuWillOpen:(NSMenu *)menu {
    NSInteger lyricsXCount = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"Eru.Lyrics"].count;
    NSLog(@"%ld",lyricsXCount);
    if (lyricsXCount > 0) {
        sendToLyricsXMenuItem.hidden = NO;
    } else {
        sendToLyricsXMenuItem.hidden = YES;
    }
}

@end
