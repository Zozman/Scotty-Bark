//
//  Incident.h
//  PanicButton
//
//  Created by Zac Lovoy on 9/26/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PanicRequest.h"

@interface Incident : NSObject

@property NSString* longitude;
@property NSString* latitude;
@property NSString* radius;
@property NSString* name;

-(id)init;
-(id)init:(PanicRequest*)input;

@end
