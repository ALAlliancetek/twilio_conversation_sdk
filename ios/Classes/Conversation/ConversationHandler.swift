import UIKit
import TwilioConversationsClient
import Flutter
import Foundation

class ConversationsHandler: NSObject, TwilioConversationsClientDelegate {
    
    
    
    // MARK: Conversations variables
    private var client: TwilioConversationsClient?
    var lastReadIndex: NSNumber?
    weak var messageDelegate: MessageDelegate?
    weak var clientDelegate: ClientDelegate?
    var isSubscribe:Bool?
    var conversationId : String?
    public var messageSubscriptionId: String = ""
    var tokenEventSink: FlutterEventSink?
    
      func conversationsClient(_ client: TwilioConversationsClient, conversation: TCHConversation, messageDeleted message: TCHMessage) {
            print("messageDeleted - \(message)");
            var dictionary: [String: Any] = [:]
            dictionary["sid"] = message.sid
            dictionary["author"] = message.author
            dictionary["body"] = message.body
            dictionary["isDelete"] = true
            var updatedMessage: [String: Any] = [:]
            updatedMessage["conversationId"] = conversation.sid ?? ""
            updatedMessage["message"] = dictionary

            self.messageDelegate?.onMessageUpdate(message: updatedMessage, messageSubscriptionId: self.messageSubscriptionId)
        }
    
    //    MARK: raw
    func conversationsClient(_ client: TwilioConversationsClient, conversation: TCHConversation,
                             messageAdded message: TCHMessage) {
        
        var attachedMedia: [[String: Any]] = []
        guard client.synchronizationStatus == .completed else {
            return
        }
        
        self.getMessageInDictionary(message) { [self] messageDictionary in
            if let messageDict = messageDictionary {
                var updatedMessage: [String: Any] = [:]
                updatedMessage["conversationId"] = conversation.sid ?? ""
                updatedMessage["message"] = messageDict
                //MARK: Update Index
                let computedIndex: NSNumber = {
                    if let lastMessageIndex = conversation.lastMessageIndex {
                        // Extract the value of lastMessageIndex and add 1
                        return NSNumber(value: lastMessageIndex.intValue + 1)
                    } else {
                        return 1
                    }
                }()
                
                for media in message.getMedia(by: Set([MediaCategory.media])) {
                    var mediaMap: [String: Any] = [:]
                    
                    mediaMap["sid"] = media.sid
                    mediaMap["contentType"] = media.contentType
                    mediaMap["filename"] = media.filename
                    
                    media.getTemporaryContentUrl { result, tempUrl in
                        mediaMap["mediaUrl"] = tempUrl
                        print("TempURL >>> \(tempUrl)")
                    }
                    attachedMedia.append(mediaMap)
                    updatedMessage["attachMedia"] = attachedMedia
                }
                
                if (isSubscribe ?? false && conversationId == conversation.sid ){
                    conversation.setLastReadMessageIndex(computedIndex) { result, index in
                        print("setLastReadMessageIndex \(result.description)")
                    }
                }
                
                
                self.messageDelegate?.onMessageUpdate(message: updatedMessage, messageSubscriptionId: self.messageSubscriptionId)
                
                //                print("lastReadIndex \(conversation.lastMessageIndex)")
                
            }
        }
    }
    
    func registerFCMToken(token: String,completion: @escaping (_ success : Bool) -> Void){
        
        let data = token.hexToData
        //        print(data) // Output: 5 bytes
        
        
        self.client?.register(withNotificationToken: data ?? Data(), completion: { result in
            if result.isSuccessful {
                completion(true)
            }
            print("Twilio Notification Token Set: \(result) with token \(token)")
            print("Device push token registration was\(result.isSuccessful ? "" : " not") successful")
        })
    }
    
    func unregisterFCMToken(token: String,completion: @escaping (_ success : Bool) -> Void){
        
        let data = token.hexToData
        //        print(data) // Output: 5 bytes
        
        
        self.client?.deregister(withNotificationToken: data ?? Data(), completion: { result in
            if result.isSuccessful {
                completion(true)
            }
            print("Twilio Notification Token deregister: \(result) with token \(token)")
            print("Device push token deregister \(result.isSuccessful ? "" : " not") successful")
        })
    }
    
    
    func conversationsClient(_ client: TwilioConversationsClient, conversation: TCHConversation, synchronizationStatusUpdated status: TCHConversationSynchronizationStatus) {
        self.messageDelegate?.onSynchronizationChanged(status: ["status" : conversation.synchronizationStatus.rawValue])
        print("StatusConversations \(conversation.synchronizationStatus.rawValue) ")
        
    }
    
    func conversationsClientTokenWillExpire(_ client: TwilioConversationsClient) {
        print("Access token will expire.->\(String(describing: tokenEventSink))")
        var tokenStatusMap: [String: Any] = [:]
        tokenStatusMap["statusCode"] = 200
        tokenStatusMap["message"] = Strings.accessTokenWillExpire
        tokenEventSink?(tokenStatusMap)
    }
    
    
    func conversationsClient(_ client: TwilioConversationsClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        print("statusclient->\(status.hashValue)--\(client.synchronizationStatus)")
        
        guard status == .completed else {
            return
        }
        self.clientDelegate?.onClientSynchronizationChanged(status: ["status":client.synchronizationStatus.rawValue])
        print("StatusClient \(client.synchronizationStatus.rawValue) ")
        
        //            checkConversationCreation { (_, conversation) in
        //               if let conversation = conversation {
        //                   self.joinConversation(conversation)
        //               } else {
        //                   self.createConversation { (success, conversation) in
        //                       if success, let conversation = conversation {
        //                           self.joinConversation(conversation)
        //                       }
        //                   }
        //               }
        //            }
    }
    
    
    
    func conversationsClientTokenExpired(_ client: TwilioConversationsClient) {
        print("Access token expired.\(String(describing: tokenEventSink))")
        var tokenStatusMap: [String: Any] = [:]
        tokenStatusMap["statusCode"] = 401
        tokenStatusMap["message"] = Strings.accessTokenExpired
        tokenEventSink?(tokenStatusMap)
    }
    
    public func updateAccessToken(accessToken:String,completion: @escaping (TCHResult?) -> Void) {
        self.client?.updateToken(accessToken, completion: { tchResult in
            completion(tchResult)
        })
    }
    
    
    
    func sendMessage(conversationId: String,
                     messageText: String,
                     attributes: [String: Any],
                     completion: @escaping (TCHResult, TCHMessage?) -> Void) {
        // Fetch the conversation using the provided ID
        self.getConversationFromId(conversationId: conversationId) { conversation in
            //            if let error = error {
            //                print("Error fetching conversation: \(error.localizedDescription)")
            //                result(.failure(error))
            //                return
            //            }
            
            
            // Convert attributes dictionary into Attributes type
            
            let attributesObject : TCHJsonAttributes = TCHJsonAttributes(dictionary: attributes)
            
            // Prepare and send the message
            conversation?.prepareMessage()
                .setAttributes(attributesObject, error: nil)
                .setBody(messageText).buildAndSend(completion: { tchResult, tchMessages in
                    completion(tchResult,tchMessages)
                })
            
            
        }
    }
    
    func sendMessageWithMedia(conversationId: String,
                              messageText: String,
                              attributes: [String: Any],
                              mediaFilePath : String,
                              mimeType : String,
                              fileName :String ,
                              completion: @escaping (TCHResult, TCHMessage?) -> Void) {
        // Fetch the conversation using the provided ID
        self.getConversationFromId(conversationId: conversationId) { conversation in
            //            if let error = error {
            //                print("Error fetching conversation: \(error.localizedDescription)")
            //                result(.failure(error))
            //                return
            //            }
            
            
            // Convert attributes dictionary into Attributes type
            
            let attributesObject : TCHJsonAttributes = TCHJsonAttributes(dictionary: attributes)
            
            guard let fileInputStream = InputStream(fileAtPath: mediaFilePath) else {
                print("Error opening media file at path: \(mediaFilePath)")
                return
            }
            
            // Prepare and send the message
            conversation?.prepareMessage()
                .setAttributes(attributesObject, error: nil)
                .setBody(messageText)
                .addMedia(inputStream: fileInputStream, contentType: mimeType, filename: fileName, listener: MediaMessageListener(
                    onStarted: {
                        print("Media upload started.")
                    },
                    onProgress: { bytesSent in
                        print("Media upload progress: \(bytesSent) bytes sent.")
                    },
                    onCompleted: { mediaSid in
                        print("Media uploaded successfully with SID: \(mediaSid)")
                    },
                    onFailed: { error in
                        print("Media upload failed: \(error.localizedDescription )")
                    }
                ))
                .buildAndSend(completion: { tchResult, tchMessages in
                    completion(tchResult,tchMessages)
                })
            
            
        }
    }
    
    
    func loginWithAccessToken(_ token: String, completion: @escaping (TCHResult?) -> Void) {
        // Set up Twilio Conversations client
        TwilioConversationsClient.conversationsClient(withToken: token,
                                                      properties: nil,
                                                      delegate: self) { (result, client) in
            self.client = client
            self.clientDelegate?.onClientSynchronizationChanged(status: ["status" : client?.synchronizationStatus.rawValue ?? -1])
            print("\(client?.synchronizationStatus.rawValue ?? -1)")
            //            self.client?.delegate?.conversationsClient?(<#T##client: TwilioConversationsClient##TwilioConversationsClient#>, synchronizationStatusUpdated: TCHClientSynchronizationStatus)
            completion(result)
        }
    }
    
    func shutdown() {
        if let client = client {
            client.delegate = nil
            client.shutdown()
            self.client = nil
        }
    }
    
    func createConversation(uniqueConversationName:String,_ completion: @escaping (Bool, TCHConversation?,String) -> Void) {
        guard let client = client else {
            return
        }
        // Create the conversation if it hasn't been created yet
        let options: [String: Any] = [
            TCHConversationOptionUniqueName: uniqueConversationName,
            TCHConversationOptionFriendlyName: uniqueConversationName,
        ]
        client.createConversation(options: options) { (result, conversation) in
            if result.isSuccessful {
                completion(result.isSuccessful, conversation,result.resultText ?? "Conversation created.")
            } else {
                completion(false, conversation,result.error?.localizedDescription ?? "Conversation NOT created.")
            }
        }
    }
    
    func getConversations(_ completion: @escaping([TCHConversation]) -> Void) {
        guard let client = client else {
            return
        }
        guard client.synchronizationStatus == .completed else {
            return
        }
        
        completion(client.myConversations() ?? [])
    }
    
    func getParticipants(conversationId:String,_ completion: @escaping([TCHParticipant]) -> Void) {
        self.getConversationFromId(conversationId: conversationId) { conversation in
            completion(conversation?.participants() ?? [])
        }
    }
    
    func addParticipants(conversationId:String,participantName:String,_ completion: @escaping(TCHResult?) -> Void) {
        self.getConversationFromId(conversationId: conversationId) { conversation in
            conversation?.addParticipant(byIdentity: participantName, attributes: nil,completion: { status in
                completion(status)
            })
        }
    }
    
    func removeParticipants(conversationId:String,participantName:String,_ completion: @escaping(TCHResult?) -> Void) {
        self.getConversationFromId(conversationId: conversationId) { conversation in
            conversation?.removeParticipant(byIdentity: participantName,completion: { status in
                print("status->\(status)")
                completion(status)
            })
        }
    }
    
    
    func joinConversation(_ conversation: TCHConversation,_ completion: @escaping(String?) -> Void) {
        if conversation.status == .joined {
            //            self.loadPreviousMessages(conversation,1000) { listOfMessages in
            //
            //            }
        } else {
            conversation.join(completion: { result in
                if result.isSuccessful {
                    //                    self.loadPreviousMessages(conversation,1000) { listOfMessages in
                    //
                    //                    }
                }
            })
        }
        completion(conversation.sid)
    }
    
    func getConversationFromId(conversationId:String,_ completion: @escaping(TCHConversation?) -> Void){
        guard let client = client else {
            return
        }
        guard client.synchronizationStatus == .completed else {
            return
        }
        client.conversation(withSidOrUniqueName: conversationId) { (result, conversation) in
            if let conversationFromSid = conversation {
                print("message readed")
                completion(conversationFromSid)
            }
        }
    }
    
    func loadPreviousMessages(_ conversation: TCHConversation,_ messageCount: UInt?,_ completion: @escaping([[String: Any]]?) -> Void) {
        print("synchronizationStatus->\(client?.synchronizationStatus == .completed)")
        guard client?.synchronizationStatus == .completed else {
            return
        }
        var listOfMessagess: [[String: Any]] = []
        conversation.getLastMessages(withCount: messageCount ?? 1000) { (result, messages) in
            if let messagesList = messages {
                self.processMessagesSequentially(messagesList: messagesList) { result in
                    completion(result) // Return the final processed list
                }
            }
            
        }
    }
    
    func processMessagesSequentially(
        messagesList: [TCHMessage],
        listOfMessagess: [[String: Any]] = [],
        completion: @escaping ([[String: Any]]) -> Void
    ) {
        var listOfMessagess = listOfMessagess // Create a local copy to modify
        
        var index = 0 // Start index
        
        func processNextMessage() {
            if index < messagesList.count { // Ensure we're within bounds
                self.getMessageInDictionary(messagesList[index]) { messageDictionary in
                    if let messageDict = messageDictionary {
                        listOfMessagess.append(messageDict)
                    }
                    index += 1 // Increment the index
                    processNextMessage() // Process the next message
                }
            } else {
                // All messages have been processed
                completion(listOfMessagess) // Return the final list
            }
        }
        
        processNextMessage() // Start processing
    }
    
    
    func processMessagesSequentiallyForParticipants(_ conversation: TCHConversation,
                                                    messagesList: [TCHMessage],
                                                    listOfMessagess: [[String: Any]] = [],
                                                    completion: @escaping ([[String: Any]]) -> Void
    ) {
        var listOfMessagess = listOfMessagess // Create a local copy to modify
        
        var index = 0 // Start index
        
        func processNextMessage() {
            if index < messagesList.count { // Ensure we're within bounds
                self.getMessageInDictionaryWithMsg(conversation,messagesList[index]) { messageDictionary in
                    if let messageDict = messageDictionary {
                        listOfMessagess.append(messageDict)
                    }
                    index += 1 // Increment the index
                    processNextMessage() // Process the next message
                }
            } else {
                // All messages have been processed
                completion(listOfMessagess) // Return the final list
            }
        }
        
        processNextMessage() // Start processing
    }
    
    
    func getLastMessage(_ conversation: TCHConversation,_ messageCount: UInt?,_ completion: @escaping([[String: Any]]?) -> Void) {
        print("synchronizationStatus->\(client?.synchronizationStatus == .completed)")
        guard client?.synchronizationStatus == .completed else {
            return
        }
        var listOfMessagess: [[String: Any]] = []
        conversation.getLastMessages(withCount: messageCount ?? 1) { (result, messages) in
            if let messagesList = messages {
                self.processMessagesSequentiallyForParticipants(conversation,messagesList: messagesList) { result in
                    completion(result) // Return the final processed list
                }
            }
        }
    }
    
    
    func getUnReadMsgCount(conversationId: String, _ completion: @escaping ([[String: Any]]?) -> Void) {
        var list: [[String: Any]] = []
        
        self.getConversationFromId(conversationId: conversationId) { conversation in
            var dictionary: [String: Any] = [:]
            conversation?.getUnreadMessagesCount(completion: { result, count in
                if result.isSuccessful {
                    list.removeAll()
                    print("Total Unread Count \(count)")
                    dictionary["sid"] = conversationId
                    dictionary["unReadCount"] = count
                    list.append(dictionary)
                    completion(list)
                }
                else{
                    print("No Unread Count")
                    dictionary["sid"] = conversationId
                    dictionary["unReadCount"] = 0
                    completion(list)
                }
            })
        }
    }
    
    
    
    func getMessageInDictionary(_ message: TCHMessage, _ completion: @escaping ([String: Any]?) -> Void) {
        var dictionary: [String: Any] = [:]
        var attachedMedia: [[String: Any]] = []
        
        dictionary["sid"] = message.sid
        dictionary["author"] = message.author
        dictionary["body"] = message.body
        
        do {
            let attributes = message.attributes()?.dictionary ?? [:]
            let jsonData = try JSONSerialization.data(withJSONObject: attributes, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                dictionary["attributes"] = jsonString
            }
        } catch {
            print("Error converting dictionary to string: \(error.localizedDescription)")
            dictionary["attributes"] = ""
        }
        
        
        dictionary["lastMessageDate"] = formatLastMessageDateISO8601(lastMessageDateString: message.dateUpdated?.description ?? "")
        dictionary["dateCreated"] = message.dateCreated?.description ?? ""
        dictionary["lastMessage"] = message.body
        
        // Fetch media details
        let mediaItems = message.getMedia(by: Set([MediaCategory.media]))
        if mediaItems.isEmpty {
            completion(dictionary) // No media, complete immediately
            return
        }
        
        let mediaDispatchGroup = DispatchGroup()
        
        for media in mediaItems {
            mediaDispatchGroup.enter()
            
            var mediaMap: [String: Any] = [:]
            mediaMap["sid"] = media.sid
            mediaMap["contentType"] = media.contentType
            mediaMap["filename"] = media.filename
            
            media.getTemporaryContentUrl { result, tempUrl in
                mediaMap["mediaUrl"] = tempUrl?.absoluteString ?? ""
                attachedMedia.append(mediaMap)
                mediaDispatchGroup.leave()
            }
        }
        
        mediaDispatchGroup.notify(queue: .main) {
            dictionary["attachMedia"] = attachedMedia
            completion(dictionary) // Complete after all media details are processed
        }
    }
    func deleteConversation(conversationId: String,
                            completion: @escaping (String) -> Void){
        self.getConversationFromId(conversationId: conversationId) { conversation in
            conversation?.destroy { result in
                if result.isSuccessful { print("Conversation deleted successfully")
                    completion(Strings.success)
                }
                else{ print("Failed to delete conversation")
                    completion(Strings.failed)
                }
                
                
            }
        }
    }
    func deleteMessageWithSid(
        conversationId: String,
        messageSid: String,
        messageCount: Int,
        completion: @escaping (String) -> Void
    ) {
        getConversationFromId(conversationId: conversationId) { conversation in
            
            guard let conversation = conversation else {
                completion("conv_failed: Conversation not found")
                return
            }
            
            conversation.getLastMessages(withCount: UInt(messageCount)) { result, messages in
                if result.isSuccessful, let messages = messages {
                    
                    // Find message by SID
                    if let message = messages.first(where: { $0.sid == messageSid }) {
                        
                        // Delete message
                        conversation.remove(message) { deleteResult in
                            if deleteResult.isSuccessful {
                                completion("success")
                            } else {
                                completion("delete_failed: \(deleteResult.error?.description ?? "unknown_error")")
                            }
                        }
                        
                    } else {
                        completion("msg_not_found: message SID not in last \(messageCount) messages")
                    }
                    
                } else {
                    completion("msg_fetch_failed: \(result.error?.description ?? "unknown_error")")
                }
            }
        }
    }
    
    func getMessageInDictionaryWithMsg(_ conversation: TCHConversation,_ message: TCHMessage, _ completion: @escaping ([String: Any]?) -> Void) {
        var dictionary: [String: Any] = [:]
        var attachedParticipantsData: [[String: Any]] = []
        
        dictionary["sid"] = message.sid
        dictionary["author"] = message.author
        dictionary["body"] = message.body
        
        do {
            let attributes = message.attributes()?.dictionary ?? [:]
            let jsonData = try JSONSerialization.data(withJSONObject: attributes, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                dictionary["attributes"] = jsonString
            }
        } catch {
            print("Error converting dictionary to string: \(error.localizedDescription)")
            dictionary["attributes"] = ""
        }
        
        let participantsDispatchGroup = DispatchGroup()
        
        dictionary["lastMessageDate"] = formatLastMessageDateISO8601(lastMessageDateString: message.dateUpdated?.description ?? "")
        dictionary["dateCreated"] = message.dateCreated?.description ?? ""
        dictionary["lastMessage"] = message.body
        dictionary["mediaCount"] = message.attachedMedia.count
        dictionary["participantsCount"] = conversation.participants().count
        dictionary["isGroup"] = conversation.participants().count > 2
        dictionary["lastReadIndex"] = conversation.lastReadMessageIndex
        dictionary["lastMessageIndex"] = conversation.lastMessageIndex
        
        var friendlyIdentity = ""
        var friendlyName = ""
        
        guard let participant = message.participant else {
            completion(dictionary)
            return// Complete after all media details are processed
        }
        
        
        participantsDispatchGroup.enter()
        
        
        participant.subscribedUser { result, users in
            friendlyIdentity = users?.identity ?? ""
            friendlyName = users?.friendlyName ?? ""
            participantsDispatchGroup.leave()
        }
        
        participantsDispatchGroup.notify(queue: .main) {
            dictionary["friendlyIdentity"] = friendlyIdentity
            dictionary["friendlyName"] = friendlyName
            
            print(dictionary)
            completion(dictionary) // Complete after all media details are processed
        }
        
    }
    
    
    
    
    func formatLastMessageDateISO8601(lastMessageDateString: String?) -> String? {
        // Create an ISO8601 date formatter for the input
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Create a standard date formatter for the desired output
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        outputFormatter.timeZone = TimeZone(abbreviation: "UTC") // Convert to UTC
        
        // Parse the input date and format it to the desired output
        if let date = inputFormatter.date(from: lastMessageDateString ?? "") {
            let outputDateString = outputFormatter.string(from: date)
            print("lastMessageDateTime->\(outputDateString)")
            return outputDateString
        } else {
            print("Failed to parse date string")
            return nil
        }
    }
}

extension String {
    var hexToData: Data? {
        // Ensure the string contains a valid hex format and even number of characters
        guard self.count % 2 == 0,
              self.range(of: "^[0-9a-fA-F]+$", options: .regularExpression) != nil else {
            return nil
        }
        
        // Convert the hex string to `Data`
        var data = Data()
        var index = startIndex
        while index < endIndex {
            let nextIndex = self.index(index, offsetBy: 2)
            if let byte = UInt8(self[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil // Return nil if conversion fails
            }
            index = nextIndex
        }
        return data
    }
}
