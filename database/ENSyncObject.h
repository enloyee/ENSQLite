//
//  ENSyncObject.h
//  Jacob's Menu
//
//  Created by enloyee on 11-11-14.
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import "ENDatabaseObject.h"

@interface ENSyncObject : ENDatabaseObject

@property (readonly, retain, nonatomic) NSDate *createDate;
@property (readonly, retain, nonatomic) NSDate *updateDate;

@end
