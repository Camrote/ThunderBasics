//
//  TSCPerson.h
//  Thunder Alert
//
//  Created by Sam Houghton on 28/11/2014.
//  Copyright (c) 2014 3 SIDED CUBE. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AddressBook;
@import UIKit;

@interface TSCPerson : NSObject

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, strong) NSArray *numbers;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) UIImage *largeImage;
@property (nonatomic, strong) NSNumber *recordNumber;
@property (nonatomic, copy) NSString *mobileNumber;
@property (nonatomic, assign) BOOL hasPlaceholderImage;
@property (nonatomic, strong) id <NSObject> observer;

- (instancetype)initWithABRecordRef:(ABRecordRef)ref;
- (void)updateWithABRecordRef:(ABRecordRef)ref;
- (NSString *)initials;
- (UIImage *)contactPlaceholderWithIntitials:(NSString *)initials;

@end
