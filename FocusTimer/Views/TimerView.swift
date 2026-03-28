// TimerView.swift
// 메인 타이머 뷰 — 원형 프로그레스 링 + 컨트롤

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        ZStack {
            AppTheme.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // 세션 유형 표시
                sessionLabel

                // 원형 프로그레스 타이머
                circularTimer

                // 컨트롤 버튼
                controlButtons

                // 오늘 통계 요약
                todaySummary
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 세션 유형 라벨

    private var sessionLabel: some View {
        Text(sessionTitle)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(sessionAccentColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(sessionAccentColor.opacity(0.15))
            )
            .padding(.top, 24)
    }

    private var sessionTitle: String {
        switch timerVM.currentSessionType {
        case .focus: return "집중 모드"
        case .shortBreak: return "짧은 휴식"
        case .longBreak: return "긴 휴식"
        }
    }

    private var sessionAccentColor: Color {
        switch timerVM.currentSessionType {
        case .focus: return AppTheme.accent
        case .shortBreak, .longBreak: return AppTheme.breakColor
        }
    }

    // MARK: - 원형 타이머

    private var circularTimer: some View {
        ZStack {
            // 배경 트랙
            Circle()
                .stroke(AppTheme.trackColor, lineWidth: 12)

            // 프로그레스 링
            Circle()
                .trim(from: 0, to: timerVM.progress)
                .stroke(
                    AngularGradient(
                        colors: [sessionAccentColor.opacity(0.6), sessionAccentColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * timerVM.progress)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: timerVM.progress)

            // 시간 표시
            VStack(spacing: 8) {
                Text(timerVM.formattedTime)
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundColor(.white)

                Text(sessionSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(width: 260, height: 260)
        .padding(.vertical, 16)
    }

    private var sessionSubtitle: String {
        switch timerVM.timerState {
        case .idle:
            return "시작을 눌러주세요"
        case .running:
            return timerVM.currentSessionType == .focus ? "집중하세요" : "쉬어가세요"
        case .paused:
            return "일시정지됨"
        }
    }

    // MARK: - 컨트롤 버튼

    private var controlButtons: some View {
        HStack(spacing: 24) {
            // 리셋 버튼
            Button(action: { timerVM.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(AppTheme.surface)
                    )
            }

            // 시작/일시정지 메인 버튼
            Button(action: {
                if timerVM.timerState == .running {
                    timerVM.pause()
                } else {
                    timerVM.start()
                }
            }) {
                Image(systemName: timerVM.timerState == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(sessionAccentColor)
                            .shadow(color: sessionAccentColor.opacity(0.5), radius: 12, y: 4)
                    )
            }

            // 건너뛰기 버튼
            Button(action: { timerVM.skipToNext() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(AppTheme.surface)
                    )
            }
        }
    }

    // MARK: - 오늘 통계

    private var todaySummary: some View {
        HStack(spacing: 40) {
            VStack(spacing: 4) {
                Text("\(timerVM.completedPomodoros)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("포모도로")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
            }

            Rectangle()
                .fill(AppTheme.trackColor)
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text(formattedTodayFocus)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("집중 시간")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
        )
    }

    private var formattedTodayFocus: String {
        let minutes = timerVM.todayFocusSeconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            return "\(hours)h \(remaining)m"
        }
        return "\(minutes)m"
    }
}
