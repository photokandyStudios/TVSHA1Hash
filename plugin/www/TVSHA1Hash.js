/**
*
* TVSHA1Hash.js
*
* @author Kerri Shotts
* @version 1.0.0
*
* Copyright (c) 2014 Kerri Shotts, photoKandy Studios LLC
*                    Chase Noel, AutoNet TV Inc
*
* License: MIT
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this
* software and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy, modify,
* merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to the following
* conditions:
* The above copyright notice and this permission notice shall be included in all copies
* or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
*/

/*jshint
	 asi:true, bitwise:false, browser:true, curly:true, eqeqeq:false, forin:true, noarg:true,
	 noempty:true, plusplus:false, smarttabs:true, sub:true, trailing:false, undef:true,
	 white:false, onevar:false
	*/
/*global module, define, cordova, console*/

var _basePath = "",  // base path for resolving relative paths
    _operationID = 0, // unique ID for operations
    _progressListeners = []; // progress listener callbacks

// try to be a little smart: if the File API is around and supports the `.file.*Directory`
// properties, default `_basePath` to something more useful.
if (typeof cordova.file !== "undefined" ) {
	if (typeof cordova.file.dataDirectory !== "undefined" ) {
		_basePath = cordova.file.dataDirectory;
	}
}

// Define interface
var TVSHA1Hash = {
	/**
	 * Sets the base path for `verifyHashes`. This allows one to only specify relative paths
	 * when calling `verifyHashes`. If sending absolute paths, this method can be ignored.
	 *
	 * @method setBasePath
	 * @param {String} basePath Path to use as the base when resolving relative paths
	 */
	setBasePath: function setBasePath ( basePath ) {
    _basePath = basePath.replace("file://","");
	},
	/**
	 * Send progress listeners updates; the listener should have the signature of
	 * `function listener ( progress )`. `progress` will be an object of the appearance
	 * `{ id: operationID, data: { ... } }`
	 *
	 * @method _notifyOfProgress
	 * @param {Number} operationID
	 * @param {Object} data
	 * @private
	 */
	_notifyOfProgress: function _notifyOfProgress ( operationID ) {
		_progressListeners.forEach ( function (callback) {
			callback(operationID);
		});
	},
	
	/**
	 * Add a progress listener so that your code can be notified when the SHA1 plugin
	 * progresses through its tasks. The listener will receive updates for *all* progress
	 * changes: be sure to inspect `progress.id` to make sure the update is something your
	 * callback is interested in.
	 *
	 * @method addProgressListener
	 * @param {Function} callback
	 */
	addProgressListener: function addProgressListener ( callback ) {
		_progressListeners.push ( callback );
	},
	
	/**
	 * Removes a progress listener so that your code is no longer notified when the SHA1
	 * plugin updates its progress.
	 *
	 * @method removeProgressListener
	 * @param {Function} callback
	 */
	removeProgressListener: function removeProgressListener ( callback ) {
		var i = _progressListeners.indexOf(callback);
		if (i>-1) {
			_progressListeners.splice (i, 1);
		}
	},
	
  /**
   * Verifies hashes against a list of files and known SHA1 hashes.
   *
   * @method verifyHashes
   * @param {Object} filesAndHashes The list of files and known SHA1 hashes
   * @param {Function} completionCallback called when the process is complete
   * @return {Number} the ID# of this operation
   */	
	verifyHashes: function verifyHashes ( filesAndHashes, completionCallback ) {
		// generate a new operation ID
		var operationID = ++_operationID,
		// add _basePath to the files, if they aren't already absolute
		    baseFilesAndHashes = filesAndHashes.map ( function (fileAndHash) {
			var file = fileAndHash.file,
			    hash = fileAndHash.hash;
			// absolute files have "/" in their first position
			if (file.substr(0,1) !== "/") {
				file = _basePath + file;
			}
			// return the updated entry
			return { file: file.replace("file://", ""), hash: hash };
		});
		
		// call the native layer
		setTimeout ( function () {
			cordova.exec ( function ( results ) {
				var relativeResults = results.map ( function (result) { 
					result.file = result.file.replace(_basePath, "");
					return result;
				});
				completionCallback (relativeResults);
			}, undefined, "TVSHA1Hash", "verifyHashes", 
			  [operationID, baseFilesAndHashes ] );
		}, 0);
		  
		// return the operation ID so code can listen for appropriate progress notices
		return operationID;
	}
	
};

// export the interface to Cordova
module.exports = TVSHA1Hash;