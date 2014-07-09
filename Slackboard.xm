//
//  Slackboard.xm
//  Slackboard
//
//  Created by Julian Weiss on 7/9/14.
//  Copyright (c) 2014 insanj. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const SBInputAccessoryViewFrameDidChangeNotification = @"SBInputAccessoryViewFrameDidChangeNotification";

@interface SBInputAccessoryView : UIView
@end

@implementation SBInputAccessoryView

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:@"frame"];
    }

    [newSuperview addObserver:self forKeyPath:@"frame" options:0 context:NULL];
    [super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == self.superview && [keyPath isEqualToString:@"frame"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SBInputAccessoryViewFrameDidChangeNotification object:object];
    }
}

@end

%hook UITableView

- (void)layoutSubviews {
	%orig();

	if (!self.inputAccessoryView) {
		NSLog(@"[Slackboard] Slacking %@.", self);
		self.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
		self.inputAccessoryView = [[SBInputAccessoryView alloc] init];
	}
}

%end


@interface HPGrowingTextView : UIView
@end

%hook HPGrowingTextView

- (id)initWithFrame:(CGRect)frame {
	HPGrowingTextView *textView = %orig();
    [[NSNotificationCenter defaultCenter] addObserver:textView selector:@selector(slackboard_changeFrame:) name:SBInputAccessoryViewFrameDidChangeNotification object:nil];

    return textView;
}

%new - (void)slackboard_changeFrame:(NSNotification *)notification {
	CGRect keyboardEndFrame = ((UIView *)notification.object).frame;
	NSLog(@"[Slack] %@", NSStringFromCGRect(keyboardEndFrame));

	// NSValue *keyboardEndFrame = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
	// NSNumber *keyboardAnimationDuration = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];

	CGRect slackedFieldFrame = self.superview.frame;
	slackedFieldFrame.origin.y = keyboardEndFrame.origin.y - slackedFieldFrame.size.height;

	// [UIView animateWithDuration:0.0 animations:^(void){
		self.superview.frame = slackedFieldFrame;
	// }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%end
