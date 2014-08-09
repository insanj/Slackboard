//
//  Slackboard.xm
//  Slackboard
//
//  Created by Julian Weiss on 7/9/14.
//  Copyright (c) 2014 insanj. All rights reserved.
//

#import <UIKit/UIKit.h>

%hook UITableView

- (UIScrollViewKeyboardDismissMode)keyboardDismissMode {
	return UIScrollViewKeyboardDismissModeOnDrag;
}

%end
