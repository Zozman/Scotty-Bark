//
//  Json.h
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanicRequest.h"
#import "DividedAddress.h"

@interface Json : NSObject

+(NSMutableData*)sendJsonCommandToData:(NSMutableString*)cmd;
+(NSString*)getNonce;
+(NSString*)getAddress:(PanicRequest*)input;
+(NSMutableArray*)getRecentIncidents;
+(NSMutableArray*)getAllIncidents;
+(void)addIncidentToMap:(PanicRequest*)input;
+(BOOL)postEmail:(PanicRequest*)input;
+(NSString*)createGeoloquLayer:(PanicRequest*)input;
+(void)createGeoloquTrigger:(NSString*)placeID;
+(NSString*)createGeoloquMapLink;
+(void)subscribeGeoloquUsers;
+(void)subscribeGeoloquSingleUser;
+(NSMutableArray*)getGeoloqiPlaces;
+(DividedAddress*)getSeparatedAddress:(PanicRequest*)input;
+(BOOL)postMapEmail:(PanicRequest*)input;

@end
