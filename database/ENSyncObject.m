//
//  ENSyncObject.m
//  Jacob's Menu
//
//  Created by enloyee on 11-11-14.
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import "ENSyncObject.h"

#define kENCreateDateKey    @"create_date"
#define kENUpdateDateKey    @"update_date"

@interface ENSyncObject()

@property (retain, nonatomic) NSDate *createDate;
@property (retain, nonatomic) NSDate *updateDate;

@end

@implementation ENSyncObject

- (id)init
{
    if (self = [super init])
    {
        self.createDate = nil;
        self.updateDate = nil;
    }
    return self;
}

- (NSDate *)createDate
{
    double value = [self doubleForKey:kENCreateDateKey];
    return [NSDate dateWithTimeIntervalSince1970:value];
}

- (void)setCreateDate:(NSDate *)createDate
{
    [self setDouble:[createDate timeIntervalSince1970] forKey:kENCreateDateKey];
}

- (NSDate *)updateDate
{
    double value = [self doubleForKey:kENUpdateDateKey];
    return [NSDate dateWithTimeIntervalSince1970:value];
}

- (void)setUpdateDate:(NSDate *)updateDate
{
    [self setDouble:[updateDate timeIntervalSince1970] forKey:kENUpdateDateKey];
}

- (BOOL)store
{
    return [self storeUseTransactions:YES];
}

- (BOOL)storeUseTransactions:(BOOL)useTransactions
{
    BOOL update = [self isSaved];
    NSDate *date = [NSDate date];
    if (update)
        self.updateDate = date;
    else
    {
        self.createDate = date;
        self.updateDate = date;
    }
    
    return [super storeUseTransactions:useTransactions];
}

@end
