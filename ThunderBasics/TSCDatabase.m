//
//  TSCDatabase.m
//  ThunderBasics
//
//  Created by Phillip Caudell on 18/02/2014.
//  Copyright (c) 2014 3 SIDED CUBE. All rights reserved.
//

#import "TSCDatabase.h"
#import "FMDatabase.h"
#import "TSCObject.h"

@interface TSCDatabase ()

@property (nonatomic, strong) NSMutableDictionary *map;

- (instancetype)initDatabaseManager;
+ (instancetype)databaseManager;

@end

@implementation TSCDatabase

static TSCDatabase *databaseManager = nil;

- (instancetype)initDatabaseManager
{
    if (self = [super init]) {
        
        self.map = [NSMutableDictionary dictionary];
    }
    
    return self;
}

+ (instancetype)databaseManager
{
    @synchronized(self) {
        
        if (databaseManager == nil) {
            databaseManager = [[self alloc] initDatabaseManager];
        }
    }
    
    return databaseManager;
}

+ (instancetype)databaseWithPath:(NSString *)path
{
    TSCDatabase *database = [[TSCDatabase alloc] initWithDatabasePath:path];
    
    return database;
}

- (instancetype)initWithDatabasePath:(NSString *)path
{
    if (self = [super init]) {
        
        self.databasePath = path;
        
        [self TSC_setupWithPath:path];
    }
    
    return self;
}

- (void)TSC_setupWithPath:(NSString *)path
{
    NSString *databaseName = [self.databasePath lastPathComponent];
    NSString *cachedDatabasePath = [self.databaseCacheDirectory stringByAppendingPathComponent:databaseName];
    
    BOOL isDatabaseInCache = [[NSFileManager defaultManager] fileExistsAtPath:cachedDatabasePath];
    
    if (!isDatabaseInCache) {
        
        [[NSFileManager defaultManager] copyItemAtPath:path toPath:cachedDatabasePath error:nil];
    }
    
    _cachedDatabasePath = cachedDatabasePath;
}

- (NSString *)databaseCacheDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

+ (void)registerClass:(Class)classToRegister toTableName:(NSString *)tableName
{
    [[[TSCDatabase databaseManager] map] setObject:tableName forKey:NSStringFromClass(classToRegister)];
}

- (BOOL)insertObject:(TSCObject *)object
{
    FMDatabase *db = [FMDatabase databaseWithPath:self.cachedDatabasePath];
    [db open];
    
    NSDictionary *queryInfo = [self TSC_queryInfoWithObject:object];
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", queryInfo[@"table"], queryInfo[@"scheme"], queryInfo[@"values"]];
    
    BOOL result = [db executeUpdate:query withParameterDictionary:object.serialisableRepresentation];
    
    [db close];
    
    return result;
}

- (BOOL)removeObject:(TSCObject *)object
{
    FMDatabase *db = [FMDatabase databaseWithPath:self.cachedDatabasePath];
    [db open];
    
    NSDictionary *queryInfo = [self TSC_queryInfoWithObject:object];
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = (:identifier)", queryInfo[@"table"]];
    
    BOOL result = [db executeUpdate:query withParameterDictionary:object.serialisableRepresentation];
    
    [db close];
    
    return result;
}

- (BOOL)updateObject:(TSCObject *)object
{
    FMDatabase *db = [FMDatabase databaseWithPath:self.cachedDatabasePath];
    [db open];
    
    NSDictionary *queryInfo = [self TSC_queryInfoWithObject:object];
    NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE identifier = (:identifier)", queryInfo[@"table"], queryInfo[@"keyAndValues"]];
    
    BOOL result = [db executeUpdate:query withParameterDictionary:object.serialisableRepresentation];
    
    [db close];
    
    return result;
}

- (NSArray *)objectsOfClass:(Class)classToSelect
{
    return [self objectsOfClass:classToSelect withSQL:nil];
}

- (NSArray *)objectsOfClass:(Class)classToSelect withSQL:(NSString *)sql
{
    FMDatabase *db = [FMDatabase databaseWithPath:self.cachedDatabasePath];
    [db open];
    
    NSMutableArray *objects = [NSMutableArray array];
    
    NSString *table = [[TSCDatabase databaseManager] map][NSStringFromClass(classToSelect)];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ", table];
    
    if (sql) {
        query = [query stringByAppendingString:sql];
    }
    
    FMResultSet *result = [db executeQuery:query];
    
    while ([result next]) {
        
        TSCObject *object = [[classToSelect alloc] initWithDictionary:[result resultDictionary]];
        [objects addObject:object];
    }
    
    return objects;
}

- (NSDictionary *)TSC_queryInfoWithObject:(TSCObject *)object
{
    NSDictionary *dictionary = object.serialisableRepresentation;
    NSString *values = [@":" stringByAppendingString:[dictionary.allKeys componentsJoinedByString:@", :"]];
    NSString *scheme = [dictionary.allKeys componentsJoinedByString:@", "];
    NSString *table = [[TSCDatabase databaseManager] map][NSStringFromClass([object class])];
    
    NSMutableArray *keyAndValues = [NSMutableArray array];
    
    for (NSString *key in dictionary.allKeys) {
        
        NSString *keyAndValue = [NSString stringWithFormat:@"%@ = :%@", key, key];
        [keyAndValues addObject:keyAndValue];
    }
    
    NSString *keyAndValuesJoined = [keyAndValues componentsJoinedByString:@", "];
    
    return @{@"table": table, @"scheme" : scheme, @"values" : values, @"keyAndValues" : keyAndValuesJoined};
}

@end
