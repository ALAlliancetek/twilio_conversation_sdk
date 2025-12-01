package com.at.twilio_conversation_sdk;

import androidx.annotation.NonNull;


import com.at.twilio_conversation_sdk.app_interface.AccessTokenInterface;
import com.at.twilio_conversation_sdk.app_interface.ClientInterface;
import com.at.twilio_conversation_sdk.app_interface.MessageInterface;
import com.at.twilio_conversation_sdk.conversation.ConversationHandler;
import com.at.twilio_conversation_sdk.utility.Methods;

import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;


/**
 * TwilioChatConversationSdkPlugin
 */
public class TwilioConversationSdkPlugin implements FlutterPlugin, MethodCallHandler, StreamHandler, MessageInterface, AccessTokenInterface, ClientInterface {
    /// The MethodChannel that will the communication between Flutter and native Android
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private EventChannel eventChannel;
    private EventChannel eventSyncChannel;
    private EventChannel tokenEventChannel;
    private EventChannel clientEventChannel;
    private EventChannel.EventSink eventSink;
    private EventChannel.EventSink eventSyncSink;
    private EventChannel.EventSink tokenEventSink;
    private EventChannel.EventSink clientEventSink;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_conversation_sdk");
        channel.setMethodCallHandler(this);
        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_conversation_sdk/onMessageUpdated");
        eventChannel.setStreamHandler(this);
        eventSyncChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_conversation_sdk/onSynchronizationChanged");
        eventSyncChannel.setStreamHandler(this);
        tokenEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_conversation_sdk/onTokenStatusChange");
        tokenEventChannel.setStreamHandler(this);
        clientEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_conversation_sdk/onClientSynchronizationChanged");
        clientEventChannel.setStreamHandler(this);

        ConversationHandler.flutterPluginBinding = flutterPluginBinding;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        System.out.println("call.method->" + call.method);
        switch (call.method) {
            // To generate twilio access token #
            case Methods.generateToken: //Generate token and authenticate user
                String accessToken = ConversationHandler.generateAccessToken(call.argument("accountSid"), call.argument("apiKey"), call.argument("apiSecret"), call.argument("identity"), call.argument("serviceSid"), call.argument("pushSid"));
                System.out.println("accessToken generated->" + accessToken);
                result.success(accessToken);
//        ConversationHandler.initializeConversationClient(accessToken,result);
                break;

            case Methods.initializeConversationClient: //Generate token and authenticate user
                ConversationHandler.initializeConversationClient(call.argument("accessToken"), result, this);
                break;
            //Register FCM Token#
            case Methods.registerFCMToken:
                ConversationHandler.registerFCMToken(call.argument("fcmToken"), result);
                break;
            //UnRegister FCM Token#
            case Methods.unregisterFCMToken:
                ConversationHandler.unregisterFCMToken(call.argument("fcmToken"), result);
                break;
            // Create new conversation #
            case Methods.createConversation:
                ConversationHandler.createConversation(call.argument("conversationName"), call.argument("identity"), result);
                break;
            // Get list of conversations for logged in user #
            case Methods.getConversations:
                List<Map<String, Object>> conversationList = ConversationHandler.getConversationsList();
                result.success(conversationList);
                break;
            // Get list of conversations for logged in user last message#
            case Methods.getLastMessages:
                ///List<Map<String, Object>> getLastMessagesList =
                ConversationHandler.getLastMessages(call.argument("conversationId"), result);
                //result.success(getLastMessagesList);
                break;
            // Get list of conversations for logged in user last message#
            case Methods.getUnReadMsgCount:
                ///List<Map<String, Object>> getLastMessagesList =
                ConversationHandler.getUnReadMsgCount(call.argument("conversationId"), result);
                //result.success(getLastMessagesList);
                break;
            // Get messages from the specific conversation #
            case Methods.getMessages:
                ConversationHandler.getAllMessages(call.argument("conversationId"), call.argument("messageCount"), result);
                break;
            //Join the existing conversation #
            case Methods.joinConversation:
                String joinStatus = ConversationHandler.joinConversation(call.argument("conversationId"));
                result.success(joinStatus);
                break;
            // Send message #
            case Methods.sendMessage:
                ConversationHandler.sendMessages(call.argument("message"), call.argument("conversationId"), call.argument("attribute"), result);
                break;
            // Send message with media #
            case Methods.sendMessageWithMedia:
                ConversationHandler.sendMessageWithMedia(
                        call.argument("message"),
                        call.argument("conversationId"),
                        call.argument("attribute"),
                        call.argument("mediaFilePath"),
                        call.argument("mimeType"),
                        call.argument("fileName"),
                        result
                );
                break;
            // Add participant in a conversation #
            case Methods.addParticipant:
                ConversationHandler.addParticipant(call.argument("participantName"), call.argument("conversationId"), result);
                break;
            case Methods.removeParticipant:
                ConversationHandler.removeParticipant(call.argument("participantName"), call.argument("conversationId"), result);
                break;
            // Get & Listen messages from the specific conversation #
            case Methods.receiveMessages:
            case Methods.subscribeToMessageUpdate:
                ConversationHandler.subscribeToMessageUpdate(call.argument("conversationId"));
                break;
            // Get participants from the specific conversation #
            case Methods.getParticipants:
                ConversationHandler.getParticipants(call.argument("conversationId"), result);
                break;
            // Get participants with name from the specific conversation #
            case Methods.getParticipantsWithName:
                ConversationHandler.getParticipantsWithName(call.argument("conversationId"), result);
                break;
            case Methods.unSubscribeToMessageUpdate:
                ConversationHandler.unSubscribeToMessageUpdate(call.argument("conversationId"));
                break;
            case Methods.updateAccessToken:
                ConversationHandler.updateAccessToken(call.argument("accessToken"), result);
                break;
            case Methods.deleteConversation:
                ConversationHandler.deleteConversation(call.argument("conversationId"), result);
                break;
            case Methods.deleteMessage:
                ConversationHandler.deleteMessage(call.argument("conversationId"), call.argument("index"), result);
                break;
            case Methods.deleteMessageWithSid:
                ConversationHandler.deleteMessageWithSid(call.argument("conversationId"), call.argument("messageSid"), call.argument("messageCount"), result);
                break;
            default:
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        eventSyncChannel.setStreamHandler(null);
        tokenEventChannel.setStreamHandler(null);
        clientEventChannel.setStreamHandler(null);
    }

    @Override
    public void onListen(Object arguments, EventSink events) {
        System.out.println("onListen " + arguments);
        this.eventSink = events;
        this.tokenEventSink = events;
        this.eventSyncSink = events;
        this.clientEventSink = events;
        ConversationHandler conversationHandler = new ConversationHandler();
        conversationHandler.setListener(this);
        conversationHandler.setTokenListener(this);
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink = null;
        tokenEventSink = null;
        eventSyncSink = null;
        clientEventSink = null;
    }

    @Override
    public void onMessageUpdate(Map message) {
        /// Pass the message result back to the Flutter side
        if (this.eventSink != null) {
            this.eventSink.success(message);
        }
    }

    @Override
    public void onSynchronizationChanged(Map status) {
        if (this.eventSyncSink != null) {
            this.eventSyncSink.success(status);
        }
    }

    @Override
    public void onTokenStatusChange(Map message) {
        /// Pass the message result back to the Flutter side
        if (this.tokenEventSink != null) {
            this.tokenEventSink.success(message);
        }
    }

    @Override
    public void onClientSynchronizationChanged(Map status) {
        System.out.println("onClientSynchronizationChanged SDK Plugin");
        if (this.clientEventSink != null) {
            System.out.println("onClientSynchronizationChanged SDK Plugin Not null");
            this.clientEventSink.success(status);
        }
    }
}