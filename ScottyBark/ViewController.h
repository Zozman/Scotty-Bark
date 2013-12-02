//
//  ViewController.h
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *panicButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sendIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UISwitch *soundAlertSwitch;

@property (weak, nonatomic) IBOutlet UIView *settingsView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)panicButton:(id)sender;
- (IBAction)settingsButton:(id)sender;

@end
