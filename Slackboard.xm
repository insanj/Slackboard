//
//  Slackboard.xm
//  Slackboard
//
//  Created by Julian Weiss on 7/9/14.
//  Copyright (c) 2014 insanj. All rights reserved.
//

#import <UIKit/UIKit.h>

static BOOL slackboard_keyboardVisible = NO;
static CGFloat slackboard_scrollViewAnchorOrigin = 0.0;
static NSString *SBScrollViewDidScrollNotification = @"SBScrollViewDidScrollNotification";

/**********************************************************************************************
******************************* Interactive Keyboard Injection ********************************
**********************************************************************************************/

%hook UITableView

- (void)layoutSubviews {
	%orig();
	self.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

%end

/**********************************************************************************************
*********************************** Scroll(ing) View Poster ***********************************
**********************************************************************************************/

@interface SLChatTableViewController : UIViewController
@end

%hook SLChatTableViewController

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	%log;
	%orig();

	// If the keyboard is visible, but untouched by Slackboard.
	if (slackboard_keyboardVisible /*slackboard_scrollViewAnchorOrigin < 0.0*/) {
		slackboard_scrollViewAnchorOrigin = scrollView.contentOffset.y;
	}

	// If the keyboard is visible, and should (now) be touched.
	else if (slackboard_keyboardVisible && slackboard_scrollViewAnchorOrigin > 0.0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SBScrollViewDidScrollNotification object:nil userInfo:@{@"scrollViewChangedOrigin" : @(scrollView.contentOffset.y)}];
	}
}

%end

/**********************************************************************************************
********************************** Accessory View Injections **********************************
**********************************************************************************************/

@interface HPGrowingTextView : UITextField
@end

%hook HPGrowingTextView

- (id)initWithFrame:(CGRect)frame {
	HPGrowingTextView *textView = %orig();

    [[NSNotificationCenter defaultCenter] addObserver:textView selector:@selector(slackboard_setScrollViewAnchorOrigin:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:textView selector:@selector(slackboard_unsetScrollViewAnchorOrigin:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:textView selector:@selector(slackboard_setSlackFrame:) name:SBScrollViewDidScrollNotification object:nil];

    return textView;
}

/*%new - (void)slackboard_setKeyboardEndOrigin:(NSNotification *)notification {
	// CGRect keyboardEndFrame = [(NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	slackboard_keyboardEndOrigin = keyboardEndFrame.origin.y;
}*/

%new - (void)slackboard_setScrollViewAnchorOrigin:(NSNotification *)notification {
	slackboard_keyboardVisible = YES;
	slackboard_scrollViewAnchorOrigin = 0.0;
}

%new - (void)slackboard_unsetScrollViewAnchorOrigin:(NSNotification *)notification {
	slackboard_keyboardVisible = NO;
	slackboard_scrollViewAnchorOrigin = 0.0;
}

%new - (void)slackboard_setSlackFrame:(NSNotification *)notification {
	// CGRect scrollViewScrollAmount = ((UIView *)notification.object).contentOffset;
	NSNumber *scrollViewNewOrigin = (NSNumber *)notification.userInfo[@"scrollViewChangedOrigin"];
	CGFloat amountToSlack = [scrollViewNewOrigin floatValue] - slackboard_scrollViewAnchorOrigin;

	CGRect slackedFieldFrame = self.superview.frame;
	slackedFieldFrame.origin.y += amountToSlack;
	self.superview.frame = slackedFieldFrame;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%end
