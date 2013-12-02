//
//  ViewController.m
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "PanicRequest.h"
#import "Utilities.h"
#import "SMTPLibrary/SKPSMTPMessage.h"
#import "Json.h"
#import "Incident.h"
#import <MapKit/MapKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate, SKPSMTPMessageDelegate, UIAlertViewDelegate> {
    CLLocationManager *locator;
    CLLocation *currentLat;
    BOOL settingsHidden;
    PanicRequest *request;
    AVAudioPlayer *avSound;
    UIButton *userHeadingBtn;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self makeFindMeButton];
    
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"policeAlarm"
                                              withExtension:@"mp3"];
    avSound = [[AVAudioPlayer alloc]
               initWithContentsOfURL:soundURL error:nil];
    [_firstNameField setDelegate:self];
    [_firstNameField setReturnKeyType:UIReturnKeyDone];
    [_firstNameField addTarget:self
                       action:@selector(textFieldFinished:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
    [_lastNameField setDelegate:self];
    [_lastNameField setReturnKeyType:UIReturnKeyDone];
    [_lastNameField addTarget:self
                        action:@selector(textFieldFinished:)
              forControlEvents:UIControlEventEditingDidEndOnExit];
    [_emailField setDelegate:self];
    [_emailField setReturnKeyType:UIReturnKeyDone];
    [_emailField addTarget:self
                       action:@selector(textFieldFinished:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[Utilities saveFilePath]];
	if (fileExists)
	{
		NSArray *values = [[NSArray alloc] initWithContentsOfFile:[Utilities saveFilePath]];
		_firstNameField.text = [values objectAtIndex:0];
		_lastNameField.text = [values objectAtIndex:1];
        _emailField.text = [values objectAtIndex:2];
	}
    
	// Do any additional setup after loading the view, typically from a nib.
    locator = [[CLLocationManager alloc]init];
    currentLat = [[CLLocation alloc]init];
    request = [[PanicRequest alloc]init];
    [_mapView setUserTrackingMode: MKUserTrackingModeFollow];
    //[_mapView setUserTrackingMode: MKUserTrackingModeNone];
    [_mapView setShowsUserLocation:YES];
    _mapView.delegate = self;
    settingsHidden = YES;
    locator.delegate = self;
    locator.desiredAccuracy = kCLLocationAccuracyBest;
    [locator startUpdatingLocation];
    currentLat = [locator location];
    [_mapView setScrollEnabled:YES];
    [self addRecentIncidents];
    [NSTimer scheduledTimerWithTimeInterval:60.0
                                    target:self
                                    selector:@selector(addRecentIncidents)
                                    userInfo:nil
                                    repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(UpdateLocation) userInfo:nil repeats:YES];
}

-(void)UpdateLocation
{
    [locator stopUpdatingLocation];
    [locator startUpdatingLocation];
}

-(void)makeFindMeButton {
    //User Heading Button states images
    UIImage *buttonImage = [UIImage imageNamed:@"greyButtonHighlight.png"];
    UIImage *buttonImageHighlight = [UIImage imageNamed:@"greyButton.png"];
    UIImage *buttonArrow = [UIImage imageNamed:@"LocationBlue.png"];
    
    //Configure the button
    userHeadingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [userHeadingBtn addTarget:self action:@selector(startShowingUserHeading:) forControlEvents:UIControlEventTouchUpInside];
    //Add state images
    [userHeadingBtn setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [userHeadingBtn setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [userHeadingBtn setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        CGSize result = [[UIScreen mainScreen] bounds].size;
        CGFloat scale = [UIScreen mainScreen].scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
        
        if(result.height == 1136){
            userHeadingBtn.frame = CGRectMake(5,395,39,30);
        } else {
            userHeadingBtn.frame = CGRectMake(5,310,39,30);
        }
    }
    
    //Button shadow
    userHeadingBtn.layer.cornerRadius = 8.0f;
    userHeadingBtn.layer.masksToBounds = NO;
    userHeadingBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    userHeadingBtn.layer.shadowOpacity = 0.8;
    userHeadingBtn.layer.shadowRadius = 1;
    userHeadingBtn.layer.shadowOffset = CGSizeMake(0, 1.0f);
    
    [self.mapView addSubview:userHeadingBtn];
}


- (IBAction) startShowingUserHeading:(id)sender{
    if(self.mapView.userTrackingMode == 0){
        [self.mapView setUserTrackingMode: MKUserTrackingModeFollow animated: YES];
        
        //Turn on the position arrow
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationBlue.png"];
        [userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
    else if(self.mapView.userTrackingMode == 1){
        [self.mapView setUserTrackingMode: MKUserTrackingModeFollowWithHeading animated: YES];
        
        //Change it to heading angle
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationHeadingBlue"];
        [userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
    else if(self.mapView.userTrackingMode == 2){
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: YES];
        
        //Put it back again
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
        [userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated{
    if(self.mapView.userTrackingMode == 0){
        [self.mapView setUserTrackingMode: MKUserTrackingModeNone animated: YES];
        
        //Put it back again
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
        [userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
    
}

- (IBAction)textFieldFinished:(id)sender
{
    [sender resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)panicButton:(id)sender {
    if (_soundAlertSwitch.on) {
        dispatch_async(dispatch_get_global_queue(0, 0),
                       ^ {
                           [avSound play];
                       });
    }
    [_sendIndicator startAnimating];
    request = [self makePanicRequest];
        
    [Json createGeoloquTrigger:[Json createGeoloquLayer:request]];
        
    if ([Json postMapEmail:request]) {
        //[Json addIncidentToMap:request];
        [self addPointToMap:[[Incident alloc]init:request]];
        [self successSent];
    } else {
        [self sendFailed];
    }
}

- (IBAction)settingsButton:(id)sender {
    if (settingsHidden) {
        [_settingsView setHidden:NO];
        [_panicButton setHidden:YES];
        [_mapView setHidden:YES];
        settingsHidden = NO;
        [_settingsButton setTitle:@"Done"];
    } else {
        [_settingsView setHidden:YES];
        [_panicButton setHidden:NO];
        [_mapView setHidden:NO];
        settingsHidden = YES;
        [_settingsButton setTitle:@"Settings"];
        NSArray *values = [[NSArray alloc] initWithObjects:_firstNameField.text ,_lastNameField.text,_emailField.text,nil];
        [values writeToFile:[Utilities saveFilePath] atomically:YES];
    }
}

-(PanicRequest*)makePanicRequest {
    [self UpdateLocation];
    currentLat = [locator location];
    PanicRequest *output = [[PanicRequest alloc]init];
    output.firsrName = _firstNameField.text;
    output.lastName = _lastNameField.text;
    output.email = _emailField.text;
    output.latitude = [NSString stringWithFormat:@"%f", [currentLat coordinate].latitude];
    output.longitude = [NSString stringWithFormat:@"%f", [currentLat coordinate].longitude];
    return output;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
}

-(void)centerMapOnUser {
    MKCoordinateRegion mapRegion;
    mapRegion.center = _mapView.userLocation.coordinate;
    mapRegion.span = MKCoordinateSpanMake(0.001, 0.001);
    [_mapView setRegion:mapRegion animated: YES];
}

- (void)messageSent:(SKPSMTPMessage *)message {
    [self successSent];
}

-(void)successSent {
    NSLog(@"Message Sent");
    NSMutableString *alertMessage = [[NSMutableString alloc]init];
    [alertMessage appendString:@"Sending Your Location NOW!!!"];
    alertMessage = [[NSString stringWithFormat:@"%@\r%@", alertMessage,@""] mutableCopy];
    [alertMessage appendString:@"Longitude: "];
    [alertMessage appendString:request.longitude];
    alertMessage = [[NSString stringWithFormat:@"%@\r%@", alertMessage,@"Latitude: "] mutableCopy];
    [alertMessage appendString:request.latitude];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message Received"
                                                    message:alertMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alert.delegate = self;
    [alert show];
    [_sendIndicator stopAnimating];
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error {
    [_sendIndicator stopAnimating];
    NSLog(@"Message Failed With Error(s): %@", [error description]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message Failed"
                                                    message:@"Something went wrong and the message was not sent.  Please try again later."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alert.delegate = self;
    [alert show];
}

-(void)sendFailed {
    [_sendIndicator stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message Failed"
                                                    message:@"Something went wrong and the message was not sent.  Please try again later."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)addPointToMap:(NSString*)latitude longitude:(NSString*)longitude {
    CLLocationCoordinate2D coord;
    coord.latitude = [latitude doubleValue];
    coord.longitude = [longitude doubleValue];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:coord];
    [annotation setTitle:@"Incident"];
    [_mapView addAnnotation:annotation];
}

-(void)addPointToMap:(NSString*)latitude longitude:(NSString*)longitude name:(NSString*)name {
    CLLocationCoordinate2D coord;
    coord.latitude = [latitude doubleValue];
    coord.longitude = [longitude doubleValue];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:coord];
    [annotation setTitle:name];
    [_mapView addAnnotation:annotation];
}

-(void)addPointToMap:(Incident*)coord {
    [self addPointToMap:coord.latitude longitude:coord.longitude name:coord.name];
    [self addCircleToMap:coord];
}

-(void)addCircleToMap:(Incident*)coord {
    CLLocationCoordinate2D location;
    location.latitude = [coord.latitude doubleValue];
    location.longitude = [coord.longitude doubleValue];
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:location radius:[coord.radius doubleValue]];
    [circle setTitle:coord.name];
    [_mapView addOverlay:circle];
}

-(void)addRecentIncidents {
    // Set another thread to check for incident updates every 60 seconds
    [self.mapView removeOverlays:self.mapView.overlays];
                       NSLog(@"Getting Recent Incidents...");
                       NSMutableArray *incidents = [Json getGeoloqiPlaces];
                       for (NSInteger x = 0; x < [incidents count]; x++) {
                           [self addPointToMap:incidents[x]];
                       }
    
}

-(void)sendEmail:(PanicRequest*)input {
    SKPSMTPMessage *forgotPassword = [[SKPSMTPMessage alloc] init];
    [forgotPassword setFromEmail:@"cmuscottybark@gmail.com"];  // Change to your email address
    [forgotPassword setToEmail:@"qiyo700hice@post.wordpress.com"]; // Load this, or have user enter this
    //[forgotPassword setToEmail:@"bjfxvkzxiicwk@tumblr.com"]; // Load this, or have user enter this
    [forgotPassword setRelayHost:@"smtp.gmail.com"];
    [forgotPassword setRequiresAuth:YES]; // GMail requires this
    [forgotPassword setLogin:@"cmuscottybark@gmail.com"]; // Same as the "setFromEmail:" email
    [forgotPassword setPass:@"rootaccess"]; // Password for the Gmail account that you are sending from
    NSDate *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM.dd.YY HH:mm:ss a"];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    NSMutableString *subject = [@"Alert at " mutableCopy];
    [subject appendString:dateString];
    [forgotPassword setSubject:subject]; // Change this to change the subject of the email
    [forgotPassword setWantsSecure:YES]; // Gmail Requires this
    [forgotPassword setDelegate:self]; // Required
    
    NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/plain", kSKPSMTPPartContentTypeKey, [Utilities assembleEmail:input], kSKPSMTPPartMessageKey, @"8bit" , kSKPSMTPPartContentTransferEncodingKey, nil];
    
    [forgotPassword setParts:[NSArray arrayWithObjects:plainPart, nil]];
    [forgotPassword send];
}

// Listener for shipment to see if a response is given
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Received Response!");
}

// Listener for shipment that fires when an NSData object is returned by the json call
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self successSent];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        [avSound stop];
    }
}

// Draws the circles
- (MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay
{
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.strokeColor = [UIColor redColor];
    circleView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    return circleView;
}

@end
