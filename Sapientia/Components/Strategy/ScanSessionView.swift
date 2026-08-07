import CodeScanner
import SwiftUI

/// Screen 04 — the dark accent-900 scan stage. Presents the pulsing ring
/// and fires the system NFC sheet on appear; if the profile prays before
/// unblocking, the prayer interstitial stands in front. An optional QR
/// fallback lets any paired QR code close the session.
struct ScanSessionView: View {
  let profileName: String
  let caption: String?
  let needsPrayer: Bool
  let onReady: () -> Void
  var qrFallbackHandler: ((String) -> Void)? = nil

  @Environment(\.dismiss) private var dismiss
  @State private var prayed = false
  @State private var showingQRScanner = false
  @State private var hasFiredScan = false

  var body: some View {
    Group {
      if needsPrayer && !prayed {
        PrayerInterstitialView(
          onAmen: { prayed = true },
          onCancel: { dismiss() }
        )
      } else {
        stage
      }
    }
  }

  private var stage: some View {
    VStack(spacing: 0) {
      HStack {
        Button("Cancel") { dismiss() }
          .font(.sapientiaBody(15))
          .foregroundColor(SapientiaTheme.onDark(0.7))
          .buttonStyle(.plain)
        Spacer()
        Text(profileName)
          .sapientiaKicker(color: SapientiaTheme.onDark(0.9))
        Spacer()
        Button("Cancel") {}
          .font(.sapientiaBody(15))
          .opacity(0)
          .disabled(true)
      }

      Spacer()

      PulsingRing()
        .frame(width: 170, height: 170)

      VStack(spacing: SapientiaTheme.space2) {
        Text("Hold near the tag")
          .font(.sapientiaHeading(32))
          .kerning(1.2)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.background)
        if let caption {
          Text(caption)
            .font(.sapientiaBody(15))
            .foregroundColor(SapientiaTheme.onDark(0.65))
        }
      }
      .padding(.top, SapientiaTheme.space8)

      Button {
        onReady()
      } label: {
        Text("Scan again")
          .font(.sapientiaBody(14))
          .foregroundColor(SapientiaTheme.onDark(0.6))
      }
      .buttonStyle(.plain)
      .padding(.top, SapientiaTheme.space6)

      Spacer()

      if qrFallbackHandler != nil {
        VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
          Rectangle()
            .fill(SapientiaTheme.onDark(0.16))
            .frame(height: 1)
          Text("No tag to hand? Any paired QR code closes the session just the same.")
            .font(.sapientiaBody(14))
            .foregroundColor(SapientiaTheme.onDark(0.6))
            .padding(.top, SapientiaTheme.space3)
          Button("Scan a QR code") {
            showingQRScanner = true
          }
          .buttonStyle(
            BlueprintSecondaryButtonStyle(
              fontSize: 19,
              foreground: SapientiaTheme.background,
              borderColor: SapientiaTheme.onDark(0.45))
          )
          .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.horizontal, SapientiaTheme.space6)
    .padding(.vertical, SapientiaTheme.space6)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SapientiaTheme.accent900.ignoresSafeArea())
    .onAppear {
      guard !hasFiredScan else { return }
      hasFiredScan = true
      onReady()
    }
    .sheet(isPresented: $showingQRScanner) {
      LabeledCodeScannerView(
        heading: "Scan to stop",
        subtitle: "Point your camera at a paired QR code to end the session."
      ) { result in
        showingQRScanner = false
        if case .success(let scan) = result {
          qrFallbackHandler?(scan.string)
        }
      }
    }
  }
}

/// Three staggered expanding rings around a small square, matching the
/// mockup's `ring` keyframes.
private struct PulsingRing: View {
  var body: some View {
    TimelineView(.animation) { timeline in
      let t = timeline.date.timeIntervalSinceReferenceDate
      ZStack {
        ForEach(0..<3, id: \.self) { index in
          let phase = ((t / 2.6) + Double(index) / 3).truncatingRemainder(dividingBy: 1)
          Circle()
            .strokeBorder(
              SapientiaTheme.accent400.opacity(0.65 * (0.9 - phase * 0.9)),
              lineWidth: 1
            )
            .scaleEffect(0.72 + phase * 0.63)
        }
        Rectangle()
          .strokeBorder(SapientiaTheme.onDark(0.5), lineWidth: 1)
          .frame(width: 82, height: 82)
      }
    }
  }
}

#Preview {
  ScanSessionView(
    profileName: "Deep Work",
    caption: "Oratory shelf · paired 4 March",
    needsPrayer: false,
    onReady: {},
    qrFallbackHandler: { _ in }
  )
}
