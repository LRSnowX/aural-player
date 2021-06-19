#  What's New in Version 3.1.0

## Remote Control

*Remote Control* is the ability of Aural Player to be controlled from outside the application, for example, from the macOS Control Center (available in Big Sur) or by Apple accessories (eg. headphones) or 3rd party apps that are able to send ***MPRemoteCommand*** audio commands to macOS. 

Controllable functions: 

 * Play / pause
 * Stop
 * Previous / next track
 * Skip forward / backward
 * Seek to an arbitrary playback position
 
 **NOTE** - This feature is available starting with **macOS 10.12.2**.   
 
 ## Now Playing Info

 When Remote Control is enabled, current audio information will be displayed within the "Now Playing" section of the macOS Control Center and/or the associated player widget that attaches to the menu bar. This includes the currently playing track's title, artist, album, cover art, duration, and playback position.
 
 **NOTE** - Track cover art display is available starting with **macOS 10.13.2**.
 
 ### Remote Control and menu bar mode
 
 Remote Control's capabilities are roughly comparable to that of Aural Player running in menu bar mode, although menu bar mode does provide some extra functions such as volume control, repeat, shuffle, segment looping, etc, and is more reliable.
 
 Note that when running Aural Player in menu bar mode, it will *not* be able to receive Remote Control commands. Now Playing info (in Control Center) will still be displayed but the playback controls will not be functional.
 
### Remote Control and media keys

An advantage of the Remote Control feature is that, when enabled, media keys don't require OS-level Accessibility permissions in order to function. They should work by default out-of-the-box, once Aural Player becomes the "Now Playable" app and shows up in the "Now Playing" section of the Control Center (i.e. once playback is started).

If you do *not* grant Accessibility permissions to Aural Player, the behavior of the media keys will be dictated by which controls are enabled by Remote Control (i.e. track changes or seeking). Remote Control preferences will take precedence over media keys preferences.

If you do grant Accessibility permissions to Aural Player, the behavior of the media keys will be dictated by Aural Player's media keys preferences.

### macOS Control Center is unreliable and buggy

The macOS Control Center is generally unreliable and buggy, and the following issues may occur sporadically:

* Track cover art disappears when pausing / resuming a track. Closing and re-opening the Control Center UI resolves this issue.
* The playback position may go out of sync with the app's actual playback position. 
* The time interval (seconds) displayed in skip controls may not match the actual skip time interval aka "seek length".

This behavior is not exclusive to Aural Player; it can be observed when using the Control Center with other audio apps such as Spotify.

### **For more info**
Visit the [official release page](https://github.com/maculateConception/aural-player/releases/tag/3.1.0)
