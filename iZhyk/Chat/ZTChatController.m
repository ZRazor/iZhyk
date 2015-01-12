//
//  ZTChatController.m
//  iZhyk
//
//  Created by ZRazor on 25.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import "ZTChatController.h"
#import "ZTZhyk.h"
#import "SVWebViewController.h"

@implementation ZTChatController {
    NSMutableArray* messages;
    JSQMessagesBubbleImage *outgoingBubbleImageData;
    JSQMessagesBubbleImage *incomingBubbleImageData;
    NSTimer *updateTimer;
    BOOL isUpdating;
    ZTZhyk *zhyk;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    messages = [NSMutableArray array];
    zhyk = [ZTZhyk sharedInstance];
    isUpdating = NO;
    self.senderId = zhyk.userId;
    self.senderDisplayName = zhyk.login;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    self.inputToolbar.contentView.textView.placeHolder = @"Введите сообщение";
    [self.inputToolbar.contentView.rightBarButtonItem setTitle:@"Отпр" forState:UIControlStateNormal];
    [self.inputToolbar.contentView.rightBarButtonItem setTitle:@"Отпр" forState:UIControlStateDisabled];
    [self.inputToolbar.contentView.rightBarButtonItem setTitleColor:[[ZTZhyk sharedInstance] loadMainColor] forState:UIControlStateNormal];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[[ZTZhyk sharedInstance] loadMainColor]];
    
    [self updateChat];
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"updateTimerInterval"] target:self selector:@selector(updateChat) userInfo:nil repeats:YES];
}

- (void)showAlert:(NSString *)msg
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"Закрыть"
                                              otherButtonTitles:nil];
    [alertView show];
}

-(void)updateChat
{
    if (isUpdating) {
        return;
    }
    float newInterval = [[NSUserDefaults standardUserDefaults] floatForKey:@"updateTimerInterval"];
    if (updateTimer && updateTimer.timeInterval != newInterval) {
        [updateTimer invalidate];
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:newInterval target:self selector:@selector(updateChat) userInfo:nil repeats:YES];
    }
    isUpdating = YES;
    [zhyk getChatContent:^(NSArray *newMessages, BOOL isError, NSString *errorMsg) {
        if (isError) {
            [updateTimer invalidate];
            updateTimer = nil;
            [self.toolbarItems[0] setHidden:YES];
            if (zhyk.authStatus != asLoggedOut) {
                [self showAlert:errorMsg];
            }
        } else {
            isUpdating = NO;
            if (newMessages) {
                messages = [NSMutableArray array];
                for (NSDictionary* msg in newMessages) {
                    JSQMessage *jmsg = [JSQMessage messageWithSenderId:msg[@"authorId"] displayName:[ NSString stringWithFormat:@"%@ - %@", msg[@"time"], msg[@"author"]] text:msg[@"text"]];
                    [messages addObject:jmsg];
                }
                
                JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"parrot2.gif"]];
                JSQMessage *photoMessage = [JSQMessage messageWithSenderId:zhyk.userId
                                                               displayName:@"MediaMan"
                                                                     media:photoItem];
                [messages addObject:photoMessage];
                
//                [self.collectionView reloadData];
                [self finishReceivingMessage];
            }
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    
    
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
}


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [messages objectAtIndex:indexPath.item];
    
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return outgoingBubbleImageData;
    }
    
    return incomingBubbleImageData;
}

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    button.enabled = NO;
    self.inputToolbar.contentView.textView.text = @"";
    [zhyk sendMsg:text block:^(BOOL isError, NSString *errorMsg) {
        button.enabled = YES;
        if (isError) {
            [self showAlert:errorMsg];
        }
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [messages count];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
//    if (indexPath.item % 3 == 0) {
//        JSQMessage *message = [messages objectAtIndex:indexPath.item];
//        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
//    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
//    if (indexPath.item % 3 == 0) {
//        return kJSQMessagesCollectionViewCellLabelHeightDefault;
//    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:[URL absoluteString]];
    [self.navigationController pushViewController:webViewController animated:YES];
    
    return NO;
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    cell.textView.delegate = self;
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    } else {
        [cell.mediaView sizeToFit];
    }
    
    return cell;
}

@end
