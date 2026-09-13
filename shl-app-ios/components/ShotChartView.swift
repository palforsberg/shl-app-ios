//
//  ShotChartView.swift
//  shl-app-ios
//
//  Created by Codex on 2026-02-03.
//

import SwiftUI

struct ShotChartView: View {
    let events: [GameEvent]
    let homeTeam: String
    let awayTeam: String
    var showLegend: Bool = true
    var replayStatus: String? = nil
    var replayGameTime: String? = nil

    @EnvironmentObject var teamsData: TeamsData
    @State private var visibleMarkerCount: Int = .max
    @State private var markerAnimationTask: Task<Void, Never>?
    @State private var displayedClockSeconds: Int = 0
    @State private var isReplaying: Bool = false
    @State private var activePucks: [ActivePuck] = []

    private enum MarkerType {
        case shot
        case goal
    }

    private struct Marker: Identifiable {
        let event: GameEvent
        let type: MarkerType
        let timelineSeconds: Int
        var id: String { event.id }
    }

    fileprivate struct ActivePuck: Identifiable {
        let id: String
        let normalizedStart: CGPoint
        let normalizedImpact: CGPoint
        let normalizedOutcome: CGPoint
        let impactDuration: Double
        let outcomeDuration: Double
        let lingerDuration: Double
        let isGoal: Bool
    }

    private var orderedMarkers: [Marker] {
        var markers: [Marker] = []
        var lastTimeline = 0

        // API events for this view are delivered newest-first; replay needs oldest-first.
        for event in events.reversed() {
            guard let type = markerType(for: event) else {
                continue
            }
            let marker = marker(for: event, type: type, minTimeline: lastTimeline)
            markers.append(marker)
            lastTimeline = marker.timelineSeconds
        }

        return markers
    }

    private var visibleMarkers: [Marker] {
        Array(orderedMarkers.prefix(visibleMarkerCount))
    }

    private var markerSignature: String {
        orderedMarkers.map(\.id).joined(separator: "|")
    }

    private var replaySignature: String {
        "\(replayStatus ?? "")|\(replayGameTime ?? "")|\(markerSignature)"
    }

    private var replayTargetSeconds: Int {
        if let status = replayStatus {
            if status == "Finished" {
                return inferredGameEndSeconds()
            }
            if let gameTime = replayGameTime,
               let total = timelineSeconds(status: status, gameTime: gameTime) {
                return total
            }
        }
        if let maxMarker = orderedMarkers.last?.timelineSeconds {
            return maxMarker
        }
        return 0
    }

    var body: some View {
        let bounds = ShotChartBounds()
        let homeUIColor = teamUIColor(for: homeTeam, fallback: .systemBlue)
        let awayUIColor = teamUIColor(for: awayTeam, fallback: .systemRed)
        let homeColor = Color(uiColor: homeUIColor)
        let awayColor = Color(uiColor: awayUIColor)
        // let mixTarget: UIColor = colorScheme == .dark ? .black : .white
        let mixTarget = UIColor.white
        let shotMixAmount: CGFloat = 0.5
        let homeShotColor = Color(uiColor: mixColor(base: homeUIColor, target: mixTarget, amount: shotMixAmount))
        let awayShotColor = Color(uiColor: mixColor(base: awayUIColor, target: mixTarget, amount: shotMixAmount))

        return VStack(spacing: 10) {
            ZStack {
                RinkBackdrop()
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        ForEach(visibleMarkers) { marker in
                            if let location = marker.event.location,
                               let point = bounds.position(for: location, in: size, flipX: bounds.shouldFlipX(event: marker.event, homeTeam: homeTeam, awayTeam: awayTeam)) {
                                if marker.type == .shot {
                                    let shotColor = teamColor(for: marker.event.team, homeColor: homeShotColor, awayColor: awayShotColor)
                                    Circle()
                                        .fill(shotColor)
                                        .frame(width: 6, height: 6)
                                        .position(point)
                                        .transition(.opacity)
                                } else {
                                    let goalColor = teamColor(for: marker.event.team, homeColor: homeColor, awayColor: awayColor)
                                    Circle()
                                        .fill(goalColor)
                                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 0.5))
                                        .frame(width: 8, height: 8)
                                        .position(point)
                                        .transition(.opacity)
                                }
                            }
                        }
                        ForEach(activePucks) { puck in
                            FlyingPuckView(
                                puck: puck,
                                size: size,
                                onCompleted: { removeActivePuck(id: puck.id) }
                            )
                            .transition(.opacity)
                        }
                    }
                }
                if isReplaying {
                    VStack {
                        Text(clockLabel(for: displayedClockSeconds))
                            .foregroundStyle(.black)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
                if showLegend {
                    HStack(spacing: 100) {
                        ShotLegendItem(fill: homeColor, title: teamsData.getDisplayCode(homeTeam))
                        
                        ShotLegendItem(fill: awayColor, title: teamsData.getDisplayCode(awayTeam))
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .aspectRatio(61.0 / 30.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                replayMarkers()
            }

       
        }
        .padding(.horizontal, 20)
        .onAppear {
            visibleMarkerCount = orderedMarkers.count
            displayedClockSeconds = replayTargetSeconds
        }
        .onChange(of: replaySignature) { (_ , _) in
            markerAnimationTask?.cancel()
            visibleMarkerCount = orderedMarkers.count
            displayedClockSeconds = replayTargetSeconds
            isReplaying = false
            activePucks = []
        }
        .onDisappear {
            markerAnimationTask?.cancel()
            markerAnimationTask = nil
            isReplaying = false
            activePucks = []
        }
    }

    private func teamUIColor(for team: String, fallback: UIColor) -> UIColor {
        if let uiColor = TeamColors.color(for: team) {
            return uiColor
        }
        return fallback
    }

    private func teamColor(for team: String?, homeColor: Color, awayColor: Color) -> Color {
        guard let team else {
            return Color(uiColor: .systemGray2)
        }
        if team == homeTeam {
            return homeColor
        }
        if team == awayTeam {
            return awayColor
        }
        if let uiColor = TeamColors.color(for: team) {
            return Color(uiColor: uiColor)
        }
        return Color(uiColor: .systemGray2)
    }

    private func mixColor(base: UIColor, target: UIColor, amount: CGFloat) -> UIColor {
        let clamped = max(0, min(amount, 1))
        var br: CGFloat = 0
        var bg: CGFloat = 0
        var bb: CGFloat = 0
        var ba: CGFloat = 0
        base.getRed(&br, green: &bg, blue: &bb, alpha: &ba)

        var tr: CGFloat = 0
        var tg: CGFloat = 0
        var tb: CGFloat = 0
        var ta: CGFloat = 0
        target.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)

        let r = br * (1 - clamped) + tr * clamped
        let g = bg * (1 - clamped) + tg * clamped
        let b = bb * (1 - clamped) + tb * clamped
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private func replayMarkers() {
        let total = orderedMarkers.count
        guard total > 0 else {
            return
        }
        markerAnimationTask?.cancel()
        markerAnimationTask = Task {
            defer {
                Task { @MainActor in
                    isReplaying = false
                }
            }
            let bounds = ShotChartBounds()
            let targetSeconds = max(replayTargetSeconds, 0)
            let duration = animationDuration(for: targetSeconds)
            let stepNs: UInt64 = 50_000_000
            var elapsed: Double = 0
            var lastVisible = 0
            var nextPuckIndex = 0

            await MainActor.run {
                isReplaying = true
                withAnimation(.easeOut(duration: 0.12)) {
                    visibleMarkerCount = 0
                }
                displayedClockSeconds = 0
                activePucks = []
            }

            while elapsed < duration {
                if Task.isCancelled { return }
                let progress = min(max(elapsed / duration, 0), 1)
                let replaySecondPrecise = Double(targetSeconds) * progress
                let replaySecond = Int((Double(targetSeconds) * progress).rounded(.down))
                let visible = visibleCount(at: replaySecond)
                var launchedPucks: [ActivePuck] = []
                while nextPuckIndex < orderedMarkers.count,
                      Double(orderedMarkers[nextPuckIndex].timelineSeconds) <= replaySecondPrecise {
                    if let puck = makeActivePuck(
                        for: nextPuckIndex,
                        bounds: bounds,
                        targetSeconds: targetSeconds,
                        replayDuration: duration
                    ) {
                        launchedPucks.append(puck)
                    }
                    nextPuckIndex += 1
                }
                await MainActor.run {
                    displayedClockSeconds = replaySecond
                    if !launchedPucks.isEmpty {
                        activePucks.append(contentsOf: launchedPucks)
                    }
                    if visible != lastVisible {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            visibleMarkerCount = visible
                        }
                    }
                }
                lastVisible = visible
                try? await Task.sleep(nanoseconds: stepNs)
                elapsed += 0.05
            }

            let finalVisible = visibleCount(at: targetSeconds)
            var launchedPucks: [ActivePuck] = []
            while nextPuckIndex < orderedMarkers.count {
                if let puck = makeActivePuck(
                    for: nextPuckIndex,
                    bounds: bounds,
                    targetSeconds: targetSeconds,
                    replayDuration: duration
                ) {
                    launchedPucks.append(puck)
                }
                nextPuckIndex += 1
            }
            await MainActor.run {
                displayedClockSeconds = targetSeconds
                if !launchedPucks.isEmpty {
                    activePucks.append(contentsOf: launchedPucks)
                }
                withAnimation(.easeInOut(duration: 0.12)) {
                    visibleMarkerCount = finalVisible
                }
            }
        }
    }

    private func markerNormalizedPosition(for marker: Marker, bounds: ShotChartBounds) -> CGPoint? {
        guard let location = marker.event.location else {
            return nil
        }
        let flipX = bounds.shouldFlipX(event: marker.event, homeTeam: homeTeam, awayTeam: awayTeam)
        return bounds.normalizedPosition(for: location, flipX: flipX, normalizeEventX: true)
    }

    private func makeActivePuck(for markerIndex: Int, bounds: ShotChartBounds, targetSeconds: Int, replayDuration: Double) -> ActivePuck? {
        guard markerIndex >= 0, markerIndex < orderedMarkers.count else {
            return nil
        }
        let marker = orderedMarkers[markerIndex]
        guard let start = markerNormalizedPosition(for: marker, bounds: bounds) else {
            return nil
        }
        let impact = goalImpactNormalizedPosition(for: marker, bounds: bounds)
        let outcome = marker.type == .goal
            ? goalInsideNetNormalizedPosition(for: marker, bounds: bounds)
            : reboundNormalizedPosition(start: start, impact: impact)
        var (impactDuration, outcomeDuration) = puckDurations(for: markerIndex, targetSeconds: targetSeconds, replayDuration: replayDuration)
        let isGoal = marker.type == .goal
        if !isGoal {
            // Rebounds should feel heavier/slower than the incoming shot.
            outcomeDuration *= 2.6
        }
        let lingerDuration = isGoal ? 0.88 : 0.85

        return ActivePuck(
            id: marker.id,
            normalizedStart: start,
            normalizedImpact: impact,
            normalizedOutcome: outcome,
            impactDuration: impactDuration,
            outcomeDuration: outcomeDuration,
            lingerDuration: lingerDuration,
            isGoal: isGoal
        )
    }

    private func goalImpactNormalizedPosition(for marker: Marker, bounds: ShotChartBounds) -> CGPoint {
        let rinkLengthM: CGFloat = 61
        let eventLengthDm: CGFloat = 600
        let goalLineFromBoardM: CGFloat = 4
        let goalHalfWidthDm: Int = 18

        let goalXMeters: CGFloat = marker.event.team == homeTeam
            ? goalLineFromBoardM
            : (rinkLengthM - goalLineFromBoardM)
        let goalXDm = Int((goalXMeters / rinkLengthM) * eventLengthDm)
        let locationY = marker.event.location?.y ?? 0
        let impactY = max(-goalHalfWidthDm, min(goalHalfWidthDm, locationY))
        let target = EventLocation(x: goalXDm, y: impactY)
        return bounds.normalizedPosition(for: target, flipX: false, normalizeEventX: false) ?? CGPoint(x: 0.5, y: 0.5)
    }

    private func goalInsideNetNormalizedPosition(for marker: Marker, bounds: ShotChartBounds) -> CGPoint {
        let rinkLengthM: CGFloat = 61
        let eventLengthDm: CGFloat = 600
        let goalLineFromBoardM: CGFloat = 4
        let netDepthM: CGFloat = 1.2
        let goalHalfWidthDm: Int = 18

        let inNetXMeters: CGFloat = marker.event.team == homeTeam
            ? max(0, goalLineFromBoardM - netDepthM)
            : min(rinkLengthM, rinkLengthM - goalLineFromBoardM + netDepthM)
        let inNetXDm = Int((inNetXMeters / rinkLengthM) * eventLengthDm)
        let locationY = marker.event.location?.y ?? 0
        let inNetY = max(-goalHalfWidthDm, min(goalHalfWidthDm, locationY))
        let target = EventLocation(x: inNetXDm, y: inNetY)
        return bounds.normalizedPosition(for: target, flipX: false, normalizeEventX: false) ?? CGPoint(x: 0.5, y: 0.5)
    }

    private func reboundNormalizedPosition(start: CGPoint, impact: CGPoint) -> CGPoint {
        let dx = impact.x - start.x
        let dy = impact.y - start.y
        let length = max(sqrt((dx * dx) + (dy * dy)), 0.0001)
        let ux = dx / length
        let uy = dy / length

        let backDistance: CGFloat = 0.05
        let sideDistance: CGFloat = 0.015
        let sideSign: CGFloat = start.y >= 0.5 ? -1 : 1

        let rebound = CGPoint(
            x: impact.x - (ux * backDistance) + ((-uy) * sideDistance * sideSign),
            y: impact.y - (uy * backDistance) + (ux * sideDistance * sideSign)
        )
        return clampNormalizedPoint(rebound)
    }

    private func clampNormalizedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0.02), 0.98),
            y: min(max(point.y, 0.02), 0.98)
        )
    }

    private func puckDurations(for markerIndex: Int, targetSeconds: Int, replayDuration: Double) -> (Double, Double) {
        guard markerIndex >= 0,
              markerIndex < orderedMarkers.count,
              targetSeconds > 0,
              replayDuration > 0 else {
            return (0.16, 0.10)
        }
        let marker = orderedMarkers[markerIndex]
        let nextEventTime = markerIndex + 1 < orderedMarkers.count
            ? orderedMarkers[markerIndex + 1].timelineSeconds
            : targetSeconds
        let currentElapsed = (Double(marker.timelineSeconds) / Double(targetSeconds)) * replayDuration
        let nextElapsed = (Double(nextEventTime) / Double(targetSeconds)) * replayDuration
        let available = max(nextElapsed - currentElapsed, 0)
        let total = min(0.55, max(0.26, available * 0.65))
        let impact = total * 0.74
        let outcome = total - impact
        return (impact, max(outcome, 0.08))
    }

    private func removeActivePuck(id: String) {
        withAnimation(.easeOut(duration: 0.18)) {
            activePucks.removeAll { $0.id == id }
        }
    }

    private func periodOrder(_ status: String) -> Int {
        switch status {
        case "Period1": return 1
        case "Period2": return 2
        case "Period3": return 3
        case "Overtime": return 4
        case "Shootout": return 5
        default: return 9
        }
    }

    private func gameTimeToSeconds(_ gameTime: String) -> Int? {
        let parts = gameTime.split(separator: ":")
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]) else {
            return nil
        }
        return minutes * 60 + seconds
    }

    private func markerType(for event: GameEvent) -> MarkerType? {
        if event.getEventType() == .goal || event.type == "Goal" {
            return .goal
        }
        if event.type.lowercased().contains("shot") {
            return .shot
        }
        return nil
    }

    private func marker(for event: GameEvent, type: MarkerType, minTimeline: Int) -> Marker {
        let sec = resolvedTimelineSeconds(status: event.status, gameTime: event.gametime, minimum: minTimeline)
        return Marker(event: event, type: type, timelineSeconds: sec)
    }

    private func resolvedTimelineSeconds(status: String, gameTime: String, minimum: Int) -> Int {
        if let resolved = timelineSeconds(status: status, gameTime: gameTime) {
            return max(resolved, minimum)
        }
        guard let periodSeconds = gameTimeToSeconds(gameTime) else {
            return minimum
        }

        let candidates = [
            periodSeconds,
            1200 + periodSeconds,
            2400 + periodSeconds,
            3600 + periodSeconds,
        ]
        if let candidate = candidates.first(where: { $0 >= minimum }) {
            return candidate
        }
        return minimum
    }

    private func timelineSeconds(status: String, gameTime: String) -> Int? {
        guard let seconds = gameTimeToSeconds(gameTime) else {
            return nil
        }
        switch status {
        case "Period1": return seconds
        case "Period2": return 1200 + seconds
        case "Period3": return 2400 + seconds
        case "Overtime": return 3600 + seconds
        case "Shootout": return 3900 + seconds
        default: return nil
        }
    }

    private func inferredGameEndSeconds() -> Int {
        let maxPeriod = max(orderedMarkers.map { periodOrder($0.event.status) }.max() ?? 1, 3)
        switch maxPeriod {
        case 1: return 1200
        case 2: return 2400
        case 3: return 3600
        case 4: return 3900
        default: return 3900
        }
    }

    private func visibleCount(at replaySecond: Int) -> Int {
        orderedMarkers.prefix { $0.timelineSeconds <= replaySecond }.count
    }

    private func animationDuration(for targetSeconds: Int) -> Double {
        if targetSeconds <= 0 { return 0.1 }
        let scaled = Double(targetSeconds) / 450.0
        return min(max(scaled, 4.0), 12.0)
    }

    private func clockLabel(for totalSeconds: Int) -> String {
        let sec = max(totalSeconds, 0)
        if sec < 1200 {
            return "P1 \(formatClock(sec))"
        }
        if sec < 2400 {
            return "P2 \(formatClock(sec - 1200))"
        }
        if sec < 3600 {
            return "P3 \(formatClock(sec - 2400))"
        }
        if sec < 3900 {
            return "OT \(formatClock(sec - 3600))"
        }
        return "SO"
    }

    private func formatClock(_ seconds: Int) -> String {
        let m = max(seconds, 0) / 60
        let s = max(seconds, 0) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct FlyingPuckView: View {
    let puck: ShotChartView.ActivePuck
    let size: CGSize
    let onCompleted: () -> Void

    @State private var currentNormalizedPosition: CGPoint = .zero

    var body: some View {
        Circle()
            .fill(Color.black)
            .frame(width: 5, height: 5)
            .position(
                x: currentNormalizedPosition.x * size.width,
                y: currentNormalizedPosition.y * size.height
            )
            .onAppear {
                currentNormalizedPosition = puck.normalizedStart
                Task {
                    withAnimation(.linear(duration: max(puck.impactDuration, 0.01))) {
                        currentNormalizedPosition = puck.normalizedImpact
                    }
                    try? await Task.sleep(nanoseconds: UInt64(max(puck.impactDuration, 0.01) * 1_000_000_000))

                    let outcomeAnimation: Animation = puck.isGoal
                        ? .easeIn(duration: max(puck.outcomeDuration, 0.01))
                        : .easeOut(duration: max(puck.outcomeDuration, 0.01))
                    withAnimation(outcomeAnimation) {
                        currentNormalizedPosition = puck.normalizedOutcome
                    }
                    try? await Task.sleep(nanoseconds: UInt64(max(puck.outcomeDuration, 0.01) * 1_000_000_000))
                    try? await Task.sleep(nanoseconds: UInt64(max(puck.lingerDuration, 0.01) * 1_000_000_000))

                    await MainActor.run {
                        onCompleted()
                    }
                }
            }
    }
}

private struct ShotLegendItem: View {
    let fill: Color
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(fill)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(Color(uiColor: .secondaryLabel))
    }
}

private struct TeamColors {
    static let map: [String: UIColor] = [
        // SHL
        "LHF": UIColor(hex: 0x000000),
        "SAIK": UIColor(hex: 0xFBB906),
        "FHC": UIColor(hex: 0x00573F),
        "FBK": UIColor(hex: 0x008E52),
        "LHC": UIColor(hex: 0x002E6D),
        "LIF": UIColor(hex: 0x133478),
        "MIF": UIColor(hex: 0xA2040E),
        "OHK": UIColor(hex: 0xB3001B),
        "RBK": UIColor(hex: 0x0E7A30),
        "TIK": UIColor(hex: 0xC60C0F),
        "VLH": UIColor(hex: 0x002D62),
        "HV71": UIColor(hex: 0x133562),
        "IKO": UIColor(hex: 0x114495),
        "DIF": UIColor(hex: 0x0A497F),

        // HA
        "AIK": UIColor(hex: 0x000000),
        "BIF": UIColor(hex: 0xF5C400),
        "MODO": UIColor(hex: 0xA50D0A),
        "IFB": UIColor(hex: 0x007A33),
        "MIK": UIColor(hex: 0xE42313),
        "VIK": UIColor(hex: 0xFFD100),
        "SOD": UIColor(hex: 0xC8102E),
        "TAIF": UIColor(hex: 0x006747),
        "BIK": UIColor(hex: 0x002D74),
        "AIS": UIColor(hex: 0x002B5C),
        "KHC": UIColor(hex: 0xC10B16),
        "VH": UIColor(hex: 0xF8AC00),
        "OHIK": UIColor(hex: 0x006633),
    ]

    static func color(for code: String) -> UIColor? {
        map[code.uppercased()]
    }
}

private struct ShotChartBounds {
    // SHL API locations are in decimeters: rink length ~60m (0..600), width ~30m (about -150..150).
    // Event x-values are normalized to chart-space so 0 -> 39 and 600 -> 561.
    private let baseXMin: CGFloat = 0
    private let baseXMax: CGFloat = 600
    private let eventChartXMin: CGFloat = 39
    private let eventChartXMax: CGFloat = 561
    private let xPadding: CGFloat = 0
    private let yMin: CGFloat = -160
    private let yMax: CGFloat = 160
    private let invertY: Bool = true

    func shouldFlipX(event: GameEvent, homeTeam: String, awayTeam: String) -> Bool {
        guard let team = event.team,
              let location = event.location else {
            return false
        }
        let x = CGFloat(location.x)
        guard x >= baseXMin, x <= baseXMax else {
            return false
        }
        let isRightSide = x > ((baseXMin + baseXMax) / 2.0)
        if team == homeTeam {
            return isRightSide
        }
        if team == awayTeam {
            return !isRightSide
        }
        return false
    }

    func position(for location: EventLocation, in size: CGSize, flipX: Bool, normalizeEventX: Bool = true) -> CGPoint? {
        guard let normalized = normalizedPosition(for: location, flipX: flipX, normalizeEventX: normalizeEventX) else {
            return nil
        }
        return CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    func normalizedPosition(for location: EventLocation, flipX: Bool, normalizeEventX: Bool = true) -> CGPoint? {
        let rawX = CGFloat(location.x)
        let y = CGFloat(location.y)
        guard rawX >= baseXMin, rawX <= baseXMax, y >= yMin, y <= yMax else {
            return nil
        }
        let x = normalizeEventX ? remapEventXToChartX(rawX) : rawX
        let paddedMin = baseXMin - xPadding
        let paddedMax = baseXMax + xPadding
        let normalizedX = (x - paddedMin) / (paddedMax - paddedMin)
        let normalizedY = (y - yMin) / (yMax - yMin)
        let mappedX = flipX ? (1 - normalizedX) : normalizedX
        let mappedY = invertY ? (1 - normalizedY) : normalizedY
        return CGPoint(x: mappedX, y: mappedY)
    }

    private func remapEventXToChartX(_ x: CGFloat) -> CGFloat {
        let t = (x - baseXMin) / (baseXMax - baseXMin)
        return eventChartXMin + t * (eventChartXMax - eventChartXMin)
    }
}

private struct RinkBackdrop: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let rinkLengthM: CGFloat = 61
            let rinkWidthM: CGFloat = 30

            let x: (CGFloat) -> CGFloat = { meters in
                (meters / rinkLengthM) * size.width
            }
            let y: (CGFloat) -> CGFloat = { meters in
                (meters / rinkWidthM) * size.height
            }
            let w: (CGFloat) -> CGFloat = { meters in
                (meters / rinkLengthM) * size.width
            }
            let h: (CGFloat) -> CGFloat = { meters in
                (meters / rinkWidthM) * size.height
            }

            // IIHF-ish rink geometry in meters.
            let cornerRadius = min(w(8.5), h(8.5))
            let centerLineX: CGFloat = 30.5
            let blueLineFromBoard: CGFloat = 22.86
            let leftBlueLineX: CGFloat = blueLineFromBoard
            let rightBlueLineX: CGFloat = rinkLengthM - blueLineFromBoard
            
            let goalLineFromBoard: CGFloat = 4.0
            let leftGoalLineX: CGFloat = goalLineFromBoard
            let rightGoalLineX: CGFloat = rinkLengthM - goalLineFromBoard
            
            let centerCircleDiameter: CGFloat = 9.0
            
            let faceoffCircleDiameter: CGFloat = 9.0
            let topFaceoffY: CGFloat = 6.6
            let bottomFaceoffY: CGFloat = rinkWidthM - topFaceoffY
            let leftFaceoffX: CGFloat = 11.0
            let rightFaceoffX: CGFloat = rinkLengthM - leftFaceoffX
            
            let goalDepth: CGFloat = 3.66 / 2
            let goalWidthM: CGFloat = 3.66
            let goalRadius: CGFloat = 7.2
            
            let iceColor = colorScheme == .dark
                ? Color(UIColor(white: 0.9, alpha: 1.0))
                : Color(uiColor: .systemBackground)
            let redColor = Color(red: 0.96, green: 0.74, blue: 0.74)

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(iceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                    )

                // Middle line
                Rectangle()
                    .fill(redColor)
                    .frame(width: 2)
                    .position(x: x(centerLineX), y: y(rinkWidthM / 2))
                
                // Offside lines
                Rectangle()
                    .fill(Color.blue.opacity(0.35))
                    .frame(width: 2)
                    .position(x: x(leftBlueLineX), y: y(rinkWidthM / 2))
                Rectangle()
                    .fill(Color.blue.opacity(0.35))
                    .frame(width: 2)
                    .position(x: x(rightBlueLineX), y: y(rinkWidthM / 2))
                
                // Goal lines
                Rectangle()
                    .fill(redColor)
                    .frame(width: 2, height: h(27))
                    .position(x: x(leftGoalLineX), y: y(rinkWidthM / 2))
                
                Rectangle()
                    .fill(redColor)
                    .frame(width: 2, height: h(27))
                    .position(x: x(rightGoalLineX), y: y(rinkWidthM / 2))

                
                // Mid circle
                Circle()
                    .stroke(redColor, lineWidth: 2)
                    .frame(width: h(centerCircleDiameter), height: h(centerCircleDiameter))
                    .position(x: x(centerLineX), y: y(rinkWidthM / 2))

                // Offensive circles
                Circle()
                    .stroke(Color.blue.opacity(0.35), lineWidth: 2)
                    .frame(width: h(faceoffCircleDiameter), height: h(faceoffCircleDiameter))
                    .position(x: x(leftFaceoffX), y: y(topFaceoffY))
                Circle()
                    .stroke(Color.blue.opacity(0.35), lineWidth: 2)
                    .frame(width: h(faceoffCircleDiameter), height: h(faceoffCircleDiameter))
                    .position(x: x(leftFaceoffX), y: y(bottomFaceoffY))
                Circle()
                    .stroke(Color.blue.opacity(0.35), lineWidth: 2)
                    .frame(width: h(faceoffCircleDiameter), height: h(faceoffCircleDiameter))
                    .position(x: x(rightFaceoffX), y: y(topFaceoffY))
                Circle()
                    .stroke(Color.blue.opacity(0.35), lineWidth: 2)
                    .frame(width: h(faceoffCircleDiameter), height: h(faceoffCircleDiameter))
                    .position(x: x(rightFaceoffX), y: y(bottomFaceoffY))

                // Goals
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0,
                                                         bottomLeading: 0,
                                                         bottomTrailing: goalRadius,
                                                         topTrailing: goalRadius))
                    .stroke(redColor, lineWidth: 2)
                    .frame(width: w(goalDepth), height: h(goalWidthM))
                    .position(x: x(leftGoalLineX + goalDepth / 2), y: y(rinkWidthM / 2))
                
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: goalRadius,
                                                         bottomLeading: goalRadius,
                                                         bottomTrailing: 0,
                                                         topTrailing: 0))
                    .stroke(redColor, lineWidth: 2)
                    .frame(width: w(goalDepth), height: h(goalWidthM))
                    .position(x: x(rightGoalLineX - goalDepth / 2), y: y(rinkWidthM / 2))
            }
        }
    }
}

#Preview("Shot Chart") {
    let home = "LHF"
    let away = "FBK"
    var events: [GameEvent] = [
        GameEvent(game_uuid: "g1", event_id: "s1", status: "Period1", gametime: "03:12", type: "Shot",
                  team: home, reason: nil, player: nil, penalty: nil, assists: nil,
                  home_team_result: nil, away_team_result: nil, team_advantage: nil, is_empty_net_goal: nil, is_penalty_shot: nil,
                  location: EventLocation(x: 120, y: -40)),
        GameEvent(game_uuid: "g1", event_id: "s2", status: "Period1", gametime: "05:48", type: "Shot",
                  team: home, reason: nil, player: nil, penalty: nil, assists: nil,
                  home_team_result: nil, away_team_result: nil, team_advantage: nil, is_empty_net_goal: nil, is_penalty_shot: nil,
                  location: EventLocation(x: 420, y: 60)),
        GameEvent(game_uuid: "g1", event_id: "s3", status: "Period2", gametime: "10:21", type: "Shot",
                  team: away, reason: nil, player: nil, penalty: nil, assists: nil,
                  home_team_result: nil, away_team_result: nil, team_advantage: nil, is_empty_net_goal: nil, is_penalty_shot: nil,
                  location: EventLocation(x: 180, y: 10)),
        GameEvent(game_uuid: "g1", event_id: "s4", status: "Period2", gametime: "12:44", type: "Shot",
                  team: away, reason: nil, player: nil, penalty: nil, assists: nil,
                  home_team_result: nil, away_team_result: nil, team_advantage: nil, is_empty_net_goal: nil, is_penalty_shot: nil,
                  location: EventLocation(x: 520, y: -70)),
        GameEvent(game_uuid: "g1", event_id: "g1", status: "Period2", gametime: "14:02", type: "Goal",
                  team: home, reason: nil, player: nil, penalty: nil, assists: nil,
                  home_team_result: 1, away_team_result: 0, team_advantage: "EQ", is_empty_net_goal: nil, is_penalty_shot: nil,
                  location: EventLocation(x: 505, y: 25)),
        GameEvent(game_uuid: "g1", event_id: "g2", status: "Period2", gametime: "14:02", type: "Goal",
                  team: away, reason: nil, player: nil, penalty: nil, assists: nil,
                  home_team_result: 1, away_team_result: 0, team_advantage: "EQ", is_empty_net_goal: nil, is_penalty_shot: nil,
                  location: EventLocation(x: 140, y: 15))
    ]

    events.reverse()
    return ShotChartView(events: events, homeTeam: home, awayTeam: away)
        .environmentObject(getTeamsData())
        .padding()
}

private struct TeamColorsPreviewGrid: View {
    private let codes = TeamColors.map.keys.sorted()
    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 128), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(codes, id: \.self) { code in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color(uiColor: TeamColors.color(for: code) ?? .systemGray3))
                            .frame(height: 34)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(uiColor: .separator), lineWidth: 1)
                            )

                        Text(code)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview("Team Colors") {
    TeamColorsPreviewGrid()
}
