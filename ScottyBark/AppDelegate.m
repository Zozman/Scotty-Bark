//
//  AppDelegate.m
//  PanicButton
//
//  Created by Zac Lovoy on 9/24/13.
//  Copyright (c) 2013 CMU. All rights reserved.
//

#import "AppDelegate.h"
#import "Utilities.h"
#import "ViewController.h"
#import "Json.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        UIStoryboard *storyBoard;
        
        CGSize result = [[UIScreen mainScreen] bounds].size;
        CGFloat scale = [UIScreen mainScreen].scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
        
        if(result.height == 1136){
            storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone5" bundle:nil];
            UIViewController *initViewController = [storyBoard instantiateInitialViewController];
            [self.window setRootViewController:initViewController];
        }
    }
    
    // Sets your API Key. Provide an empty string as the secret.
    [LQSession setAPIKey:@"dc172c6b297546030e769c9b4ba09616"];
    // Tell the SDK the app finished launching so it can properly handle push notifications, etc
    [LQSession application:application didFinishLaunchingWithOptions:launchOptions];
    
    // If a user account has already been created, this will resume the tracker in the last state
    // it was left in when the app last quit.
    if([LQSession savedSession]) {
        // Call [LQTracker sharedTracker] which will cause it to resume tracking in the previous state
        [LQTracker sharedTracker];
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        [defs setObject:[LQSession savedSession].accessToken forKey:@"accessToken"];
        [defs synchronize];
        // Re-register for push notifications so we tell the server the user is still using the app
        [LQSession registerForPushNotificationsWithCallback:NULL];
    } else {
        // Create a new anonymous account. You can pass an NSDictionary with custom user info if you wish
        [LQSession createAnonymousUserAccountWithUserInfo:nil key:nil layerIds:[NSArray arrayWithObjects: @"ALBJ", nil] groupTokens:nil completion:^(LQSession *session, NSError *error) {
            if(error) {
                NSLog(@"ERROR: Failed to create account: %@", error);
            } else {
                // Save the session to disk so it will be restored on next launch
                [LQSession setSavedSession:session];
                NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
                [defs setObject:session.accessToken forKey:@"accessToken"];
                [defs synchronize];
                
                // Now register for push notifications
                // After the user approves, the app delegate method didRegisterForRemoteNotificationsWithDeviceToken will be called
                [LQSession registerForPushNotificationsWithCallback:^(NSData *deviceToken, NSError *error) {
                    if(error){
                        NSLog(@"Failed to register for push notifications: %@", error);
                    } else {
                        NSLog(@"Got a push token! %@", deviceToken);
                    }
                }];
                
                // Start tracking
                [[LQTracker sharedTracker] setProfile:LQTrackerProfileLogging];
                
                // Note: You may not want to start tracking right here, and you may not want to register for push notifications now either.
                // You are better off putting off these until you absolutely need to, since they will show a popup prompt to the user.
                // It is somewhat annoying to see two prompts in a row before even getting a chance to use the app, so you should wait
                // until you need to show a map or until the user turns "on" some functionality before prompting for location access
                // and push notification permission.
            }
        }];
    }
    [Json subscribeGeoloquUsers];
    [Json subscribeGeoloquSingleUser];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Geoloqu Push Stuff


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
{
    // For push notification support, we need to get the push token from UIApplication via this method.
    // If you like, you can be notified when the relevant web service call to the Geoloqi API succeeds.
    [LQSession registerDeviceToken:deviceToken withMode:LQPushNotificationModeDev];
    
    // When you're ready to publish your project to the app store, you should switch to "live" push mode.
    // [LQSession registerDeviceToken:deviceToken withMode:LQPushNotificationModeLive];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
{
    [LQSession handleDidFailToRegisterForRemoteNotifications:error];
}

/**
 * This is called when a push notification is received if the app is running in the foreground. If the app was in the
 * background when the push was received, this will be run as soon as the app is brought to the foreground by tapping the notification.
 * The SDK will also call this method in application:didFinishLaunchingWithOptions: if the app was launched because of a push notification.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [LQSession handlePush:userInfo];
}

// End Push

@end
