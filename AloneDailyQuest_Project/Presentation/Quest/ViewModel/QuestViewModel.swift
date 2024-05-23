//
//  QuestViewModel.swift
//  AloneDailyQuest_Project
//
//  Created by Matthew on 5/10/24.
//

import Foundation

@MainActor
final class QuestViewModel: ViewModel {
    struct Input {
        var viewWillAppear: Observable<Void>
        var deleteTrigger: Observable<QuestInfo?>
        var qeusetViewEvent: Observable<Void>
        var rankViewEvent: Observable<Void>
        var profileViewEvent: Observable<Void>
        var didPlusButtonTap: Observable<Void>
        var updateQuestEvent: Observable<QuestInfo>
        var completeQuestEvent: Observable<QuestInfo>
    }
    
    struct Output {
        var questList: Observable<[QuestInfo]>
        var errorMessage: Observable<String>
        var userInfo: Observable<UserInfo?>
    }
    
    private let usecase: QuestUsecase
    private let coordinator: QuestCoordinator
    private let questList: Observable<[QuestInfo]> = Observable([])
    private let errorMessage: Observable<String> = Observable("")
    private let user: Observable<UserInfo?> = Observable(nil)
    
    init(usecase: QuestUsecase, coordinator: QuestCoordinator) {
        self.usecase = usecase
        self.coordinator = coordinator
    }
    
    private func viewWillAppear() {
        Task {
            try await usecase.updateDailyQuest()
            await fetchQuest()
            fetchUserInfo()
        }
    }
    
    private func fetchUserInfo() {
        self.user.value = UserInfo(nickName: UserDefaults.standard.string(forKey: "nickName") ?? "",
                                   experience: UserDefaults.standard.integer(forKey: "experience"))
    }
    
    private func fetchQuest() async {
        Task {
            do {
                questList.value = try await usecase.readQuest()
            } catch {
                errorMessage.value = error.localizedDescription
            }
        }
    }
    
    func deleteQuest(quest: QuestInfo) {
        Task {
            do {
                try await usecase.deleteQuest(questInfo: quest)
                questList.value = try await usecase.readQuest()
            } catch {
                errorMessage.value = error.localizedDescription
            }
        }
    }
    
    func updateQuest(quest: QuestInfo) {
        Task {
            do {
                try await usecase.updateQuest(newQuestInfo: quest)
                questList.value = try await usecase.readQuest()
                updateExperience(experienceData: 1)
            } catch {
                errorMessage.value = error.localizedDescription
            }
        }
    }
    
    func updateExperience(experienceData: Int) {
        Task {
            do {
                let result = try await usecase.addExperience(userId: UserDefaults.standard.string(forKey: "nickName") ?? "",
                                                             experience: experienceData)
                UserDefaults.standard.set(result, forKey: "experience")
                fetchUserInfo() 
            } catch {
                errorMessage.value = error.localizedDescription
            }
        }
    }
    
    func transform(input: Input) -> Output {
        input.viewWillAppear.bind { [weak self] _ in
            self?.viewWillAppear()
        }
        input.updateQuestEvent.bind { [weak self] quest in
            self?.coordinator.connectDetailCoordinator(quest: quest)
        }
        input.deleteTrigger.bind { [weak self] quest in
            self?.deleteQuest(quest: quest!)
        }
        input.completeQuestEvent.bind { [weak self] quest in
            self?.updateQuest(quest: quest)
        }
        input.qeusetViewEvent.bind { _ in
            return
        }
        input.rankViewEvent.bind { [weak self] _ in
            self?.coordinator.finish(to: .ranking)
        }
        input.profileViewEvent.bind { [weak self] _ in
            self?.coordinator.finish(to: .profile)
        }
        input.didPlusButtonTap.bind { [weak self] _ in
            self?.coordinator.connectDetailCoordinator(quest: nil)
        }
        return .init(questList: self.questList,
                     errorMessage: self.errorMessage,
                     userInfo: self.user)
    }
}
