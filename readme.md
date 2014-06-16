# Native SHA1 Hashing Plugin

```
Authors:
  Kerri Shotts (kerrishotts@gmail.com)
  Chase Noel (chasen@autonettv.com)

Version History:
  1.0.0 2014-06-12 KAS Created first version of plugin
```

This plugin implements a fast, native SHA1 hashing routine to make it incredibly fast and easy to check that the files you've downloaded are indeed the files you expect. The plugin allows you to specify a list of files and their corresponding SHA1 hashes. The plugin will iterate over those files, calculate the actual SHA1 hash, and notify your code of any mismatches. Should you have a large number of files (or large files), the plugin will also send periodic progress notifications to your code.

This plugin works for the following platforms: feel free to add your favorite!

* iOS 6+

The license is MIT, so feel free to use, enhance, etc. If you do make changes that would benefit the community, it would be great if you would contribute them back to the original plugin, but that is not required.

## License

```
Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
```

## Repository

Available on [Github](https://github.com/photokandyStudios/TVSHA1Hash). Contributions welcome!

## Minimum Requirements

* Cordova 2.9 or higher (tested 3.5)
* iOS 6+

## Installation

Add the plugin using Cordova's CLI:

```
cordova plugin add com.autonettv.sha1hash
```

If you want to reference the repository:

```
cordova plugin add https://github.com/photokandyStudios/TVSHA1Hash\#master:plugin
```

If you want to install from a downloaded copy:

```
cordova plugin add path/to/the/plugin/directory
```

## Use

All interaction with the library is through `window.TVSHA1Hash`. An example Cordova project can be seen in the `demo` directory (minus build artifacts like `platforms` and such).

### Set Base Path

The plugin needs to know where your files live, unless you want to specify each one as an absolute path. If the `file` plugin is available and version `1.2.0` or greater, the `cordova.file.dataDirectory` is the default location. Otherwise no default is assumed.

To set the base path:

```
window.TVSHA1Hash.setBasePath ( cordova.file.applicationDirectory );
```

### Assign Progress Listeners

Progress listeners are notified whenever the SHA1 Hashing plugin completes a hash. All listeners are notified, and so it is important to check the incoming operation ID so that you can tell which hash verification sequence is underway.

To register a listener:

```
window.TVSHA1Hash.addProgressListener ( hashProgress );
```

To deregister a listener:

```
window.TVSHA1Hash.removeProgressListener ( hashProgress );
```

Your listener should look like this:

```
function hashProgress ( operationID ) {
  // update your progress bars or the like
}
```

**Note:** Your program logic should never assume the progress listener is ever called, nor should it assume it is called in any particular order. Because the progress listener is called within a `setTimeout`, it's possible that the callback will be called *after* the operation has notified the completion handler. As such, build your logic so that it can be called, before, during, or after the completion handler, as well as handling the case where the listener is never called.

### Request hash verifications

You should already know the SHA1 hash values of your files. (If you don't, this plugin does return the computed hash for your reference.) 

Then, call `verifyHashes` with a list of files and hashes, as well as a completion handler:

```
var operationId = window.TVSHA1Hash.verifyHashes ( 
                   [ { file: "www/test1.txt", 
                       hash: "3a1ed3fb75b4e387bc4bc6f424214ca075912589" }, //right hash
                     { file: "www/test2.txt", 
                       hash: "9ba5be16fca5d9232f4255379d3bf1856b7731ca" }, //wrong hash
                     { file: "www/test3.txt", 
                       hash: "0a1568ebf5ac9207acfc8a683946ba0c06fd7d34" }, //right hash
                     { file: "www/empty.txt",  
                       hash: "da39a3ee5e6b4b0d3255bfef95601890afd80709" }, //right hash
                     { file: "www/notfound.txt", 
                       hash: "8daaddcbb3ca602a2bfc8337bf44cce9ab7b67f0" }  //error (file does not exist)
                   ], hashCompleted );
};
```

Your completion handler should look something like this:

```
function hashCompleted ( results ) {
  window.TVSHA1Hash.removeProgressListener ( hashProgress );
  var allPassed = true;
  results.forEach ( function (result) {
    if (result.match !== 1) {
      allPassed = false;
    }
  });
  if (allPassed) {
    // start your app
    console.log ("Take off!");
  } else {
    // complain
    console.log ("Incomplete matches, or other errors");
  }
}
```

### Important Notes

* Files are loaded as memory mapped files if at all possible (which should be the case on any modern iOS version). This means that there *is* a limit to the file size, but it isn't bound to available RAM.

* Do not use `alert` or other native code that may display interactive elements in your handlers. Doing so may cause crashes and other problems.


