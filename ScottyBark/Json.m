//
//  Json.m
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import "Json.h"
#import "PanicRequest.h"
#import "Incident.h"
#import "Utilities.h"
#import "DividedAddress.h"
#import <MapKit/MapKit.h>

@implementation Json

+(NSMutableData*)sendJsonCommandToData:(NSMutableString*)cmd{
    NSURL *URL = [NSURL URLWithString:[cmd stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableData *data = [NSData dataWithContentsOfURL:URL];
    return data;
}

+(NSString*)getNonce {
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://scottybark.mrlovoy.com/api/get_nonce?controller=posts&method=create_post"];
    // Run json command
    NSMutableData *resultData = [self sendJsonCommandToData:command];
    
    // Decode result
    NSError *e = nil;
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSString *nonce = [jsonArray valueForKey:@"nonce"];
    return nonce;
}

+(void)login {
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://scottybark.mrlovoy.com/wp-login.php?username=admin&password=rootaccess"];
    [self sendJsonCommandToData:command];
}

+(NSString*)getAddress:(PanicRequest*)input {
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://maps.googleapis.com/maps/api/geocode/json?latlng="];
    [command appendString:input.latitude];
    [command appendString:@","];
    [command appendString:input.longitude];
    [command appendString:@"&sensor=true"];
    // Run json command
    NSMutableData *resultData = [self sendJsonCommandToData:command];
    
    // Decode result
    NSError *e = nil;
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSString *address = [[NSString alloc]init];
    @try {
        address = [[[jsonArray valueForKey:@"results"] objectAtIndex:0] valueForKey:@"formatted_address"];
    }
    @catch (NSException *e) {
        address = @"Quota Error";
    }
    return address;
}

+(DividedAddress*)getSeparatedAddress:(PanicRequest*)input {
    DividedAddress *da = [[DividedAddress alloc]init];
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://maps.googleapis.com/maps/api/geocode/json?latlng="];
    [command appendString:input.latitude];
    [command appendString:@","];
    [command appendString:input.longitude];
    [command appendString:@"&sensor=true"];
    // Run json command
    NSMutableData *resultData = [self sendJsonCommandToData:command];
    
    // Decode result
    NSError *e = nil;
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSString *address = [[NSString alloc]init];
    @try {
        address = [[[jsonArray valueForKey:@"results"] objectAtIndex:0] valueForKey:@"formatted_address"];
        NSMutableArray *stringArray= [[address componentsSeparatedByString:@","] mutableCopy];
        da.streetAddress = stringArray[0];
        da.cityStateZip = [@"" mutableCopy];
        for (NSInteger x = 1; x < stringArray.count; x++) {
            [da.cityStateZip appendString:stringArray[x]];
            if (x+1 < stringArray.count) {
                [da.cityStateZip appendString:@","];
            }
        }
    }
    @catch (NSException *e) {
        address = @"Quota Error";
        da.streetAddress = [address mutableCopy];
        da.cityStateZip = [address mutableCopy];
    }
    return da;
}

+(NSMutableArray*)getRecentIncidents {
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://scottybark.mrlovoy.com/api/get_recent_posts/"];
    // Run json command
    NSMutableData *resultData = [self sendJsonCommandToData:command];
    
    // Decode result
    NSError *e = nil;
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSMutableArray*posts = [jsonArray valueForKey:@"posts"];
    NSMutableArray*output = [[NSMutableArray alloc] initWithCapacity:[posts count]];
    NSInteger x = 0;
    for (x = 0; x < [posts count]; x++) {
        Incident *coord = [[Incident alloc]init];
        NSMutableArray*tags = [[posts objectAtIndex:x] valueForKey:@"tags"];
        NSInteger y = 0;
        for (y = 0; y < [tags count]; y++) {
            NSString *tagValue = [[tags objectAtIndex:y] valueForKey:@"title"];
            if ([tagValue hasPrefix:@"Latitude-"]) {
                coord.latitude = [tagValue substringFromIndex:9];
            } else if ([tagValue hasPrefix:@"Longitude-"]) {
                coord.longitude = [tagValue substringFromIndex:10];
            }
        }
        output[x] = coord;
    }
    return output;
}

+(NSMutableArray*)getAllIncidents {
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://scottybark.mrlovoy.com/api/get_posts/"];
    // Run json command
    NSMutableData *resultData = [self sendJsonCommandToData:command];
    
    // Decode result
    NSError *e = nil;
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSMutableArray*posts = [jsonArray valueForKey:@"posts"];
    NSMutableArray*output = [[NSMutableArray alloc] initWithCapacity:[posts count]];
    NSInteger x = 0;
    for (x = 0; x < [posts count]; x++) {
        Incident *coord = [[Incident alloc]init];
        NSMutableArray*tags = [[posts objectAtIndex:x] valueForKey:@"tags"];
        NSInteger y = 0;
        for (y = 0; y < [tags count]; y++) {
            NSString *tagValue = [[tags objectAtIndex:y] valueForKey:@"title"];
            if ([tagValue hasPrefix:@"Latitude-"]) {
                coord.latitude = [tagValue substringFromIndex:9];
            } else if ([tagValue hasPrefix:@"Longitude-"]) {
                coord.longitude = [tagValue substringFromIndex:10];
            }
        }
        output[x] = coord;
    }
    return output;
}

+(void)addIncidentToMap:(PanicRequest*)input {
    NSMutableString *command = [[NSMutableString alloc] init];
    [command appendString:@"http://scottybark.mrlovoy.com/wp-content/plugins/leaflet-maps-marker/leaflet-api.php?key=rootaccess&action=add&type=marker&markername=Incident&layer=1&geocode="];
    [command appendString:input.latitude];
    [command appendString:@","];
    [command appendString:input.longitude];
    // Run json command
    [self sendJsonCommandToData:command];
}

+(BOOL)postEmail:(PanicRequest*)input{
    NSMutableString *post = [Utilities assembleMandrilJson:input];
    NSString *baseUrl = [NSString stringWithFormat:@"https://mandrillapp.com/api/1.0/messages/send.json"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    NSURLResponse *response;
    NSData *dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    NSString *result = [[NSString alloc] initWithData:dataReply encoding:NSUTF8StringEncoding];
    BOOL success = NO;
    if ([result rangeOfString:@"sent"].location != NSNotFound) {
        success = YES;
    }
    return success;
}

+(BOOL)postMapEmail:(PanicRequest*)input{
    NSMutableString *post = [Utilities assembleMapMandrilJson:input];
    NSString *baseUrl = [NSString stringWithFormat:@"https://mandrillapp.com/api/1.0/messages/send.json"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    NSURLResponse *response;
    NSData *dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    NSString *result = [[NSString alloc] initWithData:dataReply encoding:NSUTF8StringEncoding];
    BOOL success = NO;
    if ([result rangeOfString:@"sent"].location != NSNotFound) {
        success = YES;
    }
    return success;
}


+(NSString*)createGeoloquLayer:(PanicRequest*)input {
    NSMutableString *post = [[NSMutableString alloc]init];
    NSTimeInterval addedSeconds = 24*60*60;
    NSDate *oneDayLater = [[NSDate date] dateByAddingTimeInterval:addedSeconds];
    NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"US/Eastern"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setTimeZone:tz];
    [dateFormatter setDateFormat:@"YYYY-mm-ddThh:mm:ss+tzoffset"];
    NSString *endDate = [dateFormatter stringFromDate:oneDayLater];
    
    [post appendString:@"{\"name\":\"Incident\",\"latitude\":"];
    [post appendString:input.latitude];
    [post appendString:@",\"longitude\":"];
    [post appendString:input.longitude];
    [post appendString:@",\"radius\":30,\"layer_id\":\"ALBJ\",\"time_to\":\""];
    [post appendString:endDate];
    [post appendString:@"\"}"];
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.geoloqi.com/1/place/create"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *token = [@"OAuth " mutableCopy];
    [token appendString:@"14d78a-18584cf203795080ae24652837019f560b9f0e0f"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    NSError *e;
    NSURLResponse *response;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSString *placeID = [jsonArray valueForKey:@"place_id"];
    return placeID;
}

+(void)createGeoloquTrigger:(NSString*)placeID {
    NSMutableString *post = [[NSMutableString alloc]init];
    [post appendString:@"{\"place_id\":\""];
    [post appendString:placeID];
    [post appendString:@"\",\"type\":\"message\",\"text\":\""];
    NSString *message = @"Warning!  You have entered an area where an incident has occured in the past 24 hours!  Be aware of your surroundings!";
    [post appendString:message];
    [post appendString:@"\"}"];
    
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.geoloqi.com/1/trigger/create"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *token = [@"OAuth " mutableCopy];
    [token appendString:@"14d78a-18584cf203795080ae24652837019f560b9f0e0f"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    //NSError *e;
    NSURLResponse *response;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    //NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
}

+(NSString*)createGeoloquMapLink {
    NSMutableString *post = [@"{\"minutes\":60}" mutableCopy];
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.geoloqi.com/1/link/create"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *token = [@"OAuth " mutableCopy];
    [token appendString:[Utilities getAccessToken]];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    NSError *e;
    NSURLResponse *response;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSString *link = [jsonArray valueForKey:@"link"];
    return link;
}

+(void)subscribeGeoloquUsers {
    NSMutableString *post = [[NSMutableString alloc]init];
    [post appendString:@""];
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.geoloqi.com/1/layer/subscribe/ALBJ"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *token = [@"OAuth " mutableCopy];
    [token appendString:@"14d78a-18584cf203795080ae24652837019f560b9f0e0f"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    //NSError *e;
    NSURLResponse *response;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    //NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
}

+(void)subscribeGeoloquSingleUser {
    NSMutableString *post = [[NSMutableString alloc]init];
    [post appendString:@""];
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.geoloqi.com/1/layer/subscribe/ALBJ"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *token = [@"OAuth " mutableCopy];
    [token appendString:[Utilities getAccessToken]];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    //NSError *e;
    NSURLResponse *response;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    //NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
}

+(NSMutableArray*)getGeoloqiPlaces {
    NSMutableString *post = [[NSMutableString alloc]init];
    [post appendString:@""];
    NSString *baseUrl = [NSString stringWithFormat:@"https://api.geoloqi.com/1/layer/info/ALBJ?include_places=1"];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableString *token = [@"OAuth " mutableCopy];
    [token appendString:@"14d78a-18584cf203795080ae24652837019f560b9f0e0f"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[post
                          dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error;
    NSError *e;
    NSURLResponse *response;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error ];
    NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error: &e];
    NSMutableArray *places = [jsonArray valueForKey:@"places"];
    NSMutableArray *output = [[NSMutableArray alloc] initWithCapacity:[places count]];
    for (NSInteger x = 0; x < [places count]; x++) {
        Incident *inc = [[Incident alloc]init];
        inc.longitude = [[[places objectAtIndex:x] valueForKey:@"longitude"] stringValue];
        inc.latitude = [[[places objectAtIndex:x] valueForKey:@"latitude"] stringValue];
        inc.name = [[places objectAtIndex:x] valueForKey:@"name"];
        inc.radius = [[[places objectAtIndex:x] valueForKey:@"radius"] stringValue];
        output[x] = inc;
    }
    return output;
}

@end
