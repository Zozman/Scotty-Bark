//
//  Utilities.m
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import "Utilities.h"
#import "PanicRequest.h"
#import "Reachability.h"
#import "Json.h"
#import "SKPSMTPMessage.h"
#include <stdlib.h>

@implementation Utilities

+ (NSString *) saveFilePath
{
	NSArray *path =
	NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
	return [[path objectAtIndex:0] stringByAppendingPathComponent:@"savefile.plist"];
    
}

+(NSMutableString*)getMapLink:(PanicRequest*)input {
    NSMutableString *output = [@"https://maps.google.com/?q=" mutableCopy];
    [output appendString:input.latitude];
    [output appendString:@","];
    [output appendString:input.longitude];
    return output;
}

+(BOOL)testServerConnection {
    Reachability *hostReach = [Reachability reachabilityWithHostName:[[NSURL URLWithString:@"http://scottybark.mrlovoy.com"] host]];
    return ([hostReach currentReachabilityStatus] != NotReachable);
}

+(NSMutableString*)assembleEmail:(PanicRequest*)input{
    NSMutableString *message = [@"<h2>Alert!</h2><br /><br />Name: " mutableCopy];
    [message appendString:input.firsrName];
    [message appendString:@" "];
    [message appendString:input.lastName];
    [message appendString:@"<br />Phone Number: "];
    [message appendString:input.email];
    [message appendString:@"<br />Address: "];
    [message appendString:[Json getAddress:input]];
    [message appendString:@"<br />Latitude: "];
    [message appendString:input.latitude];
    [message appendString:@"<br />Longitude: "];
    [message appendString:input.longitude];
    [message appendString:@"<br />Map Link: <a href=\""];
    [message appendString:[Utilities getMapLink:input]];
    [message appendString:@"\" target=\"_blank\">HERE</a><br />[google-map-sc address = \""];
    [message appendString:input.latitude];
    [message appendString:@","];
    [message appendString:input.longitude];
    [message appendString:@"\" zoom = \"15\"]<br />[status publish][category Active][delay -2 minutes]"];
    [message appendString:@"[tags Longitude-"];
    [message appendString:input.longitude];
    [message appendString:@",Latitude-"];
    [message appendString:input.latitude];
    [message appendString:@"]"];
    return message;
}

+(NSMutableString*)assembleEmailMandril:(PanicRequest*)input{
    NSMutableString *message = [@"<h2>Alert!</h2><br /><br />Name: " mutableCopy];
    [message appendString:input.firsrName];
    [message appendString:@" "];
    [message appendString:input.lastName];
    [message appendString:@"<br />Phone Number: "];
    [message appendString:input.email];
    [message appendString:@"<br />Address: "];
    [message appendString:[Json getAddress:input]];
    [message appendString:@"<br />Latitude: "];
    [message appendString:input.latitude];
    [message appendString:@"<br />Longitude: "];
    [message appendString:input.longitude];
    [message appendString:@"<br />Geoloqi Map: "];
    [message appendString:[Json createGeoloquMapLink]];
    [message appendString:@"<br />[mgl_gmap zoom = '15' mapid='"];
    [message appendString:[@(arc4random()) stringValue] ];
    [message appendString:@"' lat='"];
    [message appendString:input.latitude];
    [message appendString:@"' long='"];
    [message appendString:input.longitude];
    [message appendString:@"'][mgl_marker lat='"];
    [message appendString:input.latitude];
    [message appendString:@"' long='"];
    [message appendString:input.longitude];
    [message appendString:@"'][/mgl_marker][/mgl_gmap]<br />[status published][category Active]"];
    [message appendString:@"[tags Longitude-"];
    [message appendString:input.longitude];
    [message appendString:@",Latitude-"];
    [message appendString:input.latitude];
    [message appendString:@"]"];
    return message;
}

+(NSMutableString*)assembleMapEmailMandril:(PanicRequest*)input{
    DividedAddress *adr = [Json getSeparatedAddress:input];
    NSMutableString *message = [@"<h2>Alert!</h2><br />[cf]" mutableCopy];
    [message appendString:adr.streetAddress];
    [message appendString:@"[/cf][cf2]"];
    [message appendString:adr.cityStateZip];
    [message appendString:@"[/cf2][restrict userlevel='admin']<br />Name: "];
    [message appendString:input.firsrName];
    [message appendString:@" "];
    [message appendString:input.lastName];
    [message appendString:@"<br />Phone Number: "];
    [message appendString:input.email];
    [message appendString:@"<br />Latitude: "];
    [message appendString:input.latitude];
    [message appendString:@"<br />Longitude: "];
    [message appendString:input.longitude];
    [message appendString:@"<br />Geoloqi Map: "];
    [message appendString:[Json createGeoloquMapLink]];
    [message appendString:@"<br />[/restrict]"];
    return message;
}

+(NSMutableString*)assembleMandrilJson:(PanicRequest*)input {
    NSMutableString *message = [@"{\"key\": \"7hVpgJ9SpDwJg7c2c9B-8Q\",\"message\": {\"html\": \"" mutableCopy];
    [message appendString:[self assembleEmailMandril:input]];
    [message appendString:@"\",\"subject\": \""];
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM.dd.YY HH:mm:ss a"];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    NSMutableString *subject = [@"Alert at " mutableCopy];
    [subject appendString:dateString];
    [message appendString:subject];
    [message appendString:@"\",\"from_email\": \"cmuscottybark@gmail.com\",\"from_name\": \"Scotty Bark\",\"to\": [{\"email\":\"rapo756reni@post.wordpress.com\",\"name\": \"Dispatch\"}],\"auto_text\": null,\"auto_html\": null}}"];
    return message;
}

+(NSMutableString*)assembleMapMandrilJson:(PanicRequest*)input {
    NSMutableString *message = [@"{\"key\": \"7hVpgJ9SpDwJg7c2c9B-8Q\",\"message\": {\"html\": \"" mutableCopy];
    [message appendString:[self assembleMapEmailMandril:input]];
    [message appendString:@"\",\"subject\": \""];
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM.dd.YY HH:mm:ss a"];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    NSMutableString *subject = [@"Alert at " mutableCopy];
    [subject appendString:dateString];
    [message appendString:subject];
    [message appendString:@"\",\"from_email\": \"cmuscottybark@gmail.com\",\"from_name\": \"Scotty Bark\",\"to\": [{\"email\":\"rapo756reni@post.wordpress.com\",\"name\": \"Dispatch\"}],\"auto_text\": null,\"auto_html\": null}}"];
    return message;
}

+(NSString*)getAccessToken {
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    return [defs objectForKey:@"accessToken"];
}

@end
