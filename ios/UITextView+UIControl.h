#import <UIKit/UIKit.h>

@interface UITextView (UIControl)

- (NSSet *)allTargets;
- (UIControlEvents)allControlEvents;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event;

- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents;

- (NSArray *)actionsForTarget:(id)target forControlEvent:(UIControlEvents)controlEvent;

@end
