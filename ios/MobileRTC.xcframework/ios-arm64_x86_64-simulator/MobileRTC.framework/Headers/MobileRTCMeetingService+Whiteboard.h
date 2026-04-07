//
//  MobileRTCMeetingService+Whiteboard.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2023/11/23.
//  Copyright © 2023 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>

@interface MobileRTCMeetingService (Whiteboard)

/*!
 @brief Determine whether the current meeting supports the whiteboard or not.
 @return YES indicates to support.
 */
- (BOOL)isSupportWhiteBoard;

/*!
 @brief Set parent viewctroller for whiteboard board view and whiteboard canvas.
 @param parentVC which use to present ViewController
 @warning The function only for Custom UI. This method is a prerequisite for using whiteboard. Suggest to call this function in "onMeetingStateChange:" for inMeeting status.
 @return If the function succeeds, the return value is MobileRTCSDKError_Success.
 */
- (MobileRTCSDKError)setParentViewCtroller:(UIViewController* _Nonnull)parentVC;

/*!
 @brief Show the dashboard web view window.
 @warning The function only for Custom UI.
 @return If the function succeeds, the return value is MobileRTCSDKError_Success.
 */
- (MobileRTCSDKError)showDashboardView;

/*!
 @brief Set the option for who can share a whiteboard.
 @param option New setting for who can share a whiteboard, see [MobileRTCWhiteboardShareOption].
 @return If the function succeeds, the return value is MobileRTCSDKError_Success.
 */
- (MobileRTCSDKError)setWhiteboardShareOption:(MobileRTCWhiteboardShareOption)option;

/*!
 @brief Get the option for who can share a whiteboard.
 @return Setting option for who can share a whiteboard, see [MobileRTCWhiteboardShareOption].
 */
- (MobileRTCWhiteboardShareOption)getWhiteboardShareOption;

/*!
 @brief Set the option for who can initiate a new whiteboard.
 @param option  Setting option for who can initiate a new whiteboard, see [MobileRTCWhiteboardCreateOption].
 @return If the function succeeds, the return value is MobileRTCSDKError_Success.
 */
- (MobileRTCSDKError)setWhiteboardCreateOption:(MobileRTCWhiteboardCreateOption)option;

/*!
 @brief Get the option for who can initiate a new whiteboard.
 @return Setting option for who can initiate a new whiteboard,  see [MobileRTCWhiteboardCreateOption].
 */
- (MobileRTCWhiteboardCreateOption)getWhiteboardCreateOption;

/*!
 @brief Enable the participants to create a new whiteboard without the host in the meeting.
 @param enable YES indicates to enable. NO not.
 @return If the function succeeds, the return value is MobileRTCSDKError_Success.
 */
- (MobileRTCSDKError)enableParticipantsCreateWithoutHost:(BOOL)enable;

/*!
 @brief Determine whether enable the participants create a new whiteboard without the host in the meeting.
 @return YES indicates that they have these permission.
 */
- (BOOL)isParticipantsCreateWithoutHostEnabled;

@end

