//
//  BRCEventObject.m
//  iBurn
//
//  Created by Christopher Ballinger on 7/28/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import "BRCEventObject.h"
#import "NSDictionary+MTLManipulationAdditions.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "MTLValueTransformer.h"
#import "BRCEventObject_Private.h"
#import "UIColor+iBurn.h"
#import "NSDateFormatter+iBurn.h"
#import "BRCDatabaseManager.h"

NSString * const kBRCStartDate2015Key = @"kBRCStartDate2015Key";
NSString * const kBRCEndDate2015Key = @"kBRCEndDate2015Key";
NSString * const kBRCMajorEvents2015Key = @"kBRCMajorEvents2015Key";

NSString * const kBRCEventCampEdgeName = @"camp";
NSString * const kBRCEventArtEdgeName = @"art";


@interface BRCEventObject()
@end

@implementation BRCEventObject

- (NSTimeInterval)timeIntervalUntilStart:(NSDate*)date
{
    if (self.startDate) {
        return [self.startDate timeIntervalSinceDate:date];
    }
    return DBL_MAX;
}

- (NSTimeInterval)timeIntervalUntilEnd:(NSDate*)date
{
    if (self.endDate) {
        return [self.endDate timeIntervalSinceDate:date];
    }
    return DBL_MAX;
}

- (NSTimeInterval)timeIntervalForDuration {
    NSTimeInterval duration = [self.endDate timeIntervalSinceDate:self.startDate];
    return duration;
}

- (BOOL)isHappeningRightNow:(NSDate*)currentDate
{
    if ([self hasStarted:currentDate] && ![self hasEnded:currentDate]) {
        return YES;
    }
    return NO;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    NSDictionary *paths = [super JSONKeyPathsByPropertyKey];
    NSDictionary *artPaths = @{NSStringFromSelector(@selector(title)): @"title",
                               NSStringFromSelector(@selector(checkLocation)): @"check_location",
                               NSStringFromSelector(@selector(hostedByCampUniqueID)): @"hosted_by_camp.id",
                               NSStringFromSelector(@selector(hostedByArtUniqueID)): @"located_at_art.id",
                               NSStringFromSelector(@selector(eventType)): @"event_type.abbr",
                               NSStringFromSelector(@selector(isAllDay)): @"all_day"};
    return [paths mtl_dictionaryByAddingEntriesFromDictionary:artPaths];
}

+ (NSValueTransformer *)eventTypeJSONTransformer {
    NSDictionary *transformDict = @{@"":     @(BRCEventTypeUnknown),
                                    @"none": @(BRCEventTypeNone),
                                    @"work": @(BRCEventTypeWorkshop),
                                    @"perf": @(BRCEventTypePerformance),
                                    @"care": @(BRCEventTypeSupport),
                                    @"prty": @(BRCEventTypeParty),
                                    @"cere": @(BRCEventTypeCeremony),
                                    @"game": @(BRCEventTypeGame),
                                    @"fire": @(BRCEventTypeFire),
                                    @"adlt": @(BRCEventTypeAdult),
                                    @"kid":  @(BRCEventTypeKid),
                                    @"para": @(BRCEventTypeParade),
                                    @"food": @(BRCEventTypeFood)};
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:transformDict];
}

+ (NSValueTransformer *)hostedByCampUniqueIDJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^NSString*(NSNumber* number, BOOL *success, NSError *__autoreleasing *error) {
        return number.stringValue;
    }];
}

+ (NSValueTransformer *)hostedByArtUniqueIDJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^NSString*(NSNumber* number, BOOL *success, NSError *__autoreleasing *error) {
        return number.stringValue;
    }];
}

- (BOOL) isEndingSoon:(NSDate*)currentDate {
    NSTimeInterval endingSoonTimeThreshold = 15 * 60; // 15 minutes
    // event will end soon
    NSTimeInterval timeIntervalUntilEventEnds = [self timeIntervalUntilEnd:currentDate];
    if (timeIntervalUntilEventEnds < endingSoonTimeThreshold && timeIntervalUntilEventEnds > 0) { // event ending soon
        return YES;
    }
    return NO;
}

/**
 *  Whether or not the event starts within the next hour
 */
- (BOOL)isStartingSoon:(NSDate*)currentDate {
    NSTimeInterval startingSoonTimeThreshold = 60 * 60; // one hour
    NSTimeInterval timeIntervalUntilEventStarts = [self timeIntervalUntilStart:currentDate];
    if (![self hasStarted:currentDate] && timeIntervalUntilEventStarts < startingSoonTimeThreshold) { // event starting soon
        return YES;
    }
    return NO;
}

- (BOOL)hasStarted:(NSDate*)currentDate {
    NSTimeInterval timeIntervalUntilEventStarts = [self timeIntervalUntilStart:currentDate];
    if (timeIntervalUntilEventStarts < 0) { // event started
        return YES;
    }
    return NO;
}

- (BOOL)hasEnded:(NSDate*)currentDate {
    NSTimeInterval timeIntervalUntilEventEnds = [self timeIntervalUntilEnd:currentDate];
    if (timeIntervalUntilEventEnds < 0) { // event ended
        return YES;
    }
    return NO;
}

+ (NSDate*) festivalStartDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kBRCStartDate2015Key];
}
+ (NSDate*) festivalEndDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kBRCEndDate2015Key];
}
/** Array of titles of major events, starting with first day of events */
+ (NSArray*) majorEvents {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kBRCMajorEvents2015Key];
}

+ (NSArray*) datesOfFestival {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *festivalStartDate = [self festivalStartDate];
    NSUInteger numberOfDays = [self majorEvents].count;

    NSMutableArray *dates = [NSMutableArray arrayWithCapacity:numberOfDays];
    
    for (int i = 0; i < numberOfDays; i++) {
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = i;
        
        NSDate *nextDate = [gregorianCalendar dateByAddingComponents:dayComponent toDate:festivalStartDate options:0];
        [dates addObject:nextDate];
    }
    return dates;
}

- (UIImage *)markerImageForEventStatus:(NSDate*)currentDate
{
    if ([self isStartingSoon:currentDate]) {
        return [UIImage imageNamed:@"BRCLightGreenPin"];
    }
    if ([self isEndingSoon:currentDate]) {
        return [UIImage imageNamed:@"BRCOrangePin"];
    }
    if ([self hasEnded:currentDate]) {
        return [UIImage imageNamed:@"BRCRedPin"];
    }
    if ([self isHappeningRightNow:currentDate]) {
        return [UIImage imageNamed:@"BRCGreenPin"];
    }
    return [UIImage imageNamed:@"BRCPurplePin"];
}

- (UIColor*) colorForEventStatus:(NSDate*)currentDate {
    if ([self isStartingSoon:currentDate]) {
        return [UIColor brc_lightGreenColor];
    }
    if (![self hasStarted:currentDate]) {
        return [UIColor darkTextColor];
    }
    if ([self isEndingSoon:currentDate]) {
        return [UIColor brc_orangeColor];
    }
    if ([self hasEnded:currentDate]) {
        return [UIColor brc_redColor];
    }
    if ([self isHappeningRightNow:currentDate]) {
        return [UIColor brc_greenColor];
    }
    return [UIColor darkTextColor];
}

+ (NSString *)stringForEventType:(BRCEventType)type
{
    switch (type) {
        case BRCEventTypeWorkshop:
            return @"🔨 Workshop";
            break;
        case BRCEventTypePerformance:
            return @"💃 Performance";
            break;
        case BRCEventTypeSupport:
            return @"🏥 Support";
            break;
        case BRCEventTypeParty:
            return @"🍺 Party";
            break;
        case BRCEventTypeCeremony:
            return @"🌜Ceremony";
            break;
        case BRCEventTypeGame:
            return @"🎲 Game";
            break;
        case BRCEventTypeFire:
            return @"🔥 Fire";
            break;
        case BRCEventTypeAdult:
            return @"💋 Adult";
            break;
        case BRCEventTypeKid:
            return @"👨‍👩‍👧‍👦 Kid";
            break;
        case BRCEventTypeParade:
            return @"🎉 Parade";
            break;
        case BRCEventTypeFood:
            return @"🍔 Food";
            break;
        default:
            return @"";
            break;
    }
}

+ (void) scheduleNotificationForEvent:(BRCEventObject*)eventObject transaction:(YapDatabaseReadWriteTransaction*)transaction {
    NSParameterAssert(eventObject.isFavorite);
    NSDate *now = [NSDate date];
    if ([eventObject hasStarted:now] || [eventObject hasEnded:now]) {
        return;
    }
    if (!eventObject.scheduledNotification) {
        // remind us 30 minutes before
        NSDate *reminderDate = [eventObject.startDate dateByAddingTimeInterval:-30 * 60];
        //NSDate *testingReminderDate = [[NSDate date] dateByAddingTimeInterval:10];
        NSString *startTimeString = [[NSDateFormatter brc_timeOnlyDateFormatter] stringFromDate:eventObject.startDate];
        NSString *reminderTitle = [NSString stringWithFormat:@"%@ - %@", startTimeString, eventObject.title];
        UILocalNotification *eventNotification = [[UILocalNotification alloc] init];
        eventNotification.fireDate = reminderDate;
        eventNotification.alertBody = reminderTitle;
        eventNotification.soundName = UILocalNotificationDefaultSoundName;
        eventNotification.alertAction = @"View Event";
        eventNotification.applicationIconBadgeNumber = 1;
        NSString *key = [self localNotificationUserInfoKey];
        eventNotification.userInfo = @{key: eventObject.uniqueID};
        eventObject.scheduledNotification = eventNotification;
        [transaction setObject:eventObject forKey:eventObject.uniqueID inCollection:[BRCEventObject collection]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] scheduleLocalNotification:eventNotification];
        });
    }
}

+ (NSString*) localNotificationUserInfoKey {
    NSString *key = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(@selector(uniqueID))];
    return key;
}

+ (void) cancelScheduledNotificationForEvent:(BRCEventObject*)eventObject transaction:(YapDatabaseReadWriteTransaction*)transaction {
    NSParameterAssert(!eventObject.isFavorite);
    if (eventObject.scheduledNotification) {
        UILocalNotification *notificationToCancel = eventObject.scheduledNotification;
        eventObject.scheduledNotification = nil;
        [transaction setObject:eventObject forKey:eventObject.uniqueID inCollection:[BRCEventObject collection]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] cancelLocalNotification:notificationToCancel];
        });
    }
}

- (BRCArtObject*) hostedByArtWithTransaction:(YapDatabaseReadTransaction*)readTransaction {
    if (!self.hostedByArtUniqueID) {
        return nil;
    }
    BRCArtObject *artObject = [readTransaction objectForKey:self.hostedByArtUniqueID inCollection:[BRCArtObject collection]];
    return artObject;
}

- (BRCCampObject*) hostedByCampWithTransaction:(YapDatabaseReadTransaction*)readTransaction {
    if (!self.hostedByCampUniqueID) {
        return nil;
    }
    BRCCampObject *campObject = [readTransaction objectForKey:self.hostedByCampUniqueID inCollection:[BRCCampObject collection]];
    return campObject;
}

#pragma mark YapDatabaseRelationshipNode

// This method gets automatically called when the object is inserted/updated in the database.
- (NSArray *)yapDatabaseRelationshipEdges
{
    NSMutableArray *edges = [NSMutableArray arrayWithCapacity:2];
    
    YapDatabaseRelationshipEdge *campEdge =
    [YapDatabaseRelationshipEdge edgeWithName:kBRCEventCampEdgeName
                               destinationKey:self.hostedByCampUniqueID
                                   collection:[[BRCCampObject class] collection]
                              nodeDeleteRules:YDB_NotifyIfSourceDeleted | YDB_NotifyIfDestinationDeleted];
    if (campEdge) {
        [edges addObject:campEdge];
    }
    
    YapDatabaseRelationshipEdge *artEdge =
    [YapDatabaseRelationshipEdge edgeWithName:kBRCEventArtEdgeName
                               destinationKey:self.hostedByArtUniqueID
                                   collection:[[BRCArtObject class] collection]
                              nodeDeleteRules:YDB_NotifyIfSourceDeleted | YDB_NotifyIfDestinationDeleted];
    
    if (artEdge) {
        [edges addObject:artEdge];
    }
    
    return edges;
}

@end