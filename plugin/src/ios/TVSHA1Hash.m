/**
*
* TBSHA1Hash.m
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

#import "TVSHA1Hash.h"
#import "Cordova/CDV.h"
#import "Cordova/CDVJSON.h"
#import <CommonCrypto/CommonDigest.h>

@implementation TVSHA1Hash {

}

/**
 * Compute an SHA1 hash for a specific file, specifying an error if one occurs.
 * NOTE: Uses memory mapped files (if safe), to reduce memory footprint.
 */
+(NSString *)computeSHA1HashForFile: (NSString *) path error: (NSError **) error
{
	NSString *decodedPath = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSData *fileData = [NSData dataWithContentsOfFile: decodedPath options: NSDataReadingMappedIfSafe
											error: error];
	if (!fileData) { return nil; }

	uint8_t digest[ CC_SHA1_DIGEST_LENGTH ];

	CC_SHA1 ( fileData.bytes, (CC_LONG) fileData.length, digest);

	NSMutableString *hash = [NSMutableString stringWithCapacity: CC_SHA1_DIGEST_LENGTH * 2];
	for (NSUInteger i=0; i<CC_SHA1_DIGEST_LENGTH; i++) {
		[hash appendFormat: @"%02x", digest[i]];
	}

	return hash;
}

/**
 * Apparently we have to call this by using performSelector:onMainThread... to avoid issues
 */
-(void)evalJS: (NSString *)js
{
	[self.webView stringByEvaluatingJavaScriptFromString: js ];
}

/**
 * Verify the hashes provided by the non-native code.
 */
-(void)verifyHashes:(CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{

		// this will be our return value
		CDVPluginResult* pluginResult = nil;

		// get the operation ID and the list of files and hashes from the command
		int operationID = [command.arguments[0] intValue];

		// get the files and hashes
		NSArray *filesAndHashes = command.arguments[1];

		// create a return array (of dictionaries) suitable for returning back to the native code
		__block NSMutableArray *filesAndStatuses = [NSMutableArray arrayWithCapacity: filesAndHashes.count];


		// get the global low priority queue (we don't want this to sit on the foreground thread	
		dispatch_queue_t background_queue;
		background_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0);

		// create a group, so we can wait for them all to finish later
		dispatch_group_t hash_group = dispatch_group_create();

		// iterate over all our files
		for (NSUInteger i=0; i<filesAndHashes.count; i++) {
			// capture the path and hash
			__block NSString *path = filesAndHashes[i][@"file"];
			__block NSString *hash = filesAndHashes[i][@"hash"];

			// dispatch a hashing operation
			dispatch_group_async ( hash_group, background_queue, ^{
			// we need a way to get error messages back
				NSError *error = nil;

				// compute the hash; if there is an error, the return will be nil and the error will have the needed info
				NSString *computedHash = [TVSHA1Hash computeSHA1HashForFile: path error: &error];

				// Send progress notifications
				NSString *js = [NSString stringWithFormat: @"window.TVSHA1Hash._notifyOfProgress(%i)", operationID ];
				[self performSelectorOnMainThread:@selector(evalJS:) withObject:js waitUntilDone:NO];

				// add the result to our results, including if the codes match and any error that may have occurred.
				NSDictionary *errorDictionary;
				NSMutableDictionary *fileAndStatus;
				fileAndStatus = [@{
						@"file": path,
						@"computedHash": (computedHash ? computedHash : @""),
						@"match": @(computedHash ? [hash isEqualToString: computedHash] : false)
				} mutableCopy];
				if (error) {
					errorDictionary = @{
							@"code": @(error.code),
							@"message": (error.localizedDescription)
						};
					[fileAndStatus setValue:errorDictionary forKey:@"error"];
				}
				[filesAndStatuses addObject: fileAndStatus];
			});
		}

		// wait for all our hashes to complete
		dispatch_group_wait (hash_group, DISPATCH_TIME_FOREVER);

		// create a plugin result
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: filesAndStatuses];

		// and return our result to the non-native code	
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}];
}

@end
