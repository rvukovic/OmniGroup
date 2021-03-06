// Copyright 2006-2008, 2010-2012 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#define STEnableDeprecatedAssertionMacros
#import "OFTestCase.h"

#import <OmniFoundation/OFRelativeDateParser.h>

#import <OmniFoundation/OFRegularExpression.h>
#import <OmniFoundation/OFRegularExpressionMatch.h>
#import <OmniFoundation/OFRandom.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import "OFRelativeDateParser-Internal.h"

#import <OmniBase/OmniBase.h>


RCS_ID("$Id$")


@interface OFRelativeDateParserTests : OFTestCase
{
    NSCalendar *calendar;
    OFRandomState *randomState;
    NSArray *dateFormats;
    NSArray *timeFormats;
    //NSDateFormatter *formatter;
    
}
//+ (NSDate *)_dateFromYear:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second;
@end

static NSDate *_dateFromYear(NSInteger year, NSInteger month, NSInteger day, NSInteger hour, NSInteger minute, NSInteger second, NSCalendar *cal)
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    NSDate *result = [cal dateFromComponents:components];
    [components release];
    return result;
}

static unsigned int range(OFRandomState *state, unsigned int min, unsigned int max)
{
    return min + OFRandomNextState32(state)%(max - min);
}

static BOOL _testRandomDate(OFRandomState *state, NSString *shortFormat, NSString *mediumFormat, NSString *longFormat, NSString *timeFormat)
{
    NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    
    // specifically set en_US, to make this pass if the user's current locale is ja_JP.
    [calendar setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];

    NSString *testDateString = @""; //construct the natural language string
    
    NSDateComponents *testDateComponents = [[[NSDateComponents alloc] init] autorelease];
    
    OFRelativeDateParser *parser = [OFRelativeDateParser sharedParser];
    
    NSString *dateFormat = shortFormat;
    static OFRegularExpression *formatseparatorRegex = nil;
    if (!formatseparatorRegex)
	formatseparatorRegex = [[OFRegularExpression alloc] initWithString:@"^\\w+([\\./-])"];
//    OFRegularExpressionMatch *formattedDateMatch = [formatseparatorRegex matchInString:dateFormat];
//    NSString *formatStringseparator = nil;
//    if (formattedDateMatch) {
//	formatStringseparator = [formattedDateMatch subexpressionAtIndex:0];
//	if ([formatStringseparator isEqualToString:@"-"]) 
//	    isDashed = YES;
//    }
    
    DatePosition datePosition;
    
    //	datePosition.year = 1;
    //	datePosition.month = 2;
    //	datePosition.day = 3;
    //	datePosition.separator = formatStringseparator;
    //    } else
    datePosition = [parser _dateElementOrderFromFormat:dateFormat];
    NSString *separator = datePosition.separator;
    
    int month = range(state, 1, 12);
    int day;
    if (month == 2)
	day = range(state, 1,28);
    else if (month == 10 || month == 4 || month == 6 || month == 11)
	day = range(state, 1,30);
    else
	day = range(state, 1,31);
    int year = range(state, 1990, 2007);
    
    if ([NSString isEmptyString:separator]) {
	NSString *dayString;
	if (day < 10) 
	    dayString = [NSString stringWithFormat:@"0%d", day];
	else
	    dayString = [NSString stringWithFormat:@"%d", day];
	
	NSString *monthString;
	if (month < 10) 
	    monthString = [NSString stringWithFormat:@"0%d", month];
	else
	    monthString = [NSString stringWithFormat:@"%d", month];
	
	testDateString = [NSString stringWithFormat:@"%d%@%@%@%@", year, separator, monthString, separator, dayString];
    } else {
	if (datePosition.day == 1) {
	    if (datePosition.month == 2) {
		// d m y
		testDateString = [NSString stringWithFormat:@"%d%@%d%@%d", day, separator, month, separator, year];
	    } else {
		// d y m
		OBASSERT_NOT_REACHED("years don't come second");
	    }
	} else if (datePosition.day == 2 ) {
	    if (datePosition.month == 1) {
		// m d y
		testDateString = [NSString stringWithFormat:@"%d%@%d%@%d", month, separator, day, separator, year];
	    } else {
		// y d m
		testDateString = [NSString stringWithFormat:@"%d%@%d%@%d", year, separator, day, separator, month];
	    }
	} else {
	    if (datePosition.month == 1) {
		// m y d
		OBASSERT_NOT_REACHED("years don't come second");
	    } else {
		// y m d
		testDateString = [NSString stringWithFormat:@"%d%@%d%@%d", year, separator, month, separator, day];
	    }
	}
    }
    
    [testDateComponents setDay:day];
    [testDateComponents setMonth:month];
    [testDateComponents setYear:year];
    
    int minute = range(state, 1,60);
    [testDateComponents setMinute:minute];
    
    BOOL hasSeconds = [timeFormat containsString:@"s"];
    int second = 0;
    if (hasSeconds) {
	second = range(state, 1,60);
	[testDateComponents setSecond:second];
    }
    
    int hour;
    if ([timeFormat containsString:@"H"] || [timeFormat containsString:@"k"]) {
	hour = range(state, 0,23);
	if (hasSeconds) 
	    testDateString = [testDateString stringByAppendingFormat:@" %d:%d:%d", hour, minute, second];
	else
	    testDateString = [testDateString stringByAppendingFormat:@" %d:%d", hour, minute];
    } else { 
	hour = range(state, 1,12);
	int am = range(state, 0,1);
	NSString *meridian = @"PM";
	if (am)
	    meridian = @"PM";
	if (hasSeconds)
	    testDateString = [testDateString stringByAppendingFormat:@" %d:%d:%d %@", hour, minute, second, meridian];
	else 
	    testDateString = [testDateString stringByAppendingFormat:@" %d:%d %@", hour, minute, meridian];
	if (!am && hour < 12)
	    hour += 12;
    }
    [testDateComponents setHour:hour];
    
    NSDate *testDate = [calendar dateFromComponents:testDateComponents];
    
    
    NSDate *baseDate = _dateFromYear(2007, 1, 1, 0, 0, 0, calendar);
    NSDate *testResult, *result = nil; 
    [[OFRelativeDateParser sharedParser] getDateValue:&testResult forString:testDateString fromStartingDate:baseDate calendar:calendar withShortDateFormat:shortFormat withMediumDateFormat:mediumFormat withLongDateFormat:longFormat withTimeFormat:timeFormat error:nil]; 
    
    NSString *stringBack = [[OFRelativeDateParser sharedParser] stringForDate:testDate withDateFormat:dateFormat withTimeFormat:timeFormat calendar:calendar];
    [[OFRelativeDateParser sharedParser] getDateValue:&result forString:stringBack fromStartingDate:baseDate calendar:calendar withShortDateFormat:shortFormat withMediumDateFormat:mediumFormat withLongDateFormat:longFormat withTimeFormat:timeFormat error:nil]; 
    
    if ([testResult isEqual:testDate] && [result isEqual:testDate]) 
	return YES;
    else {
	NSLog( @"RandomTestDate: %@, dateFormat: %@, timeFormat: %@", testDate, dateFormat, timeFormat);
	if (![result isEqual:testDate])
	    NSLog( @"string back failure: %@, Result:%@ expected:%@", stringBack, result, testDate );
	
	if (![testResult isEqual:testDate])
	    NSLog (@"--failure testDateString: %@, stringBack: %@,  testResult: %@, expected: %@", testDateString, stringBack, testResult, testDate);
    }
    
    return NO;
}


@implementation OFRelativeDateParserTests

- (void)setUp;
{
    const char *env = getenv("DataGeneratorSeed");
    if (env) {
        uint32_t seed = (uint32_t)strtoul(env, NULL, 0);
        randomState = OFRandomStateCreateWithSeed32(&seed, 1);
    } else
        randomState = OFRandomStateCreate();
    
    // Default to en_US instead of the user's locale for now (in the tests only). Some tests will override this.
    [[OFRelativeDateParser sharedParser] setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
     
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    // specifically set en_US, to make this pass if the user's current locale is ja_JP.
    [calendar setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];

    dateFormats = [[NSArray alloc] initWithObjects:@"MM/dd/yy", @"MM/dd/yyyy", @"dd/MM/yy", @"dd/MM/yyyy", @"yyyy-MM-dd", @"MM.dd.yy", @"dd.MM.yy", @"d-MMM-yy", nil];
    timeFormats = [[NSArray alloc] initWithObjects:@"hh:mm a", @"hh:mm:ss a", @"HH:mm:ss", @"HH:mm", @"HHmm", @"kk:mm", @"kkmm", nil];
}

- (void)tearDown;
{
    OFRandomStateDestroy(randomState);
    randomState = NULL;
    
    [calendar release];
    calendar = nil;
    
    [dateFormats release];
    dateFormats = nil;
    
    [timeFormats release];
    timeFormats = nil;
    
    [super tearDown];
}

#define parseDate(string, expectedDate, baseDate, dateFormat, timeFormat) \
do { \
    NSDate *result = nil; \
    [[OFRelativeDateParser sharedParser] getDateValue:&result forString:string fromStartingDate:baseDate calendar:calendar withShortDateFormat:dateFormat withMediumDateFormat:dateFormat withLongDateFormat:dateFormat withTimeFormat:timeFormat error:nil]; \
    if (expectedDate && ![result isEqualTo:expectedDate]) \
        NSLog( @"FAILURE-> String: %@, locale:%@, result:%@, expected: %@ dateFormat:%@, timeFormat:%@", string, [[[OFRelativeDateParser sharedParser] locale] localeIdentifier], result, expectedDate, dateFormat, timeFormat); \
    shouldBeEqual(result, expectedDate); \
} while(0)
//NSLog( @"string: %@, expected: %@, result: %@", string, expectedDate, result );

- (void)testDayWeekCodes;
{
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 >= MAC_OS_X_VERSION_MIN_REQUIRED
    NSLog(@"Skipping test that fails due to bug in 10A222.");
#else
    NSString *timeFormat = @"h:mm a";
    NSString *dateFormat = @"d-MMM-yy";

    // now, should be this instant
    NSString *string = @" thu+1w";
    NSDate *baseDate     = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
    NSDate *expectedDate = _dateFromYear(2001, 1, 11, 0, 0, 0, calendar);
    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
#endif
}

- (void)testRelativeDateNames;
{
    // test our relative date names
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	    
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    // now, should be this instant
	    NSString *string = @"now";
	    NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    NSDate *expectedDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    // should be 12pm of today
	    string = @"noon";
	    baseDate     = _dateFromYear(2001, 1, 1, 15, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 12, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"tonight";
	    baseDate     = _dateFromYear(2001, 1, 1, 15, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 23, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    [pool drain];
	}
    }
}

- (void)testFriNoon;
{
    //test setting the date with year-month-day even when the date format is d/m/y
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    // skip we have crazy candian dates, this combo is just messed up
	    if (![dateFormat containsString:@"MMM"]) {
		NSString *string = @"fri noon";
		NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
		NSDate *expectedDate = _dateFromYear(2001, 1, 5, 12, 0, 0, calendar);
		parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    }
	}
    }
}

- (void)testCanada;
{
    // test using canada's date formats
    [calendar autorelease];
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    // specifically set en_US, to make this pass if the user's current locale is ja_JP.
    [calendar setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
     
    NSString *timeFormat = @"h:mm a";
    NSString *dateFormat = @"d-MMM-yy";
    should(_testRandomDate(randomState, dateFormat, dateFormat, dateFormat, timeFormat));
    
}

- (void)testSweden;
{
    //test setting the date with year-month-day even when the date format is d/m/y
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    // skip we have crazy candian dates, this combo is just messed up
	    if (![dateFormat containsString:@"MMM"]) {
		NSString *string = @"1997-12-29";
		NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
		NSDate *expectedDate = _dateFromYear(1997, 12, 29, 0, 0, 0, calendar);
		parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    }
	}
    }
}

- (void)testFrench;
{
    NSLocale *savedLocale = [[[[OFRelativeDateParser sharedParser] locale] retain] autorelease];

    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"fr"];
    [[OFRelativeDateParser sharedParser] setLocale:locale];
    [locale release];

    NSDate *baseDate = nil;
    NSDate *expectedDate = nil;
        
    // We have to test French "tomorrow" as "tomorrow", not "demain", because we don't have localized resources
    baseDate = _dateFromYear(2011, 7, 15, 0, 0, 0, calendar);
    expectedDate = _dateFromYear(2011, 7, 16, 0, 0, 0, calendar);
    parseDate( @"tomorrow", expectedDate, baseDate, nil, nil ); 
    
    baseDate = _dateFromYear(2011, 7, 15, 0, 0, 0, calendar);
    expectedDate = _dateFromYear(2012, 12, 29, 0, 0, 0, calendar);
    parseDate( @"29 dec. 2012", expectedDate, baseDate, nil, nil ); 

    NSString *dateString = [NSString stringWithFormat:@"29 d%Cc. 2012", (unichar)0xE9];
    parseDate( dateString, expectedDate, baseDate, nil, nil ); 

    [[OFRelativeDateParser sharedParser] setLocale:savedLocale];
}

- (void)testSpanish;
{
    NSLocale *savedLocale = [[[[OFRelativeDateParser sharedParser] locale] retain] autorelease];

    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"es"];
    [[OFRelativeDateParser sharedParser] setLocale:locale];
    [locale release];

    // We expected to get tuesday, not "mar"=>March/Marzo then nil because of the extra input
    // See <bug:///73211> (OFRelativeDateParser doesn't use localized string/abbreviation when parsing out hours)
    
    NSDate *baseDate = nil;
    NSDate *expectedDate = nil;
    
    baseDate = _dateFromYear(2011, 6, 29, 0, 0, 0, calendar);
    expectedDate = _dateFromYear(2011, 7, 5, 0, 0, 0, calendar);
    parseDate( @"martes", expectedDate, baseDate, nil, nil ); 
    
    // We expect to be able to use either miercoles for mi�rcoles for wednesday and have it work
    
    baseDate = _dateFromYear(2011, 7, 5, 0, 0, 0, calendar);
    expectedDate = _dateFromYear(2011, 7, 6, 0, 0, 0, calendar);
    parseDate( @"miercoles", expectedDate, baseDate, nil, nil ); 

    NSString *dateString = [NSString stringWithFormat:@"mi%Crcoles", (unichar)0xE9];
    parseDate( dateString, expectedDate, baseDate, nil, nil ); 
    

    [[OFRelativeDateParser sharedParser] setLocale:savedLocale];
}

- (void)testItalian;
{
    NSLocale *savedLocale = [[[[OFRelativeDateParser sharedParser] locale] retain] autorelease];

    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"it"];
    [[OFRelativeDateParser sharedParser] setLocale:locale];
    [locale release];

    // We expected to get tuesday, not "mar"=>March/Marzo then nil because of the extra input
    // See <bug:///68115> (Italian localization for Sunday doesn't parse in cells [natural language, Domenica])
    
    NSDate *baseDate = nil;
    NSDate *expectedDate = nil;
    NSString *dateString = nil;
    
    baseDate = _dateFromYear(2011, 6, 29, 0, 0, 0, calendar);
    expectedDate = _dateFromYear(2011, 7, 5, 0, 0, 0, calendar);
    dateString = [NSString stringWithFormat:@"marted%C", (unichar)0xEC];
    parseDate( dateString, expectedDate, baseDate, nil, nil ); 

    baseDate = _dateFromYear(2011, 7, 5, 0, 0, 0, calendar);
    expectedDate = _dateFromYear(2011, 7, 10, 0, 0, 0, calendar);
    dateString = @"domenica";
    parseDate( dateString, expectedDate, baseDate, nil, nil ); 

    [[OFRelativeDateParser sharedParser] setLocale:savedLocale];
}

- (void)testGerman;
{
    NSLocale *savedLocale = [[[[OFRelativeDateParser sharedParser] locale] retain] autorelease];

    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de"];
    [[OFRelativeDateParser sharedParser] setLocale:locale];
    [locale release];

    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setLocale:locale];

    // We expect to be able to get dates back for German days of the week whether or not we include punctuation at the end of the abbreviated day name

    NSDate *baseDate = _dateFromYear(2011, 7, 3, 0, 0, 0, calendar);;
    NSDate *expectedDate = nil;

    NSUInteger i, count = [[dateFormatter shortWeekdaySymbols] count];
    for (i = 0; i < count; i++) {
        NSString *dayName = [[dateFormatter shortWeekdaySymbols] objectAtIndex: i];
        
        expectedDate = _dateFromYear(2011, 7, 3 + i, 0, 0, 0, calendar);
        parseDate( dayName, expectedDate, baseDate, nil, nil ); 

        dayName = [dayName stringByReplacingCharactersInSet:[NSCharacterSet punctuationCharacterSet] withString:@""];
        parseDate( dayName, expectedDate, baseDate, nil, nil ); 
    }

    [[OFRelativeDateParser sharedParser] setLocale:savedLocale];
}

- (void)testRandomCases;
{
    NSString *timeFormat = @"HH:mm";
    NSString *dateFormat = @"d-MMM-yy";
    
    NSString *string = @"1-Jul-00 11:02";
    NSDate *baseDate = _dateFromYear(2000, 1, 1, 1, 1, 0, calendar);
    NSDate *expectedDate = _dateFromYear(2000, 7, 1, 11, 2, 0, calendar);
    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
    
    timeFormat = @"hh:mm a";
    dateFormat = @"MM.dd.yy";
    string = @"04.13.00 03:05 PM";
    baseDate = _dateFromYear(2000, 1, 1, 1, 1, 0, calendar);
    expectedDate = _dateFromYear(2000, 4, 13, 15, 5, 0, calendar);
    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
}

-(void)testNil;
{
    [calendar autorelease];
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *baseDate = _dateFromYear(2007, 1, 1, 1, 1, 0, calendar);
    NSString *string = @"";
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    parseDate( string, nil, baseDate, dateFormat, timeFormat );   
	}
    }
}

- (void)testDegenerates;
{
    // test with all different formats
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	    
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    NSString *string = @" 2 weeks";
	    NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    NSDate *expectedDate = _dateFromYear(2001, 1, 15, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"1d 12 pm";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 2, 12, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"1d 12pm";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 2, 12, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"1d 2 pm";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 2, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"1d 2pm";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 2, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @" 2 p";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @" 2p";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @" 2 PM";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @" 2PM";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @" 2 P";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @" 2P";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 1, 14, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"2";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 1, 2, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
            
            [pool drain];
	}
    }
}

- (void)testBugs;
{
    // test with all different formats
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    // <bug://bugs/37222> ("4 may" is interpreted at 4 months)
	    NSString *string = @"4 May";
	    NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    NSDate *expectedDate = _dateFromYear(2001, 5, 4, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"may 4";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2001, 5, 4, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );	    
	    
	    // <bug://bugs/37216> (Entering a year into date fields doesn't work)
	    string = @"2008";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    if ([timeFormat isEqualToString:@"HHmm"] || [timeFormat isEqualToString:@"kkmm"]) {
		expectedDate = _dateFromYear(2001, 1, 1, 20, 8, 0, calendar);
		parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    } else {
		expectedDate = _dateFromYear(2008, 1, 1, 0, 0, 0, calendar);
		parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    }
	    
	    // <bug://bugs/37219> ("this year" and "next year" work in date formatter, but "last year" does not)
	    string = @"last year";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2000, 1, 1, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    
	    string = @"next year";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(2002, 1, 1, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    
	    // test tomorrow
	    string = @"tomorrow";
	    baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar); // y m d h m s
	    expectedDate = _dateFromYear(2001, 1, 2, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    
	    
	}
    }
}

- (void)testSeperatedDates;
{
    // test with all different formats
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    // 23th of may, 1979
	    NSString *string = @"23 May 1979";
	    NSDate *baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
	    NSDate *expectedDate = _dateFromYear(1979, 5, 23, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	    
	    string = @"may-23-1979";
	    baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(1979, 5, 23, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );	    
	    
	    string = @"5-23-1979";
	    baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(1979, 5, 23, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    
	    string = @"5 23 1979";
	    baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(1979, 5, 23, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    
	    string = @"5/23/1979";
	    baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(1979, 5, 23, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	    
	    string = @"5.23.1979";
	    baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
	    expectedDate = _dateFromYear(1979, 5, 23, 0, 0, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  );
	}
    }
}

- (void)testErrors;
{
    NSString *timeFormat = @"hh:mm";
    NSString *dateFormat = @"m/d/yy";
    
    NSString *string = @"jan 1 08";
    NSDate *baseDate = _dateFromYear(1979, 1, 1, 0, 0, 0, calendar);
    NSDate *expectedDate = _dateFromYear(2008, 1, 1, 0, 0, 0, calendar);
    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
}

- (void)testAt;
{
    // test with all different formats
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    NSString *string = @"may 4 1997 at 3:07pm";
	    NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    NSDate *expectedDate = _dateFromYear(1997, 5, 4, 15, 7, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	}
    }
}

- (void)testTwentyFourHourTime;
{
    // test with all different formats
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    // <bug://bugs/37104> (Fix 24hour time support in OFRelativeDateParser)
	    NSString *string = @"19:59";
	    NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	    NSDate *expectedDate = _dateFromYear(2001, 1, 1, 19, 59, 0, calendar);
	    parseDate( string, expectedDate, baseDate,  dateFormat, timeFormat  ); 
	}
    }
}

- (void)testRandomDatesAndRoundTrips;
{
    // test with all different formats
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    should(_testRandomDate(randomState, dateFormat, dateFormat, dateFormat, timeFormat));
	}
    }
}

- (void)testLocaleWeekdays;
{
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSArray *availableLocales = [NSArray arrayWithObjects:@"de", /*@"es",*/ @"fr", @"en_US", /*@"it",*/ @"ja", @"nl", @"zh_CN", nil];//[NSLocale availableLocaleIdentifiers];
    unsigned int localeIndex;
    for (localeIndex = 0; localeIndex < [availableLocales count]; localeIndex++) {
	NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:[availableLocales objectAtIndex:localeIndex]] autorelease];
	[[OFRelativeDateParser sharedParser] setLocale:locale];
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease]; 
	[formatter setLocale:locale];
	
	NSArray *weekdays = [formatter weekdaySymbols];
	NSDate *baseDate = _dateFromYear(2001, 1, 10, 0, 0, 0, calendar);
	NSDateComponents *components = [calendar components:NSWeekdayCalendarUnit fromDate:baseDate];

	// test with all different formats
	NSUInteger dateIndex = [dateFormats count];
	while (dateIndex--) {
	    NSUInteger timeIndex = [timeFormats count];
	    while (timeIndex--) {
		NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
		NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
		
		NSUInteger dayIndex = [weekdays count];
		NSInteger weekday = [components weekday] - 1; // 1 based
		while (dayIndex--) {
		    NSInteger addToWeek = (dayIndex - weekday);
		    if (addToWeek < 0)
			addToWeek = 7;
		    else 
			addToWeek = 0;
		    parseDate( [weekdays objectAtIndex:dayIndex], 
			      _dateFromYear(2001, 1, (10 + addToWeek + (dayIndex - weekday)), 0, 0, 0, calendar),
			      baseDate, dateFormat, timeFormat);
		}
		
		weekdays = [formatter shortWeekdaySymbols];
		dayIndex = [weekdays count];
		while (dayIndex--) {
		    NSInteger addToWeek = (dayIndex - weekday);
		    if (addToWeek < 0)
			addToWeek = 7;
		    else 
			addToWeek = 0;
                        
		    parseDate( [weekdays objectAtIndex:dayIndex], 
			      _dateFromYear(2001, 1, (10 + addToWeek + (dayIndex - weekday)), 0, 0, 0, calendar),
			      baseDate, dateFormat, timeFormat);
		}
	    }
	}
    }
    [[OFRelativeDateParser sharedParser] setLocale:currentLocale];
}

- (void)testLocaleMonths;
{
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSArray *availableLocales = [NSArray arrayWithObjects:@"de", @"es", @"fr", @"en_US", @"it", /*@"ja",*/ @"nl", @"zh_CN", nil];//[NSLocale availableLocaleIdentifiers]; // TODO: Figure out why -testLocaleMonths fails for Japanese
    unsigned int localeIndex;
    for (localeIndex = 0; localeIndex < [availableLocales count]; localeIndex++) {
	NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:[availableLocales objectAtIndex:localeIndex]] autorelease];
	[[OFRelativeDateParser sharedParser] setLocale:locale];
	
	
        [calendar autorelease];
	calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	
	[formatter setLocale:locale];
	NSArray *months = [formatter monthSymbols];
	NSDate *baseDate = _dateFromYear(2001, 1, 1, 0, 0, 0, calendar);
	
        NSArray *shortdays = [NSSet setWithArray:[formatter shortWeekdaySymbols]];

	NSDateComponents *components = [calendar components:NSMonthCalendarUnit fromDate:baseDate];
	
	NSUInteger dateIndex = [dateFormats count];
	while (dateIndex--) {
	    NSUInteger timeIndex = [timeFormats count];
	    while (timeIndex--) {
		NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
		NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
		
		NSUInteger monthIndex = [months count];
		NSUInteger month = [components month] - 1; // 1 based
		while (monthIndex--) {
		    NSInteger addToMonth = (monthIndex - month);
		    if (addToMonth < 0)
			addToMonth = 12;
		    else 
			addToMonth = 0;
                        
                    // If the short month symbol is also a short day symbol, skip it. We prioritize days
                    if ([shortdays containsObject:[months objectAtIndex:monthIndex]])
                        continue;

		    parseDate( [months objectAtIndex:monthIndex], 
			      _dateFromYear(2001, (1 + addToMonth + (monthIndex - month)), 1, 0, 0, 0, calendar),
			      baseDate,  dateFormat, timeFormat );
		}
		
		months = [formatter shortMonthSymbols];
		
		monthIndex = [months count];
		while (monthIndex--) {
		    NSInteger addToMonth = (monthIndex - month);
		    if (addToMonth < 0)
			addToMonth = 12;
		    else 
			addToMonth = 0;

                    // If the short month symbol is also a short day symbol, skip it. We prioritize days
                    if ([shortdays containsObject:[months objectAtIndex:monthIndex]])
                        continue;

		    parseDate( [months objectAtIndex:monthIndex], 
			      _dateFromYear(2001, (1 + addToMonth + (monthIndex - month)), 1, 0, 0, 0, calendar),
			      baseDate,  dateFormat, timeFormat );
		}
	    }
	}
    }
    [[OFRelativeDateParser sharedParser] setLocale:currentLocale];
}


- (void)testTimes;
{
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];
	    
	    parseDate( @"1d@5:45:1", 
		      _dateFromYear(2001, 1, 2, 5, 45, 1, calendar),
		      _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),  dateFormat, timeFormat  );
	    parseDate( @"@17:45", 
		      _dateFromYear(2001, 1, 1, 17, 45, 0, calendar),
		      _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),  dateFormat, timeFormat  );
	    parseDate( @"@5:45 pm", 
		      _dateFromYear(2001, 1, 1, 17, 45, 0, calendar),
		      _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),  dateFormat, timeFormat  );
	    parseDate( @"@5:45 am", 
		      _dateFromYear(2001, 1, 1, 5, 45, 0, calendar),
		      _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),  dateFormat, timeFormat  );
	}
    }
}

- (void)testCodes;
{
    NSUInteger dateIndex = [dateFormats count];
    while (dateIndex--) {
	NSUInteger timeIndex = [timeFormats count];
	while (timeIndex--) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
	    NSString *timeFormat = [timeFormats objectAtIndex:timeIndex];
	    NSString *dateFormat = [dateFormats objectAtIndex:dateIndex];    
	    parseDate( @"-1h2h3h4h+1h2h3h4h", 
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"0h", 
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"1h", 
		      _dateFromYear(2001, 1, 1, 2, 1, 1, calendar),
		      _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),  dateFormat, timeFormat  );
	    parseDate( @"+1h1h", 
		      _dateFromYear(2001, 1, 1, 3, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 1, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"-1h", 
		      _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
		      _dateFromYear(2001, 1, 1, 2, 1, 1, calendar),  dateFormat, timeFormat  );
	    
	    parseDate( @"0d", 
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"1d", 
		      _dateFromYear(2001, 1, 2, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"+1d", 
		      _dateFromYear(2001, 1, 2, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"-1d", 
		      _dateFromYear(2000, 12, 31, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    
	    parseDate( @"0w", 
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"1w", 
		      _dateFromYear(2001, 1, 8, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"+1w", 
		      _dateFromYear(2001, 1, 8, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"-1w", 
		      _dateFromYear(2000, 12, 25, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    
	    parseDate( @"0m", 
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"1m", 
		      _dateFromYear(2001, 2, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"+1m", 
		      _dateFromYear(2001, 2, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"-1m", 
		      _dateFromYear(2000, 12, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    
	    parseDate( @"0y", 
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"1y", 
		      _dateFromYear(2002, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"+1y", 
		      _dateFromYear(2002, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
	    parseDate( @"-1y", 
		      _dateFromYear(2000, 1, 1, 0, 0, 0, calendar),
		      _dateFromYear(2001, 1, 1, 0, 0, 0, calendar),  dateFormat, timeFormat  );
            
            [pool drain];
	}
    }
}


@end
