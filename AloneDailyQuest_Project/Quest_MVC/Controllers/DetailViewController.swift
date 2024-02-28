//
//  DetailViewController.swift
//  AloneDailyQuest_Project
//
//  Created by 오정석 on 12/1/2024.
//

import UIKit

final class DetailViewController: UIViewController {
    
    private let detailView = DetailView()
    weak var delegate: delegateViewController? = nil
    
    override func loadView() {
        self.view = detailView
    }
    
    let questManager = CoreDataManager.shared
    
    var questData: QuestData? {
        didSet {
        }
    }
    
    
    var isDaySelected = [false, false, false, false, false, false, false]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        configureUI()
        
    }
    
    func setup() {
        detailView.questTextView.delegate = self
        detailView.buttons.forEach{ button in
            button.addTarget(self, action: #selector(dayButtonTapped), for: .touchUpInside)
        }
        
        detailView.saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
            }
    
    func configureUI() {
        // 기존 데이터가 있을떄
        if let questData = self.questData {
            detailView.titleText.text = "퀘스트수정"
            detailView.titleBackgroundText.text = "퀘스트수정"
            guard let text = questData.quest else { return }
            detailView.questTextView.text = text
            
            detailView.questTextView.textColor = .black
            detailView.saveButton.setTitle("퀘스트 수정하기", for: .normal)
            detailView.questTextView.becomeFirstResponder()
            
        // 기존데이터가 없을때
        } else {
            detailView.titleText.text = "퀘스트생성"
            detailView.titleBackgroundText.text = "퀘스트생성"
            
            detailView.questTextView.text = "퀘스트를 입력하세요."
            detailView.questTextView.textColor = .lightGray
            
        }
    }
    
    // 요일 반복 버튼 기능구현
    @objc func dayButtonTapped(_ sender: UIButton){
        guard let index = detailView.buttons.firstIndex(of: sender) else { return }
        
        print("버튼 눌림")
        // 해당 버튼의 선택 여뷰를 토글
        isDaySelected[index].toggle()
        
        // 버튼 외관 업데이트
        toggleButtonAppearance(button: sender, isSelected: isDaySelected[index])
    }
    
    func toggleButtonAppearance(button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = UIColor(red: 0.63, green: 0.28, blue: 0.01, alpha: 1.00)
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = UIColor(red: 1.00, green: 0.90, blue: 0.78, alpha: 1.00)
            button.setTitleColor(.black, for: .normal)
        }
    }
    
    @objc func saveButtonTapped(_ sender: UIButton) {
       
        // 기존 데이터가 있을때 ===> 기존 데이터 업데이트
        if let questData = self.questData {
            // 텍스트뷰에 저장되어 있는 메시지
            questData.quest = detailView.questTextView.text
            questManager.updateQuest(newQuestData: questData) {
                print("업데이트 완료")
                // 다시 전화면으로 돌아가기
                self.navigationController?.popViewController(animated: true)
            }
            
            // 기존데이터가 없을때 ===> 새로운 데이터 생성
        } else {
            guard let questText = detailView.questTextView.text else { return }
            registerQuestForSelectedDays(questText: questText)
        }
    }
    
    func currentDayOfWeek() -> Int {
        let today = Calendar.current.component(.weekday, from: Date())
        return today - 1
    }
    
    func registerQuestForSelectedDays(questText: String) {
        let currentDay = currentDayOfWeek()
        for (index, isSelected) in isDaySelected.enumerated() {
            if isSelected {
                
                questManager.saveQuestData(questText: questText, isMonday: index == 0, isTuesday: index == 1, isWednesday: index == 2, isThursday: index == 3, isFriday: index == 4, isSaturday: index == 5, isSunday: index == 6) {
                    print("퀘스트가 등록되었습니다.")
                    
                }
            }
        }
    }
    
    
    
    // 다른곳을 터치하면 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension DetailViewController: UITextViewDelegate {
    // 입력을 시작할때
    // (텍스트뷰는 플레이스홀더가 따로 있지 않아서, 플레이스 홀더처럼 동작하도록 직접 구현)
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "퀘스트를 여기에 입력하세요." {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    // 입력이 끝났을때
    func textViewDidEndEditing(_ textView: UITextView) {
        // 비어있으면 다시 플레이스 홀더처럼 입력하기 위해서 조건 확인
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "퀘스트를 여기에 입력하세요."
            textView.textColor = .lightGray
        }
    }
}
