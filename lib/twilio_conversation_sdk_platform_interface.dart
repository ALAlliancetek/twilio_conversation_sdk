import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:twilio_conversation_sdk/twilio_conversation_sdk_method_channel.dart';

abstract class TwilioConversationSdkPlatform extends PlatformInterface {
  /// Constructs a TwilioChatConversationPlatform.
  TwilioConversationSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static TwilioConversationSdkPlatform _instance =
      MethodChannelTwilioConversationSdk();

  /// The default instance of [TwilioChatConversationPlatform] to use.
  ///
  /// Defaults to [MethodChannelTwilioChatConversation].
  static TwilioConversationSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TwilioChatConversationPlatform] when
  /// they register themselves.
  static set instance(TwilioConversationSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> generateToken({
    required String accountSid,
    required String apiKey,
    required String apiSecret,
    required String identity,
    required String serviceSid,
    required String pushSid,
  }) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> createConversation(
      {required String conversationName, required String identity}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> registerFCMToken({required String fcmToken}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> unregisterFCMToken({required String fcmToken}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getConversations() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getLastMessages({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getUnReadMsgCount({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getMessages(
      {required String conversationId, int? messageCount}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> joinConversation({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> sendMessage(
      {required String conversationId,
      required String message,
      required dynamic attribute}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> sendMessageWithMedia(
      {required String message,
      required String conversationId,
      required dynamic attribute,
      required String mediaFilePath,
      required String mimeType,
      required String fileName}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> addParticipant(
      {required String conversationId, required String participantName}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> receiveMessages({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getParticipants({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getParticipantsWithName({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> subscribeToMessageUpdate({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> unSubscribeToMessageUpdate({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> initializeConversationClient({required String accessToken}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Map?> updateAccessToken({required String accessToken}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> removeParticipant(
      {required conversationId, required participantName}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> deleteConversation({required String conversationId}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> deleteMessage(
      {required String conversationId, required int index}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> deleteMessageWithSid(
      {required String conversationId, required String messageSid}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
