//
//  ChatRoomViewModel.swift
//  Village
//
//  Created by 박동재 on 2023/11/26.
//

import Foundation
import Combine

struct Message: Hashable, Codable {
    
    let sender: String
    let message: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case sender
        case message
        case count
    }
    
}

final class ChatRoomViewModel {
    
    private let roomIDOutput = PassthroughSubject<Int, Never>()
    private let joinOutput = PassthroughSubject<Int, Never>()
    private let postIDOutput = PassthroughSubject<Int, Never>()
    private let postOutput = PassthroughSubject<PostDetail, NetworkError>()
    private let userOutput = PassthroughSubject<UserDetail, NetworkError>()
    private let reportOutput = PassthroughSubject<(postID: Int, userID: String), Never>()
    private let popViewControllerOutput = PassthroughSubject<Void, NetworkError>()
    private let tableViewReloadOutput = PassthroughSubject<Void, Never>()
    private var cancellableBag = Set<AnyCancellable>()
    
    private let roomID: Int
    private var userID: String = ""
    private var postID: Int = 0
    
    var myProfileURL: String = ""
    var opponentProfileURL: String = ""
    var myProfileData: Data = Data()
    var opponentProfileData: Data = Data()
    
    private var chatLog: [Message] = []
    
    init(roomID: Int) {
        self.roomID = roomID
    }
    
    func transform(input: Input) -> Output {
        input.roomIDInput.sink { [weak self] _ in
            guard let self = self else { return }
            self.getChatRoomData()
        }
        .store(in: &cancellableBag)
        
        input.postInput.sink { [weak self] _ in
            self?.getPostData()
        }
        .store(in: &cancellableBag)
        
        input.userInput.sink { [weak self] _ in
            self?.getUserData()
        }
        .store(in: &cancellableBag)
        
        input.joinInput.sink { [weak self] _ in
            guard let self = self else { return }
            self.joinOutput.send(self.roomID)
        }
        .store(in: &cancellableBag)
        
        input.sendInput.sink { [weak self] _ in
            guard let self = self else { return }
            self.roomIDOutput.send(self.roomID)
        }
        .store(in: &cancellableBag)
        
        input.pushInput.sink { [weak self] _ in
            guard let self = self else { return }
            self.postIDOutput.send(self.postID)
        }
        .store(in: &cancellableBag)
        
        input.reportInput.sink { [weak self] _ in
            guard let self = self else { return }
            self.reportOutput.send((self.postID, self.userID))
        }
        .store(in: &cancellableBag)
        
        return Output(
            joinOutput: joinOutput.eraseToAnyPublisher(),
            roomIDOutput: roomIDOutput.eraseToAnyPublisher(),
            postIDOutput: postIDOutput.eraseToAnyPublisher(),
            postOutput: postOutput.eraseToAnyPublisher(),
            userOutput: userOutput.eraseToAnyPublisher(),
            reportOutput: reportOutput.eraseToAnyPublisher(),
            popViewControllerOutput: popViewControllerOutput.eraseToAnyPublisher(),
            tableViewReloadOutput: tableViewReloadOutput.eraseToAnyPublisher()
        )
    }
    
    private func setRoom(data: ChatRoom) {
        data.chatLog.forEach { [weak self] chat in
            self?.appendLog(sender: chat.sender, message: chat.message)
        }
        if postID != data.postID {
            postID = data.postID
            if checkUser(userID: data.user) {
                userID = data.writer
                myProfileURL = data.userProfileIMG
                opponentProfileURL = data.writerProfileIMG
            } else {
                userID = data.user
                myProfileURL = data.writerProfileIMG
                opponentProfileURL = data.userProfileIMG
            }
            getPostData()
            getUserData()
            getImageData()
        }
    }
    
    func getChatRoomData() {
        ChatRoomUseCase(
            repository: DefaultChatRoomRepository(),
            roomID: self.roomID
        )
        .start()
        .sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                dump(error)
            }
        } receiveValue: { [weak self] data in
            self?.setRoom(data: data)
        }
        .store(in: &cancellableBag)
    }
    
    func getPostData() {
        PostDetailUseCase(
            repository: DefaultPostDetailRepostory(),
            postID: self.postID
        ) { [weak self] result in
            switch result {
            case .success(let post):
                self?.postOutput.send(post)
            case .failure(let error):
                self?.postOutput.send(completion: .failure(error))
            }
        }
        .start()
    }
    
    private func getUserData() {
        UserDetailUseCase(
            repository: DefaultUserDetailRepository(),
            userID: self.userID
        ) { [weak self] result in
            switch result {
            case .success(let user):
                self?.userOutput.send(user)
            case .failure(let error):
                self?.userOutput.send(completion: .failure(error))
            }
        }
        .start()
    }
    
    private func checkUser(userID: String) -> Bool {
        let currentUserID = JWTManager.shared.currentUserID
        return userID == currentUserID ? true : false
    }

    private func getImageData() {
        Task {
            do {
                let myData = try await APIProvider.shared.request(from: self.myProfileURL)
                let opponentData = try await APIProvider.shared.request(from: self.opponentProfileURL)
                self.myProfileData = myData
                self.opponentProfileData = opponentData
                self.tableViewReloadOutput.send()
            } catch let error {
                dump(error)
            }
        }
    }
    
    private func blockUser() {
        let endpoint = APIEndPoints.blockUser(userID: self.userID)
        
        Task {
            do {
                try await APIProvider.shared.request(with: endpoint)
                PostNotificationPublisher.shared.publishPostRefreshAll()
                popViewControllerOutput.send()
            } catch let error as NetworkError {
                popViewControllerOutput.send(completion: .failure(error))
            } catch {
                dump(error)
            }
        }
    }
    
    func appendLog(sender: String, message: String) {
        chatLog.append(Message(sender: sender, message: message, count: chatLog.count))
    }
    
    func getLog() -> [Message] {
        return chatLog
    }
    
    func checkSender(message: Message) -> Bool {
        if message.count >= 1 && message.count < chatLog.count {
            return chatLog[message.count-1].sender != chatLog[message.count].sender ? true : false
        } else if message.count == chatLog.count {
            return chatLog[chatLog.count-2].sender != message.sender ? true : false
        }
        return true
    }
    
    func getMyImageData() -> Data {
        return self.myProfileData
    }
    
    func getOpponentImageData() -> Data {
        return self.opponentProfileData
    }
    
}

extension ChatRoomViewModel {
    
    struct Input {
        let roomIDInput: AnyPublisher<Void, Never>
        let postInput: AnyPublisher<Void, Never>
        let userInput: AnyPublisher<Void, Never>
        let joinInput: AnyPublisher<Void, Never>
        let sendInput: AnyPublisher<Void, Never>
        let pushInput: AnyPublisher<Void, Never>
        let blockInput: AnyPublisher<Void, Never>
        let reportInput: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let joinOutput: AnyPublisher<Int, Never>
        let roomIDOutput: AnyPublisher<Int, Never>
        let postIDOutput: AnyPublisher<Int, Never>
        let postOutput: AnyPublisher<PostDetail, NetworkError>
        let userOutput: AnyPublisher<UserDetail, NetworkError>
        let reportOutput: AnyPublisher<(postID: Int, userID: String), Never>
        let popViewControllerOutput: AnyPublisher<Void, NetworkError>
        let tableViewReloadOutput: AnyPublisher<Void, Never>
    }
    
}
