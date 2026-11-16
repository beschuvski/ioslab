import SwiftUI

struct ContentView: View {
    @State private var model = LabModel()

    private let accent = Color(red: 0.0, green: 0.44, blue: 0.89)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.98), Color(white: 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header
                summaryCard
                checkList
                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("iOS Lab")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("SwiftUI · XcodeGen · GitHub Actions")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.summary.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(model.passed)")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
                Text("/ \(model.total)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressRing(progress: Double(model.passed) / Double(max(model.total, 1)), color: accent)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var checkList: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.checks.enumerated()), id: \.element.id) { index, check in
                HStack(spacing: 14) {
                    Circle()
                        .fill(check.status == .pass ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(check.title)
                            .font(.system(size: 15, weight: .semibold))
                        Text(check.detail)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(check.status.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(check.status == .pass ? Color.green : Color.orange)
                }
                .padding(.vertical, 14)
                if index < model.checks.count - 1 {
                    Divider().padding(.leading, 22)
                }
            }
        }
        .padding(.horizontal, 18)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { model.runNextCheck() }
            } label: {
                Text("Run next check")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Text("macOS 26 runner · Xcode 27 · Simulator")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }
}

private struct ProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 5)
            Circle()
                .trim(from: 0, to: max(0.02, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.snappy, value: progress)
    }
}
