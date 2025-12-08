import Flutter
import UIKit
import Foundation
import TwilioConversationsClient

public class TwilioConversationSdkPlugin: NSObject, FlutterPlugin,FlutterStreamHandler  {
    var conversationsHandler = ConversationsHandler()
    var eventSink: FlutterEventSink?
    var localConversation: TCHConversation?
    var tokenEventSink: FlutterEventSink?
    private var conversationsHandlers: ConversationsHandler?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        self.conversationsHandler.tokenEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        self.tokenEventSink = nil
        return nil
    }
    //  public static func register(with registrar: FlutterPluginRegistrar) {
    //    let channel = FlutterMethodChannel(name: "twilio_conversation_sdk", binaryMessenger: registrar.messenger())
    //    let instance = TwilioConversationSdkPlugin()
    //    registrar.addMethodCallDelegate(instance, channel: channel)
    //  }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "twilio_conversation_sdk", binaryMessenger: registrar.messenger())
        let synchronizationStatusEventChannel = FlutterEventChannel(name: "twilio_conversation_sdk/synchronizationStatusEventChannel", binaryMessenger: registrar.messenger())
        let onClientSynchronizationChangedEventChannel = FlutterEventChannel(name: "twilio_conversation_sdk/onClientSynchronizationChanged", binaryMessenger: registrar.messenger())
        let messageEventChannel = FlutterEventChannel(name: "twilio_conversation_sdk/onMessageUpdated", binaryMessenger: registrar.messenger())
        let tokenEventChannel = FlutterEventChannel(name: "twilio_conversation_sdk/onTokenStatusChange", binaryMessenger: registrar.messenger())
        
        let instance = TwilioConversationSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        messageEventChannel.setStreamHandler(instance)
        synchronizationStatusEventChannel.setStreamHandler(instance)
        tokenEventChannel.setStreamHandler(instance)
        onClientSynchronizationChangedEventChannel.setStreamHandler(instance)
    }
    
    //  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    //    switch call.method {
    //    case "getPlatformVersion":
    //      result("iOS " + UIDevice.current.systemVersion)
    //    default:
    //      result(FlutterMethodNotImplemented)
    //    }
    //  }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String:Any]
        print("call->\(String(describing: call.method))")
        print("arguments->\(String(describing: arguments))")
        
        switch call.method {
        case Methods.generateToken:
            //          TwilioApi.requestTwilioAccessToken(identity:arguments?["identity"] as! String) { apiResult in
            //              switch apiResult {
            //              case .success(let accessToken):
            //                  result(accessToken)
            //              case .failure(let error):
            //                  print("Error requesting Twilio Access Token: \(error)")
            //                  result("")
            //              }
            //          }
            break
        case Methods.registerFCMToken:
            conversationsHandler.registerFCMToken(token: arguments?["fcmToken"] as! String) { success in
                result("Token Registerd")
            }
            break
        case Methods.unregisterFCMToken:
            conversationsHandler.unregisterFCMToken(token: arguments?["fcmToken"] as! String) { success in
                result("Token unregisterFCMToken")
            }
            break
        case Methods.updateAccessToken:
            self.conversationsHandler.updateAccessToken(accessToken: arguments?["accessToken"] as! String) { tchResult in
                print("Methods.updateAccessToken->\(String(describing: tchResult))")
                var tokenStatus: [String: Any] = [:]
                if let tokenUpdateResult = tchResult {
                    if (tokenUpdateResult.resultCode == 200){
                        tokenStatus["statusCode"] = tokenUpdateResult.resultCode
                        tokenStatus["message"] = Strings.accessTokenRefreshed
                    }else {
                        tokenStatus["statusCode"] = tokenUpdateResult.resultCode
                        tokenStatus["message"] = tokenUpdateResult.resultText
                    }
                }
                result(tokenStatus)
            }
            break
        case Methods.initializeConversationClient:
            self.conversationsHandler.clientDelegate = self
            self.conversationsHandler.loginWithAccessToken(arguments?["accessToken"] as! String) { loginResult in
                guard let loginResultSuccessful: Bool = loginResult?.isSuccessful else {return}
                if(loginResultSuccessful) {
                    result(Strings.authenticationSuccessful)
                }else {
                    result(Strings.authenticationFailed)
                }
            }
            break
        case Methods.createConversation:
            self.conversationsHandler.createConversation (uniqueConversationName: arguments?["conversationName"] as! String){ (success, conversation,status)  in
                if success, let conversation = conversation {
                    self.conversationsHandler.joinConversation(conversation) { joinConversationStatus in}
                    result(Strings.createConversationSuccess)
                }else {
                    if (status == Strings.conversationExists) {
                        result(Strings.conversationExists)
                    } else {
                        result(Strings.createConversationFailure)
                    }
                }
            }
            break
        case Methods.getConversations:
            self.conversationsHandler.getConversations { conversationList in
                var listOfConversations: [[String: Any]] = []
                for conversation in conversationList {
                    var dictionary: [String: Any] = [:]
                    dictionary["conversationName"] = conversation.friendlyName
                    dictionary["sid"] = conversation.sid
                    dictionary["createdBy"] = conversation.createdBy
                    dictionary["dateCreated"] = conversation.dateCreated
                    dictionary["lastReadIndex"] = conversation.lastReadMessageIndex
                    dictionary["lastMessageIndex"] = conversation.lastMessageIndex
                    if (conversation.lastMessageDate != nil){
                        dictionary["lastMessageDate"] = conversation.lastMessageDate?.description
                    }
                    dictionary["uniqueName"] = conversation.uniqueName
                    dictionary["participantsCount"] = conversation.participants().count
                    dictionary["isGroup"] = conversation.participants().count > 2
                    if (ConvertorUtility.isNilOrEmpty(dictionary["conversationName"]) == false && ConvertorUtility.isNilOrEmpty(dictionary["sid"]) == false){
                        listOfConversations.append(dictionary)
                    }
                    print(dictionary)
                }
                result(listOfConversations)
            }
            break
        case Methods.getParticipants:
            var listOfParticipants: [[String:Any]] = []
            self.conversationsHandler.getParticipants(conversationId: arguments?["conversationId"] as! String) { participantsList in
                for user in participantsList {
                    var participant: [String: Any] = [:]
                    if (!ConvertorUtility.isNilOrEmpty(user.identity)) {
                        participant["identity"] = user.identity
                        participant["sid"] = user.sid
                        participant["conversationSid"] = user.conversation?.sid
                        participant["dateCreated"] = user.dateCreated
                        participant["conversationCreatedBy"] = user.conversation?.createdBy
                        participant["isAdmin"] = (user.conversation?.createdBy == user.identity)
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: user.attributes()!.dictionary ?? Dictionary(), options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print(jsonString)
                                participant["attributes"] = jsonString
                                
                            }
                        } catch {
                            print("Error converting dictionary to string: \(error.localizedDescription)")
                            participant["attributes"] = ""
                            
                        }
                        listOfParticipants.append(participant)
                    }
                }
                result(listOfParticipants)
            }
            break
        case Methods.getParticipantsWithName:
            var listOfParticipants: [[String: Any]] = []
            
            // Fetch participants for the provided conversation ID
            self.conversationsHandler.getParticipants(conversationId: arguments?["conversationId"] as! String) { participantsList in
                // Create a DispatchGroup to track asynchronous tasks
                let dispatchGroup = DispatchGroup()
                
                // Loop through each participant in the fetched list
                for user in participantsList {
                    var participant: [String: Any] = [:]
                    
                    // Ensure identity is not nil or empty
                    if !ConvertorUtility.isNilOrEmpty(user.identity) {
                        participant["identity"] = user.identity
                        participant["sid"] = user.sid
                        participant["conversationSid"] = user.conversation?.sid
                        participant["dateCreated"] = user.dateCreated
                        participant["conversationCreatedBy"] = user.conversation?.createdBy
                        participant["isAdmin"] = (user.conversation?.createdBy == user.identity)
                        // Handle attributes serialization
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: user.attributes()?.dictionary ?? [:], options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print(jsonString)
                                participant["attributes"] = jsonString
                            }
                        } catch {
                            // Handle error in serialization
                            print("Error converting dictionary to string: \(error.localizedDescription)")
                            participant["attributes"] = ""  // Provide empty string if serialization fails
                        }
                        // Enter the DispatchGroup before making the async call
                        dispatchGroup.enter()
                        
                        // Call the subscribedUser method asynchronously
                        user.subscribedUser { result, users in
                            // Update participant data with the user details
                            participant["friendlyIdentity"] = users?.identity
                            participant["friendlyName"] = users?.friendlyName
                            // Add the participant to the list once the subscribedUser completes
                            listOfParticipants.append(participant)
                            
                            // Leave the DispatchGroup after finishing the async task
                            dispatchGroup.leave()
                        }
                    }
                }
                
                // Once all async tasks are finished, notify and return the result
                dispatchGroup.notify(queue: .main) {
                    result(listOfParticipants)  // Return the list of participants once everything is done
                }
            }
            break
            
            
            
            
        case Methods.addParticipant:
            self.conversationsHandler.addParticipants(conversationId: arguments?["conversationId"] as! String, participantName: arguments?["participantName"] as! String) { status in
                if let addParticipantStatus = status {
                    if (addParticipantStatus.isSuccessful){
                        result(Strings.addParticipantSuccess)
                    }else {
                        result(addParticipantStatus.resultText)
                    }
                }
            }
            break
        case Methods.removeParticipant:
            self.conversationsHandler.removeParticipants(conversationId: arguments?["conversationId"] as! String, participantName: arguments?["participantName"] as! String) { status in
                if let removeParticipantStatus = status {
                    if (removeParticipantStatus.isSuccessful){
                        result(Strings.removedParticipantSuccess)
                    }else {
                        result(removeParticipantStatus.resultText)
                    }
                }
            }
            break
        case Methods.joinConversation:
            self.conversationsHandler.getConversationFromId(conversationId: arguments?["conversationId"] as! String) { conversation in
                if let conversationFromId = conversation {
                    self.conversationsHandler.joinConversation(conversationFromId) { tchConversationStatus in
                        result(tchConversationStatus)
                    }
                }
            }
        case Methods.getMessages:
            self.conversationsHandler.getConversationFromId(conversationId: arguments?["conversationId"] as! String) { conversation in
                self.conversationsHandler.conversationId = arguments?["conversationId"] as? String
                if let conversationFromId = conversation {
                    self.conversationsHandler.loadPreviousMessages(conversationFromId,arguments?["messageCount"] as? UInt) { listOfMessages in
                        //                      print("listOfMessagess->\(String(describing: listOfMessages))")
                        result(listOfMessages)
                    }
                }
            }
            break
        case Methods.getLastMessages:
            self.conversationsHandler.getConversationFromId(conversationId: arguments?["conversationId"] as! String) { conversation in
                if let conversationFromId = conversation {
                    self.conversationsHandler.getLastMessage(conversationFromId,arguments?["messageCount"] as? UInt) { listOfMessages in
                        //                      print("listOfMessagess->\(String(describing: listOfMessages))")
                        result(listOfMessages)
                    }
                }
            }
            break
            
        case Methods.getUnReadMsgCount:
            self.conversationsHandler.getUnReadMsgCount(conversationId: arguments?["conversationId"] as! String){ list in
                result(list)
            }
            break
            
        case Methods.sendMessage:
            self.conversationsHandler.sendMessage(conversationId: arguments?["conversationId"] as! String, messageText: arguments?["message"] as! String, attributes: arguments?["attribute"] as! [String : Any]) { tchResult, tchMessages in
                if (tchResult.isSuccessful){
                    result("send")
                }else {
                    result(tchResult.resultText)
                }
            }
            break
        case Methods.sendMessageWithMedia:
            self.conversationsHandler.sendMessageWithMedia(conversationId: arguments?["conversationId"] as! String, messageText: arguments?["message"] as! String, attributes: arguments?["attribute"] as! [String : Any], mediaFilePath: arguments?["mediaFilePath"] as! String, mimeType: arguments?["mimeType"] as! String, fileName: arguments?["fileName"] as! String ){ tchResult, tchMessages in
                if (tchResult.isSuccessful){
                    print("sendMessageWithMedia send success")
                    result("send")
                }else {
                    result(tchResult.resultText)
                }
            }
            
            //            self.conversationsHandler.sendMessage(conversationId: arguments?["conversationId"] as! String, messageText: arguments?["message"] as! String,
            //                attributes: arguments?["attribute"] as! [String : Any]) { tchResult, tchMessages in
            //                if (tchResult.isSuccessful){
            //                    result("send")
            //                }else {
            //                    result(tchResult.resultText)
            //                }
            
            break
        case Methods.subscribeToMessageUpdate:
            if let conversationId = arguments?["conversationId"] as? String {
                conversationsHandler.messageDelegate = self
                conversationsHandler.messageSubscriptionId = conversationId
                //MARK: TODO
                self.conversationsHandler.getConversationFromId(conversationId: arguments?["conversationId"] as! String) { conversation in
                    self.conversationsHandler.messageDelegate?.onSynchronizationChanged(status: ["status" : conversation?.synchronizationStatus.rawValue])
                    
                    //MARK: setLastReadMessageIndex
                    conversation?.setLastReadMessageIndex(conversation?.lastMessageIndex ?? 0, completion: { result, index in
                        print("setLastReadMessageIndex\(result.description)")
                        self.conversationsHandler.lastReadIndex = nil
                    })
                }
                self.conversationsHandler.isSubscribe = true
            }
            
            break
        case Methods.unSubscribeToMessageUpdate:
            self.conversationsHandler.getConversationFromId(conversationId: arguments?["conversationId"] as! String) { conversation in
            }
            self.conversationsHandler.conversationId = nil
            conversationsHandler.isSubscribe = nil
            conversationsHandler.messageDelegate = nil
            break
        case Methods.deleteConversation:
            self.conversationsHandler.deleteConversation(conversationId: arguments?["conversationId"] as! String) { resultString in
                result(resultString)
            }
            break
        case Methods.deleteMessageWithSid:
            self.conversationsHandler.deleteMessageWithSid(conversationId: arguments?["conversationId"] as! String,messageSid: arguments?["messageSid"] as! String,messageCount: arguments?["messageCount"] as! Int) { resultString in
                result(resultString)
            }
            break
        default:
            break
        }
    }
    
    
}

extension TwilioConversationSdkPlugin : MessageDelegate {
    func onSynchronizationChanged(status: [String : Any]) {
        self.eventSink?(status)
    }
    
    func onMessageUpdate(message: [String : Any], messageSubscriptionId: String) {
        if let conversationId = message["conversationId"] as? String,let message = message["message"] as? [String:Any] {
            if (messageSubscriptionId == conversationId) {
                self.eventSink?(message)
            }
        }
    }
}

extension TwilioConversationSdkPlugin : ClientDelegate {
    func onClientSynchronizationChanged(status: [String : Any]) {
        print("--------Status-------------> " + "\(status)")
        self.eventSink?(status)
    }
}



