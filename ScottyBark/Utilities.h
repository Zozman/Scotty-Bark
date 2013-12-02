//
//  Utilities.h
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanicRequest.h"

@interface Utilities : NSObject

+(NSString *) saveFilePath;
+(NSMutableString*)getMapLink:(PanicRequest*)input;
+(BOOL)testServerConnection;
+(NSMutableString*)assembleEmail:(PanicRequest*)input;
+(NSMutableString*)assembleMandrilJson:(PanicRequest*)input;
+(NSMutableString*)assembleMapMandrilJson:(PanicRequest*)input;
+(NSString*)getAccessToken;

@end
