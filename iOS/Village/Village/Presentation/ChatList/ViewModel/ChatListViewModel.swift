//
//  ChatListViewModel.swift
//  Village
//
//  Created by 박동재 on 2023/11/24.
//

import Foundation
import Combine

final class ChatListViewModel {
    
    private var cancellableBag = Set<AnyCancellable>()
    private let chatList = PassthroughSubject<GetChatListResponseDTO, NetworkError>()
    
    func transform(input: Input) -> Output {
        input.getChatListSubject
            .sink(receiveValue: { [weak self] () in
                self?.getList()
            })
            .store(in: &cancellableBag)
        
        return Output(chatList: chatList.eraseToAnyPublisher())
    }
    
    private func getList() {
        ChatListUseCase(
            repository: DefaultChatListRepository()
        ) { [weak self] result in
            switch result {
            case .success(let list):
                self?.chatList.send(list)
            case .failure(let error):
                self?.chatList.send(completion: .failure(error))
            }
        }
        .start()
    }
    
    func deleteChatRoom(roomID: Int) {
        let request = ChatRoomRequestDTO(roomID: roomID)
        let endpoint = APIEndPoints.deleteChatRoom(with: request)
        
        Task {
            do {
                try await APIProvider.shared.request(with: endpoint)
            } catch {
                dump(error)
            }
        }
    }
    
}

extension ChatListViewModel {
    
    struct Input {
        let getChatListSubject: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let chatList: AnyPublisher<GetChatListResponseDTO, NetworkError>
    }
    
}
