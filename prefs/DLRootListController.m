#import <UIKit/UIKit.h>
#import <notify.h>

@interface PSListController : UIViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)reloadSpecifiers;
@end

@interface DLRootListController : PSListController
@end

@implementation DLRootListController

- (NSArray *)specifiers {
    NSArray *s = [self valueForKey:@"_specifiers"];
    if (!s) {
        s = [self loadSpecifiersFromPlistName:@"Root" target:self];
        [self setValue:s forKey:@"_specifiers"];
    }
    return s;
}

- (void)resetSettings {
    CFStringRef domain = CFSTR("com.jamal.deadlcd");
    NSDictionary *d = @{
        @"enabled": @YES, @"vlines": @YES, @"hglitch": @YES,
        @"flicker": @YES, @"rgb": @YES, @"dead": @YES, @"random": @YES,
        @"intensity": @0.5, @"frequency": @0.4
    };
    for (NSString *k in d) {
        CFPreferencesSetAppValue((__bridge CFStringRef)k, (__bridge CFPropertyListRef)d[k], domain);
    }
    CFPreferencesAppSynchronize(domain);
    notify_post("com.jamal.deadlcd/prefschanged");
    [self reloadSpecifiers];
}

@end
