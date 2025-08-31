

<img width="1920" height="1080" alt="readmeImage" src="https://github.com/user-attachments/assets/8aff0cab-c2b7-45f9-ab63-66df88502b17" />


<div align="center">

<br>

**AI를 기반**으로 사용자의 **일정·운동·휴식**을 관리하여 건강하고 균형 잡힌 생활을 실현할 수 있도록 돕는 **라이프스타일 플래너**입니다.

</div>

<br>

<div align="center">

## 🧑🏻‍💻👩🏻‍💻 팀원
| <img src="https://github.com/pde0814.png?size=100" width="100"/> | <img src="https://github.com/puuurm.png?size=100" width="100"/> | <img src="https://github.com/twoweeks-y.png?size=100" width="100"/> | <img src="https://github.com/vinyl-nyl.png?size=100" width="100"/> | <img src="https://github.com/Jeon-GwangHo.png?size=100" width="100"/> | <img src="https://github.com/SoyiJeong.png?size=100" width="100"/> |
| :---: | :---: | :---: | :---: | :---: | :---: |
| [박동언](https://github.com/pde0814) | [양희정](https://github.com/puuurm) | [이주용](https://github.com/twoweeks-y) | [이준일](https://github.com/vinyl-nyl) | [전광호](https://github.com/Jeon-GwangHo) | [정소이](https://github.com/SoyiJeong) |
| 🧑🏻‍💻 팀원 | 👑 팀장 | 🧑🏻‍💻 팀원 | 🧑🏻‍💻 팀원 | 🧑🏻‍💻 팀원 | 👩🏻‍💻 팀원 |
| `PlanView`<br>`Code Review` | `ScheduleInputView`<br>`CoreData` | `HomeView`<br>`Tech Write` | `ScheduleInputView`<br>`AnalyticsView`<br>`Presentation` | `SettingsView`<br>`Quality Assurance` | `OnboardingView`<br>`Design Lead` |

</div>

<br>
<br>



## 💡 주요 기능
- 온보딩에서 받은 사용자의 신체정보, 선호운동, 건강상태를 기반으로 맞춤형 콘텐츠 추천
- Alan AI 기반 사용자 맞춤형 일정 추천
- 일정 조회, 등록 및 삭제
- 건강 앱과 연동하여 걸음수, 수면시간 조회 및 기록
- 웰니스 목표 설정 및 달성률 피드백 제공



## 📌 요구사항
### 기능 요구사항 (Functional Requirements)
| 화면 | 요구사항 |
| :--: | ----- |
| 공통 | - 화면 간 이동에 문제 발생하지 않음<br> - 하단 탭바/사이드 메뉴 등 공통 네비게이션 제공<br> - 공통으로 사용되는 UI 컴포넌트/함수 등 분리 |
| 온보딩 | - 전반적인 앱 소개<br> - 사용자의 신체정보, 선호활동, 건강상태 등 설문 조사 |
| 홈 | - 온보딩 설문을 바탕으로 사용자 프로필 제공<br> - 오늘의 일정 확인 및 완료 여부 체크<br> - 오늘의 일정 삭제<br> - 사용자 맞춤형 컨텐츠(날씨, 영상) 제공<br> - 웰니스 목표 및 시각화된 달성률 피드백 제공 |
| 일정 | - 사용자의 선호, 필요사항을 기반으로 맞춤형 일정 추천<br> - 직접/Alan AI 기반 일정 생성, 수정 및 삭제<br> - 캘린더 형태의 시각화된 일정 확인<br> - 일정 시간(시작/종료) 및 반복/알림 설정<br> - 장소 및 메모 추가 및 수정 |
| 통계 | - 건강 앱과 연동해 걸음수, 수면시간 확인 및 기록<br> - 일/주/월 단위로 확인 및 기록<br> - 시각화된 웰니스 목표 달성률 피드백 제공<br> - AI 인사이트 제공 |
| 설정 | - 사용자 프로필 관리<br> - 알림/건강 앱 연동 설정<br> - 모든 일정 삭제(초기화)<br> - 온보딩 사용자 설문 수정 |

### 비기능 요구사항 (Non-Functional Requirements)
| 항목 | 요구사항 |
| :--: | ----- |
| 디자인 및 UI/UX | - SwiftUI 사용 <br>- iPhone(세로), iPad(가로/세로) 지원<br>- Size Class, 다크모드 대응 |
| 성능 안정성 | - Crash, UI/기능 버그 방지<br>- 참조 사이클 메모리 누수 방지 및 옵션 처리 시 예외 상황 대응<br> - GCD 사용은 가급적 지양하고 Swift Concurrency를 활용 |
| 데이터 저장 방식 | - 모델 정의 및 영구적인 데이터 저장<br> - CoreData, UserDefaults, 바이너리 파일 사용 |
| 접근성 및 사용자 경험 | - 버튼 색상, 알림 등 시각적 피드백 적용 |
| 위치 기반 서비스 | - CoreLoacation을 통한 위치 정보 권한 확인<br> - 원활한 OpenWeather API 호출 |
| 호환성 | - iOS 16 이상 지원 |



## 🛠️ 기술 스택
- SwiftUI
- CoreData, UserDefaults, 바이너리 파일
- Alan API, OpenWeather API, Youtube data API API
- CoreLocation, HealthKit



## 📁 폴더 구조
- MVVM 패턴
- App: 앱 실행 진입점
- Feature: 주요 기능 단위 화면 (온보딩, 홈, 일정, 통계, 설정)
- Resource: 이미지 및 컬러 리소스
- Shared: 공통 UI, 컴포넌트, 모델, 로컬 데이터, 외부 API 모음 및 관리
- Tests: 단위 테스트



## 📂 프로젝트 구조

```swift
Wellnest
├── App
│   ├── AppRouter.swift              # 화면 이동 및 네비게이션 라우터
│   ├── WellnestApp.swift            # 앱 진입점
│
├── Feature                          # 주요 화면
│   ├── Analytics                    # 통계
│   ├── Home                         # 홈
│   ├── MainTab                      # 메인 탭 바
│   ├── Onboarding                   # 온보딩
│   ├── Plan                         # 일정 조회
│   ├── ScheduleInput                # 일정 생성, 수정 및 삭제
│   ├── Settings                     # 설정
│   └── Splash                       # 스플래시 스크린
│
├── Resource
│   ├── Assets.xcassets              # 이미지, 컬러 등 리소스
│   └── schedule_dummy_data.json     # 일정 샘플 데이터
│
├── Shared                           # 공용 모듈
│   ├── Common                       # 상수, 공통 유틸, 확장(Extensions)
│   ├── Model                        # 데이터 모델 (User, Schedule 등)
│   ├── Persistence                  # CoreData 등 로컬 저장소
│   ├── Service                      # 외부 API, CoreLocation 연동
│   └── View                         # 재사용 가능한 공통 UI 컴포넌트
```



## 🖥️ 주요 화면
| Splash | Onboarding | Onboarding |
| :--: | :--: | :--: |
| <img width="200" alt="스플래시" src="https://github.com/user-attachments/assets/2b0bdbb4-baaa-45da-964e-bd84aa357ad9" /> | <img width="200" alt="앱소개1" src="https://github.com/user-attachments/assets/0d15e573-8f72-4f57-b427-73d96e2f162c" /> | <img width="200" alt="선호활동" src="https://github.com/user-attachments/assets/8b8b5407-fdfc-484a-9940-11e62c6684ba" /> |

| Home | Home | ScheduleInput | ScheduleInput |
| :--: | :--: | :--: | :--: |
| <img width="200" alt="홈1" src="https://github.com/user-attachments/assets/d344aad3-8859-4cb4-bc31-4b53301136dd" /> | <img width="200" alt="홈2" src="https://github.com/user-attachments/assets/f17244bc-5853-4e98-b764-4154255582eb" /> | <img width="200" alt="일정1" src="https://github.com/user-attachments/assets/029dc449-38ae-42b0-822b-0989a7b3731e" /> | <img width="200" alt="일정2" src="https://github.com/user-attachments/assets/9b823ebc-727d-49e9-a847-0a1ffb9b73fa" /> |

| Plan | Plan | Analytics | Settings |
| :--: | :--: | :--: | :--: |
| <img width="200" alt="달력1" src="https://github.com/user-attachments/assets/24478ed0-89a8-4fb5-9046-a7697114e5e9" /> | <img width="200" alt="달력2" src="https://github.com/user-attachments/assets/5fff99b4-ad43-4a53-a205-6670e904c7a4" /> | <img width="200" alt="통계1" src="https://github.com/user-attachments/assets/73bb3a60-e0a1-4761-a791-5b02ef985bff" /> | <img width="200" alt="설정" src="https://github.com/user-attachments/assets/4f16d184-0a08-4ff3-9e1c-4ab991a31f09" /> |


