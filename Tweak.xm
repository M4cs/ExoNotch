#import <QuartzCore/QuartzCore.h>
#import <Cephei/HBPreferences.h>
#import "EXNTheme.h"
#import "Tweak.h"

UIView *gestureView;
UIView *notchView;
UIScrollView *scrollView;

bool disableBurnInProtection;
bool enabled;
EXNTheme *theme;
EXNWebView *exnWebView;
NSString *themeDirectory;
NSMutableArray *webViews = [NSMutableArray new];
NSMutableArray *viewsToRelayout = [NSMutableArray new];
HBPreferences *preferences;

@implementation EXNWebView

-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	NSString *content = [NSString stringWithContentsOfFile:@"/Library/ExoNotch/exonotch.js" encoding:NSUTF8StringEncoding error:NULL];
	self.exnUserScript = [[WKUserScript alloc] initWithSource:content injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
	[self.exoContentController addUserScript:self.exnUserScript];

	return self;
}

-(void)exoAction:(NSString *)action withArguments:(NSDictionary *)arguments {
	[super exoAction:action withArguments:arguments];
	if ([action isEqualToString:@"enableInteraction"]) {
		self.userInteractionEnabled = true;
	}
}

@end

%group ExoNotch

%hook UIWindow

-(id)_initWithFrame:(CGRect)arg1 showForegroundView:(BOOL)arg2 inProcessStateProvider:(id)arg3 {
    %orig;
    [viewsToRelayout addObject:self];
    return self;
}

- (void)layoutSubviews {
	%orig;
	if (enabled) {
		if(!gestureView) {
			gestureView = [[UIView alloc] initWithFrame:CGRectMake(83, -30, 209, 65)];
			gestureView.backgroundColor = [UIColor clearColor];
			gestureView.clipsToBounds = YES;
			gestureView.layer.cornerRadius = 23;
			[self addSubview:gestureView];

			UISwipeGestureRecognizer *downGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedNotch:)];
			downGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
			downGestureRecognizer.numberOfTouchesRequired = 1;
			[gestureView addGestureRecognizer:downGestureRecognizer];

			notchView = [[UIView alloc] initWithFrame:CGRectMake(83, -120, 209, 120)];
			notchView.backgroundColor = [UIColor blackColor];
			notchView.clipsToBounds = YES;
			notchView.layer.cornerRadius = 23;
			[self addSubview:notchView];

			UISwipeGestureRecognizer *upGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedNotchUp:)];
			upGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
			upGestureRecognizer.numberOfTouchesRequired = 1;
			[notchView addGestureRecognizer:upGestureRecognizer];

			scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 60, notchView.frame.size.width, notchView.frame.size.height)];
			scrollView.backgroundColor = [UIColor clearColor];
			scrollView.pagingEnabled = YES;
			[notchView addSubview:scrollView];
			[scrollView setContentSize:CGSizeMake(notchView.frame.size.width * 1, 60)];

			if (!exnWebView) {
				exnWebView = [[EXNWebView alloc] initWithFrame:CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
				[webViews addObject:exnWebView];
				exnWebView.opaque = false;
				[scrollView addSubview:exnWebView];

				NSURL *nsURL = [NSURL fileURLWithPath:[theme getPath:@"theme.html"]];
				NSURLRequest *request = [NSURLRequest requestWithURL:nsURL];
				[exnWebView loadRequest:request];
			}

			[exnWebView exoInternalUpdate:@{
				@"exonotch.cc": @(false),
				@"exonotch.diabledBurnInProtection": @(disableBurnInProtection),
				@"exonotch.modern": @(false)
			}];

			bool dark = false;

			[exnWebView exoInternalUpdate:@{
				@"exonotch.dark": @(dark)
			}];

			if (theme.info && theme.info[@"settings"]) {
				NSMutableDictionary *settings = [NSMutableDictionary new];
				NSString *prefix = [NSString stringWithFormat:@"TS%@", theme.name];
				for (NSString *key in [preferences.dictionaryRepresentation allKeys]) {
					if ([key hasPrefix:prefix]) {
						settings[[key stringByReplacingOccurrencesOfString:prefix withString:@"exonotch.theme."]] = preferences.dictionaryRepresentation[key];
					}
				}
				[exnWebView exoInternalUpdate:settings];
			}

		}
	}
}


%new
-(void)swipedNotch:(UISwipeGestureRecognizer *)gesture {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	notchView.frame = CGRectMake(83, -30, 209, 120);
	[UIView commitAnimations];
}

%new
-(void)swipedNotchUp:(UISwipeGestureRecognizer *)gesture {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	notchView.frame = CGRectMake(83, -120, 209, 120);
	[UIView commitAnimations];
}

%end

%end

void refreshAll() {
    for (EXNWebView *view in webViews) {
        [view reload];
    }
}

void relayoutAll() {
    for (UIView *view in viewsToRelayout) {
        [view layoutSubviews];
    }
}

%ctor {
    if (![NSProcessInfo processInfo]) return;
    NSString *processName = [NSProcessInfo processInfo].processName;
    bool isSpringboard = [@"SpringBoard" isEqualToString:processName];

    // Someone smarter than me invented this.
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/
    bool shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                        || [processName isEqualToString:@"CoreAuthUI"]
                        || [processName isEqualToString:@"InCallService"]
                        || [processName isEqualToString:@"MessagesNotificationViewService"]
                        || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if ((!isFileProvider && isApplication && !skip) || isSpringboard) {
                shouldLoad = YES;
            }
        }
    }

    if (!shouldLoad) return;

    preferences = [[HBPreferences alloc] initWithIdentifier:@"io.securarepo.exonotch"];
    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];
    [preferences registerBool:&disableBurnInProtection default:NO forKey:@"DisableBurnInProtection"];
    [preferences registerObject:&themeDirectory default:@"default" forKey:@"Theme"];
    [preferences registerPreferenceChangeBlock:^() {
        theme = [EXNTheme themeWithDirectoryName:themeDirectory];
        relayoutAll();
        for (EXNWebView *view in webViews) {
            NSURL *nsUrl = [NSURL fileURLWithPath:[theme getPath:@"theme.html"]];
            NSURLRequest *request = [NSURLRequest requestWithURL:nsUrl];
            [view loadRequest:request];
        }
    }];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)refreshAll, (CFStringRef)EXNRefreshNotification, NULL, (CFNotificationSuspensionBehavior)kNilOptions);

    %init(ExoNotch);
}