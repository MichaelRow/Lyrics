
//
//  AppDelegate.swift
//  Lyrics
//
//  Created by Eru on 15/11/10.
//  Copyright © 2015年 Eru. All rights reserved.
//

import Cocoa
import ScriptingBridge

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> AnyObject!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
}

// MARK: iTunesEKnd
@objc public enum iTunesEKnd : AEKeyword {
    case TrackListing = 0x6b54726b /* 'kTrk' */
    case AlbumListing = 0x6b416c62 /* 'kAlb' */
    case CdInsert = 0x6b434469 /* 'kCDi' */
}

// MARK: iTunesEnum
@objc public enum iTunesEnum : AEKeyword {
    case Standard = 0x6c777374 /* 'lwst' */
    case Detailed = 0x6c776474 /* 'lwdt' */
}

// MARK: iTunesEPlS
@objc public enum iTunesEPlS : AEKeyword {
    case Stopped = 0x6b505353 /* 'kPSS' */
    case Playing = 0x6b505350 /* 'kPSP' */
    case Paused = 0x6b505370 /* 'kPSp' */
    case FastForwarding = 0x6b505346 /* 'kPSF' */
    case Rewinding = 0x6b505352 /* 'kPSR' */
}

// MARK: iTunesERpt
@objc public enum iTunesERpt : AEKeyword {
    case Off = 0x6b52704f /* 'kRpO' */
    case One = 0x6b527031 /* 'kRp1' */
    case All = 0x6b416c6c /* 'kAll' */
}

// MARK: iTunesEVSz
@objc public enum iTunesEVSz : AEKeyword {
    case Small = 0x6b565353 /* 'kVSS' */
    case Medium = 0x6b56534d /* 'kVSM' */
    case Large = 0x6b56534c /* 'kVSL' */
}

// MARK: iTunesESrc
@objc public enum iTunesESrc : AEKeyword {
    case Library = 0x6b4c6962 /* 'kLib' */
    case IPod = 0x6b506f64 /* 'kPod' */
    case AudioCD = 0x6b414344 /* 'kACD' */
    case MP3CD = 0x6b4d4344 /* 'kMCD' */
    case RadioTuner = 0x6b54756e /* 'kTun' */
    case SharedLibrary = 0x6b536864 /* 'kShd' */
    case Unknown = 0x6b556e6b /* 'kUnk' */
}

// MARK: iTunesESrA
@objc public enum iTunesESrA : AEKeyword {
    case Albums = 0x6b53724c /* 'kSrL' */
    case All = 0x6b416c6c /* 'kAll' */
    case Artists = 0x6b537252 /* 'kSrR' */
    case Composers = 0x6b537243 /* 'kSrC' */
    case Displayed = 0x6b537256 /* 'kSrV' */
    case Songs = 0x6b537253 /* 'kSrS' */
}

// MARK: iTunesESpK
@objc public enum iTunesESpK : AEKeyword {
    case None = 0x6b4e6f6e /* 'kNon' */
    case Books = 0x6b537041 /* 'kSpA' */
    case Folder = 0x6b537046 /* 'kSpF' */
    case Genius = 0x6b537047 /* 'kSpG' */
    case ITunesU = 0x6b537055 /* 'kSpU' */
    case Library = 0x6b53704c /* 'kSpL' */
    case Movies = 0x6b537049 /* 'kSpI' */
    case Music = 0x6b53705a /* 'kSpZ' */
    case Podcasts = 0x6b537050 /* 'kSpP' */
    case PurchasedMusic = 0x6b53704d /* 'kSpM' */
    case TVShows = 0x6b537054 /* 'kSpT' */
}

// MARK: iTunesEVdK
@objc public enum iTunesEVdK : AEKeyword {
    case None = 0x6b4e6f6e /* 'kNon' */
    case HomeVideo = 0x6b566448 /* 'kVdH' */
    case Movie = 0x6b56644d /* 'kVdM' */
    case MusicVideo = 0x6b566456 /* 'kVdV' */
    case TVShow = 0x6b566454 /* 'kVdT' */
}

// MARK: iTunesERtK
@objc public enum iTunesERtK : AEKeyword {
    case User = 0x6b527455 /* 'kRtU' */
    case Computed = 0x6b527443 /* 'kRtC' */
}

// MARK: iTunesEAPD
@objc public enum iTunesEAPD : AEKeyword {
    case Computer = 0x6b415043 /* 'kAPC' */
    case AirPortExpress = 0x6b415058 /* 'kAPX' */
    case AppleTV = 0x6b415054 /* 'kAPT' */
    case AirPlayDevice = 0x6b41504f /* 'kAPO' */
    case Unknown = 0x6b415055 /* 'kAPU' */
}

// MARK: iTunesGenericMethods
@objc public protocol iTunesGenericMethods {
    optional func printPrintDialog(printDialog: Bool, withProperties: iTunesPrintSettings, kind: iTunesEKnd, theme: NSString) // Print the specified object(s)
    optional func close() // Close an object
    optional func delete() // Delete an element from an object
    optional func duplicateTo(to: SBObject) -> SBObject // Duplicate one or more object(s)
    optional func exists() -> Bool // Verify if an object exists
    optional func open() // open the specified object(s)
    optional func playOnce(once: Bool) // play the current track or the specified track or file.
}

// MARK: iTunesPrintSettings
@objc public protocol iTunesPrintSettings: SBObjectProtocol, iTunesGenericMethods {
    optional var copies: Int { get } // the number of copies of a document to be printed
    optional var collating: Bool { get } // Should printed copies be collated?
    optional var startingPage: Int { get } // the first page of the document to be printed
    optional var endingPage: Int { get } // the last page of the document to be printed
    optional var pagesAcross: Int { get } // number of logical pages laid across a physical page
    optional var pagesDown: Int { get } // number of logical pages laid out down a physical page
    optional var errorHandling: iTunesEnum { get } // how errors are handled
    optional var requestedPrintTime: NSDate { get } // the time at which the desktop printer should print the document
    optional var printerFeatures: NSArray { get } // printer specific options
    optional var faxNumber: NSString { get } // for fax number
    optional var targetPrinter: NSString { get } // for target printer
}
extension SBObject: iTunesPrintSettings {}

// MARK: iTunesApplication
@objc public protocol iTunesApplication: SBApplicationProtocol {
    optional func AirPlayDevices() -> SBElementArray
    optional func browserWindows() -> SBElementArray
    optional func encoders() -> SBElementArray
    optional func EQPresets() -> SBElementArray
    optional func EQWindows() -> SBElementArray
    optional func playlistWindows() -> SBElementArray
    optional func sources() -> SBElementArray
    optional func visuals() -> SBElementArray
    optional func windows() -> SBElementArray
    optional var AirPlayEnabled: Bool { get } // is AirPlay currently enabled?
    optional var converting: Bool { get } // is a track currently being converted?
    optional var currentEncoder: iTunesEncoder { get set } // the currently selected encoder (MP3, AIFF, WAV, etc.)
    optional var currentEQPreset: iTunesEQPreset { get set } // the currently selected equalizer preset
    optional var currentPlaylist: iTunesPlaylist { get } // the playlist containing the currently targeted track
    optional var currentStreamTitle: NSString { get } // the name of the current song in the playing stream (provided by streaming server)
    optional var currentStreamURL: NSString { get } // the URL of the playing stream or streaming web site (provided by streaming server)
    optional var currentTrack: iTunesTrack { get } // the current targeted track
    optional var currentVisual: iTunesVisual { get set } //  the currently selected visual plug-in
    optional var EQEnabled: Bool { get set } // is the equalizer enabled?
    optional var fixedIndexing: Bool { get set } // true if all AppleScript track indices should be independent of the play order of the owning playlist.
    optional var frontmost: Bool { get set } // is iTunes the frontmost application?
    optional var fullScreen: Bool { get set } // are visuals displayed using the entire screen?
    optional var name: NSString { get } // the name of the application
    optional var mute: Bool { get set } // has the sound output been muted?
    optional var playerPosition: Double { get set } // the player’s position within the currently playing track in seconds.
    optional var playerState: iTunesEPlS { get } // is iTunes stopped, paused, or playing?
    optional var selection: SBObject { get } // the selection visible to the user
    optional var soundVolume: Int { get set } // the sound output volume (0 = minimum, 100 = maximum)
    optional var version: NSString { get } // the version of iTunes
    optional var visualsEnabled: Bool { get set } // are visuals currently being displayed?
    optional var visualSize: iTunesEVSz { get set } // the size of the displayed visual
    optional var iAdIdentifier: NSString { get } // the iAd identifier
    optional func printPrintDialog(printDialog: Bool, withProperties: iTunesPrintSettings, kind: iTunesEKnd, theme: NSString) // Print the specified object(s)
    optional func run() // run iTunes
    optional func quit() // quit iTunes
    optional func add(x: NSArray, to: SBObject) -> iTunesTrack // add one or more files to a playlist
    optional func backTrack() // reposition to beginning of current track or go to previous track if already at start of current track
    optional func convert(x: NSArray) -> iTunesTrack // convert one or more files or tracks
    optional func fastForward() // skip forward in a playing track
    optional func nextTrack() // advance to the next track in the current playlist
    optional func pause() // pause playback
    optional func playOnce(once: Bool) // play the current track or the specified track or file.
    optional func playpause() // toggle the playing/paused state of the current track
    optional func previousTrack() // return to the previous track in the current playlist
    optional func resume() // disable fast forward/rewind and resume playback, if playing.
    optional func rewind() // skip backwards in a playing track
    optional func stop() // stop playback
    optional func update() // update the specified iPod
    optional func eject() // eject the specified iPod
    optional func subscribe(x: NSString) // subscribe to a podcast feed
    optional func updateAllPodcasts() // update all subscribed podcast feeds
    optional func updatePodcast() // update podcast feed
    optional func openLocation(x: NSString) // Opens a Music Store or audio stream URL
}
extension SBApplication: iTunesApplication {}

// MARK: iTunesItem
@objc public protocol iTunesItem: SBObjectProtocol, iTunesGenericMethods {
    optional var container: Int { get } // the container of the item
    optional func id() // the id of the item
    optional var index: Int { get } // The index of the item in internal application order.
    optional var name: NSString { get set } // the name of the item
    optional var persistentID: NSString { get } // the id of the item as a hexadecimal string. This id does not change over time.
    optional var properties: NSDictionary { get set } // every property of the item
    optional func reveal() // reveal and select a track or playlist
}
extension SBObject: iTunesItem {}

// MARK: iTunesAirPlayDevice
@objc public protocol iTunesAirPlayDevice: iTunesItem {
    optional var active: Bool { get } // is the device currently being played to?
    optional var available: Bool { get } // is the device currently available?
    optional var kind: iTunesEAPD { get } // the kind of the device
    optional var networkAddress: NSString { get } // the network (MAC) address of the device
    optional func protected()->Bool // is the device password- or passcode-protected?
    optional var selected: Bool { get set } // is the device currently selected?
    optional var supportsAudio: Bool { get } // does the device support audio playback?
    optional var supportsVideo: Bool { get } // does the device support video playback?
    optional var soundVolume: Int { get set } // the output volume for the device (0 = minimum, 100 = maximum)
}
extension SBObject: iTunesAirPlayDevice {}

// MARK: iTunesArtwork
@objc public protocol iTunesArtwork: iTunesItem {
    optional var data: NSImage { get set } // data for this artwork, in the form of a picture
    optional var objectDescription: NSString { get set } // description of artwork as a string
    optional var downloaded: Bool { get } // was this artwork downloaded by iTunes?
    optional var format: NSNumber { get } // the data format for this piece of artwork
    optional var kind: Int { get set } // kind or purpose of this piece of artwork
    optional var rawData: NSData { get set } // data for this artwork, in original format
}
extension SBObject: iTunesArtwork {}

// MARK: iTunesEncoder
@objc public protocol iTunesEncoder: iTunesItem {
    optional var format: NSString { get } // the data format created by the encoder
}
extension SBObject: iTunesEncoder {}

// MARK: iTunesEQPreset
@objc public protocol iTunesEQPreset: iTunesItem {
    optional var band1: Double { get set } // the equalizer 32 Hz band level (-12.0 dB to +12.0 dB)
    optional var band2: Double { get set } // the equalizer 64 Hz band level (-12.0 dB to +12.0 dB)
    optional var band3: Double { get set } // the equalizer 125 Hz band level (-12.0 dB to +12.0 dB)
    optional var band4: Double { get set } // the equalizer 250 Hz band level (-12.0 dB to +12.0 dB)
    optional var band5: Double { get set } // the equalizer 500 Hz band level (-12.0 dB to +12.0 dB)
    optional var band6: Double { get set } // the equalizer 1 kHz band level (-12.0 dB to +12.0 dB)
    optional var band7: Double { get set } // the equalizer 2 kHz band level (-12.0 dB to +12.0 dB)
    optional var band8: Double { get set } // the equalizer 4 kHz band level (-12.0 dB to +12.0 dB)
    optional var band9: Double { get set } // the equalizer 8 kHz band level (-12.0 dB to +12.0 dB)
    optional var band10: Double { get set } // the equalizer 16 kHz band level (-12.0 dB to +12.0 dB)
    optional var modifiable: Bool { get } // can this preset be modified?
    optional var preamp: Double { get set } // the equalizer preamp level (-12.0 dB to +12.0 dB)
    optional var updateTracks: Bool { get set } // should tracks which refer to this preset be updated when the preset is renamed or deleted?
}
extension SBObject: iTunesEQPreset {}

// MARK: iTunesPlaylist
@objc public protocol iTunesPlaylist: iTunesItem {
    optional func tracks()
    optional var duration: Int { get } // the total length of all songs (in seconds)
    optional var name: NSString { get set } // the name of the playlist
    optional var loved: Bool { get set } // is this playlist loved?
    optional var parent: iTunesPlaylist { get } // folder which contains this playlist (if any)
    optional var shuffle: Bool { get set } // play the songs in this playlist in random order?
    optional var size: Int { get } // the total size of all songs (in bytes)
    optional var songRepeat: iTunesERpt { get set } // playback repeat mode
    optional var specialKind: iTunesESpK { get } // special playlist kind
    optional var time: NSString { get } // the length of all songs in MM:SS format
    optional var visible: Bool { get } // is this playlist visible in the Source list?
    optional func moveTo(to: SBObject) // Move playlist(s) to a new location
    optional func searchFor(for_: NSString, only: iTunesESrA) -> iTunesTrack // search a playlist for tracks matching the search string. Identical to entering search text in the Search field in iTunes.
}
extension SBObject: iTunesPlaylist {}

// MARK: iTunesAudioCDPlaylist
@objc public protocol iTunesAudioCDPlaylist: iTunesPlaylist {
    optional func audioCDTracks()->SBElementArray
    optional var artist: NSString { get set } // the artist of the CD
    optional var compilation: Bool { get set } // is this CD a compilation album?
    optional var composer: NSString { get set } // the composer of the CD
    optional var discCount: Int { get set } // the total number of discs in this CD’s album
    optional var discNumber: Int { get set } // the index of this CD disc in the source album
    optional var genre: NSString { get set } // the genre of the CD
    optional var year: Int { get set } // the year the album was recorded/released
}
extension SBObject: iTunesAudioCDPlaylist {}

// MARK: iTunesLibraryPlaylist
@objc public protocol iTunesLibraryPlaylist: iTunesPlaylist {
    optional func fileTracks() -> SBElementArray
    optional func URLTracks() -> SBElementArray
    optional func sharedTracks() -> SBElementArray
}
extension SBObject: iTunesLibraryPlaylist {}

// MARK: iTunesRadioTunerPlaylist
@objc public protocol iTunesRadioTunerPlaylist: iTunesPlaylist {
    optional func URLTracks() -> SBElementArray
}
extension SBObject: iTunesRadioTunerPlaylist {}

// MARK: iTunesSource
@objc public protocol iTunesSource: iTunesItem {
    optional func audioCDPlaylists() -> SBElementArray
    optional func libraryPlaylists() -> SBElementArray
    optional func playlists() -> SBElementArray
    optional func radioTunerPlaylists() -> SBElementArray
    optional func userPlaylists() -> SBElementArray
    optional var capacity: Int64 { get } // the total size of the source if it has a fixed size
    optional var freeSpace: Int64 { get } // the free space on the source if it has a fixed size
    optional var kind: iTunesESrc { get }
    optional func update() // update the specified iPod
    optional func eject() // eject the specified iPod
}
extension SBObject: iTunesSource {}

// MARK: iTunesTrack
@objc public protocol iTunesTrack: iTunesItem {
    optional func artworks()
    optional var album: NSString { get set } // the album name of the track
    optional var albumArtist: NSString { get set } // the album artist of the track
    optional var albumLoved: Bool { get set } // is the album for this track loved?
    optional var albumRating: Int { get set } // the rating of the album for this track (0 to 100)
    optional var albumRatingKind: iTunesERtK { get } // the rating kind of the album rating for this track
    optional var artist: NSString { get set } // the artist/source of the track
    optional var bitRate: Int { get } // the bit rate of the track (in kbps)
    optional var bookmark: Double { get set } // the bookmark time of the track in seconds
    optional var bookmarkable: Bool { get set } // is the playback position for this track remembered?
    optional var bpm: Int { get set } // the tempo of this track in beats per minute
    optional var category: NSString { get set } // the category of the track
    optional var comment: NSString { get set } // freeform notes about the track
    optional var compilation: Bool { get set } // is this track from a compilation album?
    optional var composer: NSString { get set } // the composer of the track
    optional var databaseID: Int { get } // the common, unique ID for this track. If two tracks in different playlists have the same database ID, they are sharing the same data.
    optional var dateAdded: NSDate { get } // the date the track was added to the playlist
    optional var objectDescription: NSString { get set } // the description of the track
    optional var discCount: Int { get set } // the total number of discs in the source album
    optional var discNumber: Int { get set } // the index of the disc containing this track on the source album
    optional var duration: Double { get } // the length of the track in seconds
    optional var enabled: Bool { get set } // is this track checked for playback?
    optional var episodeID: NSString { get set } // the episode ID of the track
    optional var episodeNumber: Int { get set } // the episode number of the track
    optional var EQ: NSString { get set } // the name of the EQ preset of the track
    optional var finish: Double { get set } // the stop time of the track in seconds
    optional var gapless: Bool { get set } // is this track from a gapless album?
    optional var genre: NSString { get set } // the music/audio genre (category) of the track
    optional var grouping: NSString { get set } // the grouping (piece) of the track. Generally used to denote movements within a classical work.
    optional var iTunesU: Bool { get } // is this track an iTunes U episode?
    optional var kind: NSString { get } // a text description of the track
    optional var longDescription: NSString { get set }
    optional var loved: Bool { get set } // is this track loved?
    optional var lyrics: NSString { get set } // the lyrics of the track
    optional var modificationDate: NSDate { get } // the modification date of the content of this track
    optional var playedCount: Int { get set } // number of times this track has been played
    optional var playedDate: NSDate { get set } // the date and time this track was last played
    optional var podcast: Bool { get } // is this track a podcast episode?
    optional var rating: Int { get set } // the rating of this track (0 to 100)
    optional var ratingKind: iTunesERtK { get } // the rating kind of this track
    optional var releaseDate: NSDate { get } // the release date of this track
    optional var sampleRate: Int { get } // the sample rate of the track (in Hz)
    optional var seasonNumber: Int { get set } // the season number of the track
    optional var shufflable: Bool { get set } // is this track included when shuffling?
    optional var skippedCount: Int { get set } // number of times this track has been skipped
    optional var skippedDate: NSDate { get set } // the date and time this track was last skipped
    optional var show: NSString { get set } // the show name of the track
    optional var sortAlbum: NSString { get set } // override string to use for the track when sorting by album
    optional var sortArtist: NSString { get set } // override string to use for the track when sorting by artist
    optional var sortAlbumArtist: NSString { get set } // override string to use for the track when sorting by album artist
    optional var sortName: NSString { get set } // override string to use for the track when sorting by name
    optional var sortComposer: NSString { get set } // override string to use for the track when sorting by composer
    optional var sortShow: NSString { get set } // override string to use for the track when sorting by show name
    optional var size: Int64 { get } // the size of the track (in bytes)
    optional var start: Double { get set } // the start time of the track in seconds
    optional var time: NSString { get } // the length of the track in MM:SS format
    optional var trackCount: Int { get set } // the total number of tracks on the source album
    optional var trackNumber: Int { get set } // the index of the track on the source album
    optional var unplayed: Bool { get set } // is this track unplayed?
    optional var videoKind: iTunesEVdK { get set } // kind of video track
    optional var volumeAdjustment: Int { get set } // relative volume adjustment of the track (-100% to 100%)
    optional var year: Int { get set } // the year the track was recorded/released
}
extension SBObject: iTunesTrack {}

// MARK: iTunesAudioCDTrack
@objc public protocol iTunesAudioCDTrack: iTunesTrack {
    optional var location: NSURL { get } // the location of the file represented by this track
}
extension SBObject: iTunesAudioCDTrack {}

// MARK: iTunesFileTrack
@objc public protocol iTunesFileTrack: iTunesTrack {
    optional var location: NSURL { get set } // the location of the file represented by this track
    optional func refresh() // update file track information from the current information in the track’s file
}
extension SBObject: iTunesFileTrack {}

// MARK: iTunesSharedTrack
@objc public protocol iTunesSharedTrack: iTunesTrack {
}
extension SBObject: iTunesSharedTrack {}

// MARK: iTunesURLTrack
@objc public protocol iTunesURLTrack: iTunesTrack {
    optional var address: NSString { get set } // the URL for this track
    optional func download() // download podcast episode
}
extension SBObject: iTunesURLTrack {}

// MARK: iTunesUserPlaylist
@objc public protocol iTunesUserPlaylist: iTunesPlaylist {
    optional func fileTracks() -> SBElementArray
    optional func URLTracks() -> SBElementArray
    optional func sharedTracks() -> SBElementArray
    optional var shared: Bool {get set} // is this playlist shared?
    optional var smart: Bool { get } // is this a Smart Playlist?
    optional var genius: Bool { get } // is this a Genius Playlist?
}
extension SBObject: iTunesUserPlaylist {}

// MARK: iTunesFolderPlaylist
@objc public protocol iTunesFolderPlaylist: iTunesUserPlaylist {
}
extension SBObject: iTunesFolderPlaylist {}

// MARK: iTunesVisual
@objc public protocol iTunesVisual: iTunesItem {
}
extension SBObject: iTunesVisual {}

// MARK: iTunesWindow
@objc public protocol iTunesWindow: iTunesItem {
    optional var bounds: NSRect { get set } // the boundary rectangle for the window
    optional var closeable: Bool { get } // does the window have a close box?
    optional var collapseable: Bool { get } // does the window have a collapse (windowshade) box?
    optional var collapsed: Bool { get set } // is the window collapsed?
    optional var position: NSPoint { get set } // the upper left position of the window
    optional var resizable: Bool { get } // is the window resizable?
    optional var visible: Bool { get set } // is the window visible?
    optional var zoomable: Bool { get } // is the window zoomable?
    optional var zoomed: Bool { get set } // is the window zoomed?
}
extension SBObject: iTunesWindow {}

// MARK: iTunesBrowserWindow
@objc public protocol iTunesBrowserWindow: iTunesWindow {
    optional var minimized: Bool { get set } // is the small player visible?
    optional var selection: SBObject { get } // the selected songs
    optional var view: iTunesPlaylist { get set } // the playlist currently displayed in the window
}
extension SBObject: iTunesBrowserWindow {}

// MARK: iTunesEQWindow
@objc public protocol iTunesEQWindow: iTunesWindow {
    optional var minimized: Bool { get set } // is the small EQ window visible?
}
extension SBObject: iTunesEQWindow {}

// MARK: iTunesPlaylistWindow
@objc public protocol iTunesPlaylistWindow: iTunesWindow {
    optional var selection: SBObject { get } // the selected songs
    optional var view: iTunesPlaylist { get } // the playlist displayed in the window
}
extension SBObject: iTunesPlaylistWindow {}

