//
//  Incident.m
//  PanicButton
//
//  Created by Zac Lovoy on 9/26/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import "Incident.h"
#import "PanicRequest.h"

@implementation Incident

@synthesize longitude;
@synthesize latitude;
@synthesize radius;
@synthesize name;

-(id)init {
    return self;
}

-(id)init:(PanicRequest*)input {
    longitude = input.longitude;
    latitude = input.latitude;
    return self;
}

@end
