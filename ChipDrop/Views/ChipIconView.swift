import SwiftUI

/// Custom poker chip icon — updated for Midnight Emerald palette
struct ChipIconView: View {
    var size: CGFloat = 60
    var style: ChipStyle = .dual

    enum ChipStyle { case dual, single }

    var body: some View {
        ZStack {
            switch style {
            case .dual:  dualChipView
            case .single: singleChipView
            }
        }
        .frame(width: size, height: size)
    }

    private var dualChipView: some View {
        ZStack {
            singleChip(mainColor: Color(red: 0.14, green: 0.16, blue: 0.22),
                        accentColor: Color.white.opacity(0.8))
                .offset(x: -size * 0.08, y: -size * 0.05)
                .scaleEffect(0.85)

            singleChip(mainColor: Color(red: 0.20, green: 0.72, blue: 0.45),
                        accentColor: Color.white)
                .offset(x: size * 0.08, y: size * 0.05)
                .scaleEffect(0.85)
        }
    }

    private var singleChipView: some View {
        singleChip(mainColor: Color(red: 0.20, green: 0.72, blue: 0.45),
                    accentColor: Color.white)
    }

    private func singleChip(mainColor: Color, accentColor: Color) -> some View {
        ZStack {
            Circle()
                .fill(mainColor)
                .frame(width: size * 0.8, height: size * 0.8)

            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.9))
                    .frame(width: size * 0.12, height: size * 0.06)
                    .offset(x: size * 0.33)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            Circle()
                .fill(mainColor.opacity(0.9))
                .frame(width: size * 0.5, height: size * 0.5)

            Circle()
                .stroke(accentColor.opacity(0.6), lineWidth: 1)
                .frame(width: size * 0.45, height: size * 0.45)

            clubSymbol(color: accentColor)
                .scaleEffect(0.15 * (size / 60))
        }
    }

    private func clubSymbol(color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 20, height: 20).offset(y: -10)
            Circle().fill(color).frame(width: 20, height: 20).offset(x: -10, y: 5)
            Circle().fill(color).frame(width: 20, height: 20).offset(x: 10, y: 5)
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 6, height: 18).offset(y: 18)
        }
    }
}

/// Bingo ball icon
struct BingoBallsView: View {
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            ballView(number: "30", color: Color(red: 0.20, green: 0.72, blue: 0.45))
                .offset(x: -size * 0.15, y: size * 0.12).scaleEffect(0.7)
            ballView(number: "17", color: Color(red: 0.20, green: 0.72, blue: 0.45))
                .offset(x: size * 0.15, y: size * 0.12).scaleEffect(0.7)
            ballView(number: "5", color: Color(red: 0.20, green: 0.70, blue: 1.0))
                .offset(x: -size * 0.1, y: -size * 0.1).scaleEffect(0.7)
            ballView(number: "4", color: Color(red: 1.0, green: 0.78, blue: 0.20))
                .offset(x: size * 0.1, y: -size * 0.1).scaleEffect(0.7)
        }
        .frame(width: size, height: size)
    }

    private func ballView(number: String, color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: size * 0.4, height: size * 0.4)
            Circle().fill(Color.white).frame(width: size * 0.22, height: size * 0.22)
            Text(number)
                .font(.system(size: size * 0.12, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        ChipIconView(size: 80, style: .dual)
        ChipIconView(size: 60, style: .single)
        BingoBallsView(size: 80)
    }
    .padding()
    .background(Theme.bg)
}
