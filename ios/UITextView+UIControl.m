#import "UITextView+UIControl.h"
#import <objc/runtime.h>

static void *UIControlEventsTargetActionsMapKey = &UIControlEventsTargetActionsMapKey;

@implementation UITextView (UIControl)

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    NSMutableSet *targetActions = self.eventsTargetActionsMap[@(controlEvents)];
    if (targetActions == nil) {
        targetActions = [NSMutableSet set];
        self.eventsTargetActionsMap[@(controlEvents)] = targetActions;
    }
    [targetActions addObject:@{ @"target": target, @"action": NSStringFromSelector(action) }];

    [self.notificationCenter addObserver:self
                                    selector:@selector(textViewDidBeginEditing:)
                                        name:UITextViewTextDidBeginEditingNotification
                                      object:self];
    [self.notificationCenter addObserver:self
                                    selector:@selector(textViewChanged:)
                                        name:UITextViewTextDidChangeNotification
                                      object:self];
    [self.notificationCenter addObserver:self
                                    selector:@selector(textViewDidEndEditing:)
                                        name:UITextViewTextDidEndEditingNotification
                                      object:self];
}

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    NSMutableSet *targetActions = self.eventsTargetActionsMap[@(controlEvents)];
    NSDictionary *targetAction = nil;
    for (NSDictionary *ta in targetActions) {
        if (ta[@"target"] == target && [ta[@"action"] isEqualToString:NSStringFromSelector(action)]) {
            targetAction = ta;
            break;
        }
    }
    if (targetAction) {
        [targetActions removeObject:targetAction];
    }
}

- (NSSet *)allTargets
{
    NSMutableSet *targets = [NSMutableSet set];
    [self.eventsTargetActionsMap enumerateKeysAndObjectsUsingBlock:^(id key, NSSet *targetActions, BOOL *stop) {
        for (NSDictionary *ta in targetActions) { [targets addObject:ta[@"target"]]; }
    }];
    return targets;
}

- (UIControlEvents)allControlEvents
{
    NSArray *arrayOfEvents = self.eventsTargetActionsMap.allKeys;
    UIControlEvents allControlEvents = 0;
    for (NSNumber *e in arrayOfEvents) {
        allControlEvents = allControlEvents|e.unsignedIntegerValue;
    };
    return allControlEvents;
}

- (NSArray *)actionsForTarget:(id)target forControlEvent:(UIControlEvents)controlEvent
{
    NSMutableSet *targetActions = [NSMutableSet set];
    for (NSNumber *ce in self.eventsTargetActionsMap.allKeys) {
        if (ce.unsignedIntegerValue & controlEvent) {
            [targetActions addObjectsFromArray:[self.eventsTargetActionsMap[ce] allObjects]];
        }
    }

    NSMutableArray *actions = [NSMutableArray array];
    for (NSDictionary *ta in targetActions) {
        if (ta[@"target"] == target) [actions addObject:ta[@"action"]];
    }

    return actions.count ? actions : nil;
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    [self.application sendAction:action to:target from:self forEvent:event];
}

- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents
{
    for (id target in self.allTargets.allObjects) {
        NSArray *actions = [self actionsForTarget:target forControlEvent:controlEvents];
        for (NSString *action in actions) {
            [self sendAction:NSSelectorFromString(action) to:target forEvent:nil];
        }
    }
}

#pragma mark Notifications

- (void)textViewDidBeginEditing:(NSNotification *)notification
{
    [self forwardControlEvent:UIControlEventEditingDidBegin fromSender:notification.object];
}

- (void)textViewChanged:(NSNotification *)notification
{
    [self forwardControlEvent:UIControlEventEditingChanged fromSender:notification.object];
}

- (void)textViewDidEndEditing:(NSNotification *)notification
{
    [self forwardControlEvent:UIControlEventEditingDidEnd fromSender:notification.object];
}

- (void)forwardControlEvent:(UIControlEvents)controlEvent fromSender:(id)sender
{
    NSArray *events = self.eventsTargetActionsMap.allKeys;
    for (NSNumber *ce in events) {
        if (ce.unsignedIntegerValue & controlEvent) {
            NSMutableSet *targetActions = self.eventsTargetActionsMap[ce];
            for (NSDictionary *ta in targetActions) {
                [ta[@"target"] performSelector:NSSelectorFromString(ta[@"action"])
                                    withObject:sender];
            }
        }
    }
}

#pragma mark Private

- (NSMutableDictionary *)eventsTargetActionsMap
{
    NSMutableDictionary *eventsTargetActionsMap = objc_getAssociatedObject(self, UIControlEventsTargetActionsMapKey);
    if (eventsTargetActionsMap == nil) {
        eventsTargetActionsMap = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(
            self,
            UIControlEventsTargetActionsMapKey,
            eventsTargetActionsMap,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC
        );
    }
    return eventsTargetActionsMap;
}

- (NSNotificationCenter *)notificationCenter
{
    return [NSNotificationCenter defaultCenter];
}

- (UIApplication *)application
{
    return UIApplication.sharedApplication;
    
}

@end
