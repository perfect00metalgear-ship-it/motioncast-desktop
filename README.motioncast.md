# MotionCast for Windows

A fork of [jellyfin/jellyfin-desktop](https://github.com/jellyfin/jellyfin-desktop)
(**GPL-2.0**, upstream commit `4e1010b`) rebranded as the MotionCast desktop client.

Upstream's licence, copyright and history are retained in full. This fork is
published to satisfy GPL-2.0 §3 — members receive modified binaries, so the
corresponding source lives here.

## Why this fork exists

MotionCast's entire member UI is a bridge injected into the server's own
`jellyfin-web` `index.html`. Stock desktop builds render a *bundled* web client,
so none of that branding loads. This fork points the app at the MotionCast server
instead, so the real web surface — and the whole bridge — is the app.

Playback is handled by **mpv**, not the browser engine, which removes the codec
gaps that force the server to transcode for Chrome: HEVC (incl. 10-bit),
E-AC-3/AC-3 audio, MPEG-2, and subtitle burn-in.

## Changes vs upstream

| Area | Change |
|---|---|
| `resources/settings/settings_description.json` | `path.startupurl_desktop` pinned to `https://motioncast.tv/web/index.html`, so the app loads our web client and no member types a server address. |
| `CMakeModules/NameConfiguration.cmake` | Binary/data dir `motioncast-desktop`; product name `MotionCast`. |
| `src/ui/webview.qml` | Window title, tray tooltip, and web storage profile. |
| `resources/images/` | App icon and splash. |
| `src/player/OpenGLDetect.cpp` | **Windows VRR flicker fix** — see below. |

The diff is deliberately tiny (~30 lines + two images) so rebasing onto upstream
stays cheap.

## The Windows flicker fix

Upstream leaves `detectOpenGLEarly()` **empty on Windows**, so the GL surface
inherits a driver-default swap interval. Combined with the unconditional
`QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL)` in `src/main.cpp`
and Qt's threaded render loop, present timing goes erratic on variable-refresh
(G-Sync / FreeSync) displays and the UI flickers. Reported upstream and unfixed:
[#1202](https://github.com/jellyfin/jellyfin-desktop/issues/1202) (open since
2026-03) and [#1112](https://github.com/jellyfin/jellyfin-desktop/issues/1112).

We pin `setSwapInterval(1)`, mirroring the existing macOS branch.

> **This cannot be fixed by switching to the D3D11 RHI backend.** mpvqt's
> `MpvAbstractItem` derives from `QQuickFramebufferObject` and its renderer uses
> `QOpenGLFramebufferObject` — both OpenGL-only. Dropping OpenGL kills video
> output entirely.

## Building

Windows builds require **MSVC 2022 + Qt 6.9.3** (Qt ships WebEngine for MSVC
only; MinGW is unsupported). Built by `.github/workflows/build-windows.yml` on a
GitHub-hosted Windows runner. See upstream `dev/` for local build instructions.
