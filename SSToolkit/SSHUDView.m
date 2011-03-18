//
//  SSHUDView.h
//  SSToolkit
//
//  Created by Sam Soffes on 9/29/09.
//  Copyright 2009-2010 Sam Soffes. All rights reserved.
//

#import "SSHUDView.h"
#import "SSHUDWindow.h"
#import "SSDrawingMacros.h"
#import "UIView+SSToolkitAdditions.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat kIndicatorSize = 40.0;

@implementation SSHUDView

@synthesize textLabel = _textLabel;
@synthesize textLabelHidden = _textLabelHidden;
@synthesize activityIndicator = _activityIndicator;
@synthesize hudSize = _hudSize;
@synthesize loading = _loading;
@synthesize successful = _successful;

#pragma mark NSObject

- (id)init {
	return [self initWithTitle:nil loading:YES];
}


- (void)dealloc {
	[_hudWindow release];
	[_activityIndicator release];
	[_textLabel release];
	[super dealloc];
}


#pragma mark UIView

- (id)initWithFrame:(CGRect)frame {
	return [self initWithTitle:nil loading:YES];
}


- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw rounded rectangle
	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 0.5f);
	CGRect rrect = CGRectMake(0.0f, 0.0f, _hudSize.width, _hudSize.height);
	SSDrawRoundedRect(context, rrect, 14.0f);
	
	// Image
	if (_loading == NO) {
		[[UIColor whiteColor] set];
		NSString *dingbat = _successful ? @"✔" : @"✘";
		UIFont *dingbatFont = [UIFont systemFontOfSize:60.0f];
		CGSize dingbatSize = [dingbat sizeWithFont:dingbatFont];
		CGRect dingbatRect = CGRectMake(roundf((_hudSize.width - dingbatSize.width) / 2.0f),
										roundf((_hudSize.height - dingbatSize.height) / 2.0f),
										dingbatSize.width, dingbatSize.height);
		[dingbat drawInRect:dingbatRect withFont:dingbatFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	}
}


- (void)layoutSubviews {
	_activityIndicator.frame = CGRectMake(roundf((_hudSize.width - kIndicatorSize) / 2.0f),
										  roundf((_hudSize.height - kIndicatorSize) / 2.0f),
										  kIndicatorSize, kIndicatorSize);
	
	if (_textLabelHidden) {
		_textLabel.frame = CGRectZero;
	} else {
		_textLabel.frame = CGRectMake(0.0f, roundf(_hudSize.height - 30.0f), _hudSize.width, 20.0f);
	}
}


#pragma mark HUD

- (id)initWithTitle:(NSString *)aTitle {
	return [self initWithTitle:aTitle loading:YES];
}


- (id)initWithTitle:(NSString *)aTitle loading:(BOOL)isLoading {
	if ((self = [super initWithFrame:CGRectZero])) {
		self.backgroundColor = [UIColor clearColor];

		_hudWindow = [[SSHUDWindow alloc] init];
		_hudSize = CGSizeMake(172.0f, 172.0f);
		
		// Indicator
		_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_activityIndicator.alpha = 0.0;
		[_activityIndicator startAnimating];
		[self addSubview:_activityIndicator];
		
		// Text Label
		_textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_textLabel.font = [UIFont boldSystemFontOfSize:14];
		_textLabel.backgroundColor = [UIColor clearColor];
		_textLabel.textColor = [UIColor whiteColor];
		_textLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
		_textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_textLabel.textAlignment = UITextAlignmentCenter;
		_textLabel.lineBreakMode = UILineBreakModeTailTruncation;
		_textLabel.text = aTitle ? aTitle : @"Loading";
		[self addSubview:_textLabel];
		
		// Loading
		self.loading = isLoading;
	}
	return self;
}


- (void)show {
	_hudWindow.alpha = 0.0f;
	self.alpha = 0.0f;
	[_hudWindow addSubview:self];
	[_hudWindow makeKeyAndVisible];
	
	[UIView beginAnimations:@"SSHUDViewFadeInWindow" context:nil];
	_hudWindow.alpha = 1.0f;
	[UIView commitAnimations];
	
	CGSize windowSize = _hudWindow.frame.size;
	CGRect contentFrame = CGRectMake(roundf((windowSize.width - _hudSize.width) / 2.0f), 
									 roundf((windowSize.height - _hudSize.height) / 2.0f) + 10.0f,
									 _hudSize.width, _hudSize.height);
	
	self.frame = CGRectSetY(contentFrame, contentFrame.origin.y + 20.0f);
	
	[UIView beginAnimations:@"SSHUDViewFadeInContentAlpha" context:nil];
	[UIView setAnimationDelay:0.1];
	[UIView setAnimationDuration:0.2];
	self.alpha = 1.0f;
	[UIView commitAnimations];
	
	[UIView beginAnimations:@"SSHUDViewFadeInContentFrame" context:nil];
	[UIView setAnimationDelay:0.1];
	[UIView setAnimationDuration:0.3];
	self.frame = contentFrame;
	[UIView commitAnimations];
}


- (void)completeWithTitle:(NSString *)aTitle {
	self.successful = YES;
	self.loading = NO;
	_textLabel.text = aTitle;
}


- (void)completeAndDismissWithTitle:(NSString *)aTitle {
	[self completeWithTitle:aTitle];
	[self retain];
	[self performSelector:@selector(releaseAndDismiss) withObject:nil afterDelay:1.0];
}


- (void)failWithTitle:(NSString *)aTitle {
	self.successful = NO;
	self.loading = NO;
	_textLabel.text = aTitle;
}


- (void)failAndDismissWithTitle:(NSString *)aTitle {
	[self failWithTitle:aTitle];
	[self retain];
	[self performSelector:@selector(releaseAndDismiss) withObject:nil afterDelay:1.0];
}


- (void)releaseAndDismiss {
	[self autorelease];
	[self dismissAnimated:YES];
}


- (void)dismiss {
	[self dismissAnimated:YES];
}


- (void)dismissAnimated:(BOOL)animated {
	[_hudWindow fadeOutAndPerformSelector:@selector(resignKeyWindow)];
}


#pragma mark Getters

- (BOOL)showsVignette {
	return _hudWindow.showsVignette;
}


#pragma mark Setters

- (void)setLoading:(BOOL)isLoading {
	_loading = isLoading;
	_activityIndicator.alpha = _loading ? 1.0 : 0.0;
	[self setNeedsDisplay];
}


- (void)setTextLabelHidden:(BOOL)hidden {
	_textLabelHidden = hidden;
	_textLabel.hidden = hidden;
	[self setNeedsLayout];
}


- (void)setShowsVignette:(BOOL)show {
	_hudWindow.showsVignette = show;
}

@end
