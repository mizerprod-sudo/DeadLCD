#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>

#define DOMAIN CFSTR("com.jamal.deadlcd")

static BOOL gEnabled, gVLines, gHGlitch, gFlicker, gRGB, gDead, gRandom;
static CGFloat gI = 0.5, gF = 0.4;

static BOOL PBool(CFStringRef key, BOOL def) {
    BOOL r = def;
    CFPropertyListRef v = CFPreferencesCopyAppValue(key, DOMAIN);
    if (v) {
        if (CFGetTypeID(v) == CFBooleanGetTypeID()) {
            r = CFBooleanGetValue((CFBooleanRef)v);
        } else if (CFGetTypeID(v) == CFNumberGetTypeID()) {
            int n = 0;
            CFNumberGetValue((CFNumberRef)v, kCFNumberIntType, &n);
            r = (n != 0);
        }
        CFRelease(v);
    }
    return r;
}

static CGFloat PFloat(CFStringRef key, CGFloat def) {
    CGFloat r = def;
    CFPropertyListRef v = CFPreferencesCopyAppValue(key, DOMAIN);
    if (v) {
        if (CFGetTypeID(v) == CFNumberGetTypeID()) {
            double d = def;
            CFNumberGetValue((CFNumberRef)v, kCFNumberDoubleType, &d);
            r = d;
        }
        CFRelease(v);
    }
    return r;
}

static void LoadPrefs(void) {
    CFPreferencesAppSynchronize(DOMAIN);
    gEnabled  = PBool(CFSTR("enabled"), YES);
    gVLines   = PBool(CFSTR("vlines"), YES);
    gHGlitch  = PBool(CFSTR("hglitch"), YES);
    gFlicker  = PBool(CFSTR("flicker"), YES);
    gRGB      = PBool(CFSTR("rgb"), YES);
    gDead     = PBool(CFSTR("dead"), YES);
    gRandom   = PBool(CFSTR("random"), YES);
    gI = MAX(0.05, MIN(1.0, PFloat(CFSTR("intensity"), 0.5)));
    gF = MAX(0.0, MIN(1.0, PFloat(CFSTR("frequency"), 0.4)));
}

static CGFloat R(void) { return arc4random_uniform(100001) / 100000.0; }
static CGFloat RR(CGFloat a, CGFloat b) { return a + (b - a) * R(); }

static UIColor *PrimColor(CGFloat a) {
    static const CGFloat c[6][3] = {{1,0,0},{0,1,0},{0,0,1},{0,1,1},{1,0,1},{1,1,0}};
    int i = arc4random_uniform(6);
    return [UIColor colorWithRed:c[i][0] green:c[i][1] blue:c[i][2] alpha:a];
}

/* ---------- Overlay view ---------- */

@interface DLOverlay : UIView
- (void)rebuild;
@end

@implementation DLOverlay {
    CADisplayLink *_link;
    NSMutableArray<CALayer *> *_static;
    NSMutableArray<NSArray *> *_temp;
    NSArray<CALayer *> *_stripes;
    CALayer *_dark, *_flash, *_tint;
    CAGradientLayer *_grad;
    CFTimeInterval _darkUntil, _flashUntil, _tintUntil;
}

- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _static = [NSMutableArray new];
        _temp = [NSMutableArray new];

        _grad = [CAGradientLayer layer];
        _grad.frame = self.bounds;
        _grad.startPoint = CGPointMake(0, 0.5);
        _grad.endPoint = CGPointMake(1, 0.5);
        _grad.hidden = YES;
        [self.layer addSublayer:_grad];

        _tint = [CALayer layer];
        _tint.frame = self.bounds; _tint.opacity = 0; _tint.zPosition = 50;
        [self.layer addSublayer:_tint];

        _dark = [CALayer layer];
        _dark.frame = self.bounds; _dark.opacity = 0; _dark.zPosition = 100;
        _dark.backgroundColor = UIColor.blackColor.CGColor;
        [self.layer addSublayer:_dark];

        _flash = [CALayer layer];
        _flash.frame = self.bounds; _flash.opacity = 0; _flash.zPosition = 101;
        _flash.backgroundColor = UIColor.whiteColor.CGColor;
        [self.layer addSublayer:_flash];

        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        _link.preferredFramesPerSecond = 30;
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _link.paused = YES;
    }
    return self;
}

- (CALayer *)rect:(CGRect)r color:(UIColor *)c life:(CFTimeInterval)life {
    CALayer *l = [CALayer layer];
    l.frame = r;
    l.backgroundColor = c.CGColor;
    [self.layer addSublayer:l];
    if (life > 0) [_temp addObject:@[l, @(CACurrentMediaTime() + life)]];
    else [_static addObject:l];
    return l;
}

- (void)rebuild {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    for (CALayer *l in _static) [l removeFromSuperlayer];
    [_static removeAllObjects];
    for (NSArray *e in _temp) [(CALayer *)e[0] removeFromSuperlayer];
    [_temp removeAllObjects];
    _stripes = nil;
    _dark.opacity = 0; _flash.opacity = 0; _tint.opacity = 0;
    _grad.hidden = YES;

    CGFloat W = self.bounds.size.width, H = self.bounds.size.height;
    _grad.frame = self.bounds; _tint.frame = self.bounds;
    _dark.frame = self.bounds; _flash.frame = self.bounds;

    if (!gEnabled) {
        _link.paused = YES;
        self.hidden = YES;
        [CATransaction commit];
        return;
    }
    self.hidden = NO;
    _link.paused = NO;

    if (gVLines) {
        NSMutableArray *s = [NSMutableArray new];
        int n = 4 + (int)(gI * 28);
        for (int i = 0; i < n; i++) {
            CGFloat w = RR(1, 3.5);
            CGFloat y = (R() < 0.5) ? 0 : RR(0, H * 0.7);
            CGFloat h = (R() < 0.6) ? (H - y) : MIN(H - y, RR(H * 0.15, H));
            CALayer *l = [self rect:CGRectMake(RR(0, W), y, w, h) color:PrimColor(RR(0.35, 0.9)) life:0];
            [s addObject:l];
        }
        _stripes = s;
    }

    if (gDead) {
        int n = 6 + (int)(gI * 70);
        for (int i = 0; i < n; i++) {
            BOOL cluster = R() < 0.35;
            CGFloat cx = RR(0, W), cy = RR(0, H);
            int m = cluster ? (2 + arc4random_uniform(5)) : 1;
            int kind = arc4random_uniform(3);
            for (int j = 0; j < m; j++) {
                CGFloat sz = RR(1.5, 4);
                UIColor *c = (kind == 0) ? [UIColor colorWithWhite:0 alpha:0.95]
                           : (kind == 1) ? [UIColor colorWithWhite:1 alpha:0.95]
                           : PrimColor(0.95);
                [self rect:CGRectMake(cx + RR(-6, 6), cy + RR(-6, 6), sz, sz) color:c life:0];
            }
        }
        int k = (int)(gI * 5);
        for (int i = 0; i < k; i++) {
            CGFloat w = RR(8, 10 + 60 * gI), h = RR(3, 20);
            CGFloat x = RR(0, MAX(1, W - w)), y = RR(0, MAX(1, H - h));
            [self rect:CGRectMake(x, y, w, h) color:[UIColor colorWithWhite:0 alpha:0.85] life:0];
            [self rect:CGRectMake(x, y + RR(0, h), w, 1) color:PrimColor(0.9) life:0];
        }
    }

    if (gRGB) {
        CGFloat a = 0.04 + 0.10 * gI;
        NSMutableArray *cols = [NSMutableArray new];
        for (int i = 0; i < 9; i++) {
            UIColor *c = (i % 3 == 0) ? [UIColor colorWithRed:1 green:0 blue:0 alpha:a]
                       : (i % 3 == 1) ? [UIColor colorWithRed:0 green:1 blue:0 alpha:a]
                       : [UIColor colorWithRed:0 green:0 blue:1 alpha:a];
            [cols addObject:(__bridge id)c.CGColor];
        }
        _grad.colors = cols;
        _grad.hidden = NO;
    }
    [CATransaction commit];
}

- (void)band {
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height;
    CGFloat y = RR(0, H), h = RR(2, 6 + 40 * gI);
    CGFloat dx = RR(-50, 50) * (0.3 + gI), life = RR(0.05, 0.25);
    CGFloat a = 0.35 * (0.5 + gI);
    [self rect:CGRectMake(0, y, W, h) color:[UIColor colorWithWhite:R() alpha:RR(0.1, 0.35) * (0.5 + gI)] life:life];
    [self rect:CGRectMake(dx, y, W * RR(0.3, 1), h) color:[UIColor colorWithRed:1 green:0 blue:0 alpha:a] life:life];
    [self rect:CGRectMake(-dx, y, W * RR(0.3, 1), h) color:[UIColor colorWithRed:0 green:1 blue:1 alpha:a] life:life];
}

- (void)tick:(CADisplayLink *)l {
    CFTimeInterval now = CACurrentMediaTime();
    CGFloat p = (0.3 + gF * 5.0) / 30.0;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    for (NSArray *e in [_temp copy]) {
        if ([e[1] doubleValue] < now) {
            [(CALayer *)e[0] removeFromSuperlayer];
            [_temp removeObject:e];
        }
    }

    if (gHGlitch && R() < p) {
        int n = 1 + arc4random_uniform(3);
        for (int i = 0; i < n; i++) [self band];
    }

    if (gRandom && R() < p * 0.5) {
        int n = 3 + arc4random_uniform(6);
        for (int i = 0; i < n; i++) [self band];
        _flashUntil = now + RR(0.04, 0.12);
        _flash.opacity = RR(0.25, 0.8) * gI;
    }
    if (now > _flashUntil) _flash.opacity = 0;

    if (gFlicker) {
        if (now > _darkUntil && R() < p * 1.2) _darkUntil = now + RR(0.08, 0.35);
        _dark.opacity = (now < _darkUntil) ? RR(0.05, 0.7) * gI : 0;
    } else {
        _dark.opacity = 0;
    }

    if (gRGB) {
        if (now > _tintUntil && R() < p * 0.8) {
            _tint.backgroundColor = PrimColor(1).CGColor;
            _tintUntil = now + RR(0.1, 0.4);
            _tint.opacity = RR(0.08, 0.3) * gI;
        }
        if (now > _tintUntil) _tint.opacity = 0;
    } else {
        _tint.opacity = 0;
    }

    if (_stripes.count && R() < 0.5) {
        CALayer *s = _stripes[arc4random_uniform((uint32_t)_stripes.count)];
        s.opacity = RR(0.15, 1.0);
        if (R() < 0.2) s.frame = CGRectOffset(s.frame, RR(-1, 1), 0);
    }

    [CATransaction commit];
}
@end

/* ---------- Window ---------- */

@interface UIWindow (DL)
- (void)_setSecure:(BOOL)secure;
@end

@interface DLWindow : UIWindow
@end
@implementation DLWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e { return nil; }
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)_canAffectStatusBarAppearance { return NO; }
- (BOOL)_canBecomeKeyWindow { return NO; }
@end

static DLWindow *gWindow;
static DLOverlay *gOverlay;
static int gToken;

static void DLStart(void) {
    if (gWindow) return;
    LoadPrefs();

    gWindow = [[DLWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    gWindow.windowLevel = UIWindowLevelStatusBar + 1000000;
    gWindow.backgroundColor = UIColor.clearColor;
    gWindow.userInteractionEnabled = NO;
    if ([gWindow respondsToSelector:@selector(_setSecure:)]) [gWindow _setSecure:YES];

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.clearColor;
    vc.view.userInteractionEnabled = NO;
    gWindow.rootViewController = vc;

    gOverlay = [[DLOverlay alloc] initWithFrame:vc.view.bounds];
    [vc.view addSubview:gOverlay];
    gWindow.hidden = NO;
    [gOverlay rebuild];

    notify_register_dispatch("com.jamal.deadlcd/prefschanged", &gToken,
                             dispatch_get_main_queue(), ^(int t) {
        LoadPrefs();
        [gOverlay rebuild];
    });
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{ DLStart(); });
}
%end
