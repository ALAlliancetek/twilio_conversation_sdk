import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'twilio_conversation_sdk_platform_interface.dart';

/// An implementation of [TwilioConversationSdkPlatform] that uses method channels.
class MethodChannelTwilioConversationSdk extends TwilioConversationSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('twilio_conversation_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /// Generate token and authenticate user (only for Android) #
  @TargetPlatform.android
  @override
  Future<String?> generateToken(
      {required String accountSid,
      required String apiKey,
      required String apiSecret,
      required String identity,
      required String serviceSid,
      required String pushSid}) async {
    final accessToken =
        await methodChannel.invokeMethod<String>('generateToken', {
      "accountSid": accountSid,
      "apiKey": apiKey,
      "apiSecret": apiSecret,
      "identity": identity,
      "serviceSid": serviceSid,
      "pushSid": pushSid
    });
    return accessToken;
  }

  /// Register FCM Token #
  @override
  Future<String?> registerFCMToken({required String fcmToken}) async {
    final result = await methodChannel
        .invokeMethod<String>('registerFCMToken', {"fcmToken": fcmToken});
    return result;
  }

  /// UnRegister FCM Token #
  @override
  Future<String?> unregisterFCMToken({required String fcmToken}) async {
    final result = await methodChannel
        .invokeMethod<String>('unregisterFCMToken', {"fcmToken": fcmToken});
    return result;
  }

  /// Create new conversation #
  @override
  Future<String?> createConversation(
      {required String conversationName, required String identity}) async {
    final result = await methodChannel.invokeMethod<String>(
        'createConversation',
        {"conversationName": conversationName, "identity": identity});
    return result;
  }

  /// Get list of conversations for logged in user #
  @override
  Future<List?> getConversations() async {
    final List? conversationsList =
        await methodChannel.invokeMethod('getConversations');
    return conversationsList ?? [];
  }

  /// Get list of conversations for logged in user last message#
  @override
  Future<List?> getLastMessages({required String conversationId}) async {
    final List? lastMessageList = await methodChannel
        .invokeMethod('getLastMessages', {"conversationId": conversationId});
    return lastMessageList ?? [];
  }

  /// Get list of conversations for logged in user last message unread count#
  @override
  Future<List?> getUnReadMsgCount({required String conversationId}) async {
    final List? lastMessageList = await methodChannel
        .invokeMethod('getUnReadMsgCount', {"conversationId": conversationId});
    return lastMessageList ?? [];
  }

  /// Get messages from the specific conversation #
  @override
  Future<List?> getMessages(
      {required String conversationId, int? messageCount}) async {
    final List? messages = await methodChannel.invokeMethod('getMessages',
        {"conversationId": conversationId, "messageCount": messageCount});
    //print("messages->$messages");
    return messages ?? [];
  }

  /// Join the existing conversation #
  @override
  Future<String?> joinConversation({required String conversationId}) async {
    final String? result = await methodChannel.invokeMethod<String>(
        'joinConversation', {"conversationId": conversationId});
    return result ?? "";
  }

  /// Send message #
  @override
  Future<String?> sendMessage(
      {required String conversationId,
      required String message,
      dynamic attribute}) async {
    final String? result = await methodChannel.invokeMethod<String>(
        'sendMessage', {
      "conversationId": conversationId,
      "message": message,
      "attribute": attribute
    });
    return result ?? "";
  }

  /// Send message with media #
  @override
  Future<String?> sendMessageWithMedia(
      {required String message,
      required String conversationId,
      dynamic attribute,
      required String mediaFilePath,
      required String mimeType,
      required String fileName}) async {
    final String? result =
        await methodChannel.invokeMethod<String>('sendMessageWithMedia', {
      "message": message,
      "conversationId": conversationId,
      "attribute": attribute,
      "mediaFilePath": mediaFilePath,
      "mimeType": mimeType,
      "fileName": fileName,
    });
    return result ?? "Something Wrong in SendMediaMessage";
  }

  /// Add participant in a conversation #
  @override
  Future<String?> addParticipant(
      {required String conversationId, required String participantName}) async {
    final String? result = await methodChannel.invokeMethod<String>(
        'addParticipant',
        {"conversationId": conversationId, "participantName": participantName});
    return result ?? "";
  }

  /// Get messages from the specific conversation #
  @override
  Future<String?> receiveMessages({required String conversationId}) async {
    final String? result =
        await methodChannel.invokeMethod<String>('receiveMessages', {
      "conversationId": conversationId,
    });
    return result ?? "";
  }

  /// Get participants from the specific conversation #
  @override
  Future<List?> getParticipants({required String conversationId}) async {
    final List? participantsList = await methodChannel
        .invokeMethod('getParticipants', {"conversationId": conversationId});
    return participantsList ?? [];
  }

  /// Get participants with name from the specific conversation #
  @override
  Future<List?> getParticipantsWithName(
      {required String conversationId}) async {
    final List? participantsList = await methodChannel.invokeMethod(
        'getParticipantsWithName', {"conversationId": conversationId});
    return participantsList ?? [];
  }

  @override
  Future<String> subscribeToMessageUpdate(
      {required String conversationId}) async {
    // TODO: implement onMessageUpdated
    //
    final String? result = await methodChannel.invokeMethod(
        'subscribeToMessageUpdate', {"conversationId": conversationId});
    return result ?? "";
  }

  @override
  Future<String> unSubscribeToMessageUpdate(
      {required String conversationId}) async {
    // TODO: implement onMessageUpdated
    //
    final String? result = await methodChannel.invokeMethod(
        'unSubscribeToMessageUpdate', {"conversationId": conversationId});
    return result ?? "";
  }

  @override
  Future<String?> initializeConversationClient(
      {required String accessToken}) async {
    // TODO: implement initializeConversationClient
    final String? result = await methodChannel.invokeMethod(
        'initializeConversationClient', {"accessToken": accessToken});
    return result ?? "";
  }

  @override
  Future<Map?> updateAccessToken({required String accessToken}) async {
    // TODO: implement updateAccessToken
    final Map? result = await methodChannel
        .invokeMethod('updateAccessToken', {"accessToken": accessToken});
    return result ?? {};
  }

  @override
  Future<String?> removeParticipant(
      {required conversationId, required participantName}) async {
    final String? result = await methodChannel.invokeMethod<String>(
        'removeParticipant',
        {"conversationId": conversationId, "participantName": participantName});
    return result ?? "";
  }

  /// delete conversation #
  @override
  Future<String?> deleteConversation({required String conversationId}) async {
    final result = await methodChannel.invokeMethod<String>(
        'deleteConversation', {"conversationId": conversationId});
    return result;
  }

  /// delete message #
  @override
  Future<String?> deleteMessage(
      {required String conversationId, required int index}) async {
    final result = await methodChannel.invokeMethod<String>(
        'deleteMessage', {"conversationId": conversationId, "index": index});
    return result;
  }

  /// delete message with sid #
  @override
  Future<String?> deleteMessageWithSid(
      {required String conversationId, required String messageSid}) async {
    final result = await methodChannel.invokeMethod<String>('deleteMessageWithSid',
        {"conversationId": conversationId, "messageSid": messageSid});
    return result;
  }
}
