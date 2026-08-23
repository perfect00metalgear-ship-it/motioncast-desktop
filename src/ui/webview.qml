import QtQuick
import Konvergo 1.0
import QtWebEngine
import QtWebChannel
import QtQuick.Window
import QtQuick.Controls
import Qt.labs.platform as Labs

Window
{
  id: mainWindow
  title: "MotionCast"
  objectName: "mainWindow"
  width: 1280
  height: 720
  minimumWidth: 213
  minimumHeight: 120
  visible: true
  // MotionCast floor, not black: this is what the member stares at while the
  // web client loads over the network, so it should look like the app.
  color: "#080C14"

  // Properties previously from KonvergoWindow
  property bool webDesktopMode: true
  property bool showDebugLayer: false
  property string debugInfo: ""
  property string videoInfo: ""
  property string webUrl: ""

  property bool showSystemTrayIcon: webDesktopMode && components.system.isWindows &&
                                    components.settings.windowsTrayIcon

  signal reloadWebClient()

  Component.onCompleted: {
    if (components && components.settings) {
      webUrl = components.settings.getWebClientUrl(webDesktopMode)
    }
  }

  onClosing: function(close) {
    if (showSystemTrayIcon) {
      // Minimize to tray on close.
      close.accepted = false
      mainWindow.hide()
    }
  }

  function toggleFullscreen() {
    visibility = (visibility === Window.FullScreen) ? Window.Windowed : Window.FullScreen
  }

  function toggleDebug() {
    showDebugLayer = !showDebugLayer
  }

  function setFullScreen(enable) {
    visibility = enable ? Window.FullScreen : Window.Windowed
  }

  function minimizeWindow() {
    if (visibility !== Window.FullScreen)
      visibility = Window.Minimized
  }

  function restoreWindow() {
    mainWindow.show()
    mainWindow.raise()
    mainWindow.requestActivate()
  }

  function runWebAction(action)
  {
    if (mainWindow.webDesktopMode)
      web.triggerWebAction(action)
  }

  Action
  {
    enabled: mainWindow.webDesktopMode
    shortcut:
    {
      if (components.system.isMacos) return "Ctrl+Meta+F"
      return "F11"
    }
    onTriggered: mainWindow.toggleFullscreen()
  }

  Action
  {
    shortcut: "Alt+Return"
    enabled:
    {
      if (mainWindow.webDesktopMode && components.system.isWindows)
        return true;
      return false;
    }
    onTriggered: mainWindow.toggleFullscreen()
  }

  Action
  {
    enabled: mainWindow.webDesktopMode
    shortcut: StandardKey.Close
    onTriggered: mainWindow.close()
  }

  Action
  {
    enabled: mainWindow.webDesktopMode
    shortcut: {
      if (components.system.isMacos) return "Ctrl+M";
      return "Meta+Down";
    }
    onTriggered: mainWindow.minimizeWindow()
  }

  Action
  {
    enabled: mainWindow.webDesktopMode
    shortcut: components.system.isWindows ? "Ctrl+Q" : StandardKey.Quit
    onTriggered: Qt.quit()
  }

  Action
  {
    shortcut: "Ctrl+Shift+D"
    enabled: mainWindow.webDesktopMode
    onTriggered: mainWindow.toggleDebug()
  }

  Action
  {
    shortcut: StandardKey.Copy
    onTriggered: runWebAction(WebEngineView.Copy)
    id: action_copy
  }

  Action
  {
    shortcut: StandardKey.Cut
    onTriggered: runWebAction(WebEngineView.Cut)
    id: action_cut
  }

  Action
  {
    shortcut: StandardKey.Paste
    onTriggered: runWebAction(WebEngineView.Paste)
    id: action_paste
  }

  Action
  {
    shortcut: StandardKey.SelectAll
    onTriggered: runWebAction(WebEngineView.SelectAll)
    id: action_selectall
  }

  Action
  {
    shortcut: StandardKey.Undo
    onTriggered: runWebAction(WebEngineView.Undo)
    id: action_undo
  }

  Action
  {
    shortcut: StandardKey.Redo
    onTriggered: runWebAction(WebEngineView.Redo)
    id: action_redo
  }

  Action
  {
    shortcut: StandardKey.Back
    onTriggered: runWebAction(WebEngineView.Back)
    id: action_back
  }

  Action
  {
    shortcut: StandardKey.Forward
    onTriggered: runWebAction(WebEngineView.Forward)
    id: action_forward
  }

  Action
  {
    enabled: mainWindow.webDesktopMode
    shortcut: "Ctrl+0"
    onTriggered: web.zoomFactor = 1.0
  }

  Timer
  {
    id: splashFade
    interval: 300
    onTriggered: bootSplash.visible = false
  }

  WebChannel
  {
    id: webChannelObject
  }

  Binding
  {
    target: web
    property: "zoomFactor"
    value: 1.0
    when: !components.settings.allowBrowserZoom()
  }

  MpvVideoItem
  {
    id: video
    objectName: "video"
    enabled: true

    width: mainWindow.contentItem.width
    height: mainWindow.contentItem.height
    anchors.left: mainWindow.contentItem.left
    anchors.right: mainWindow.contentItem.right
    anchors.top: mainWindow.contentItem.top

    Component.onCompleted: {
      console.log("MpvVideoItem size:", width, "x", height, "visible:", visible)
    }
    onWidthChanged: console.log("MpvVideoItem width changed:", width)
    onHeightChanged: console.log("MpvVideoItem height changed:", height)
  }

  WebEngineView
  {
    id: web
    objectName: "web"
    width: mainWindow.width
    height: mainWindow.height
    z: 100
    backgroundColor: "transparent"

    // Upstream sets layer.enabled unconditionally to fix a black window on
    // un-minimize / resume from suspend -- but its own comment scopes that to
    // "linux/{x11/wayland}, possibly others" (commit fd31562).
    //
    // On Windows the extra offscreen-FBO composite of a TRANSPARENT WebEngineView
    // is a plausible cause of two reported symptoms: UI flicker on variable-refresh
    // displays, and mpv video not showing through at all (the layer composites
    // opaque, so the video plane behind the view is hidden). See upstream #1202.
    //
    // Keep upstream behaviour everywhere except Windows, where it defaults off and
    // stays toggleable via main.webLayer in case this diagnosis is wrong.
    layer.enabled: components.system.isWindows
                     ? (components.settings.value("main", "webLayer") !== false)
                     : true

    webChannel: webChannelObject
    settings.errorPageEnabled: false
    settings.localContentCanAccessRemoteUrls: true
    settings.localContentCanAccessFileUrls: true
    settings.allowRunningInsecureContent: true
    settings.playbackRequiresUserGesture: false
    profile.httpUserAgent: components.system.getUserAgent()
    profile.httpCacheType: WebEngineProfile.DiskHttpCache
    url: mainWindow.webUrl
    focus: true
    property string currentHoveredUrl: ""
    onLinkHovered: function(hoveredUrl)
    {
      web.currentHoveredUrl = hoveredUrl;
    }
    profile.persistentCookiesPolicy: WebEngineProfile.AllowPersistentCookies
    profile.offTheRecord: false
    profile.storageName: "MotionCastStorage"

    Component.onCompleted:
    {
      console.log("WebEngineView size:", width, "x", height, "backgroundColor:", backgroundColor)
      forceActiveFocus()
      mainWindow.reloadWebClient.connect(reload)

      // Handle CSP workaround from C++
      components.system.pageContentReady.connect(function(html, finalUrl, hadCSP) {
        if (hadCSP) {
          console.log("CSP workaround: navigating to", finalUrl);
          web.url = finalUrl;
        }
      })

      var nativeshell =
      {
        sourceCode: components.system.getNativeShellScript(),
        injectionPoint: WebEngineScript.DocumentCreation,
        worldId: WebEngineScript.MainWorld
      }

      web.userScripts.collection = [ nativeshell ];
    }

    onLoadingChanged: function(loadingInfo)
    {
      // we use a timer here to switch to the webview since
      // it take a few moments for the webview to render
      // after it has loaded.
      //
      if (loadingInfo.status == WebEngineView.LoadStartedStatus)
      {
        console.log("WebEngineLoadRequest starting: " + loadingInfo.url);
      }
      else if (loadingInfo.status == WebEngineView.LoadSucceededStatus)
      {
        console.log("WebEngineLoadRequest success: " + loadingInfo.url);
        bootSplash.opacity = 0.0
        splashFade.start()
      }
      else if (loadingInfo.status == WebEngineView.LoadFailedStatus)
      {
        console.log("WebEngineLoadRequest failure: " + loadingInfo.url + " error code: " + loadingInfo.errorCode);
        bootSplash.visible = false
        errorLabel.visible = true
        errorLabel.text = "Error loading client, this is bad and should not happen<br>" +
                          "You can try to <a href='reload'>reload</a> or head to our <a href='http://jellyfin.org'>support page</a><br><br>Actual Error: <pre>" +
                          loadingInfo.errorString + " [" + loadingInfo.errorCode + "]</pre><br><br>" +
                          "Provide the <a target='_blank' href='file://"+ components.system.logFilePath + "'>logfile</a> as well."
      }
    }

    onNewWindowRequested:
    {
      if (request.userInitiated)
      {
        console.log("Opening external URL: " + web.currentHoveredUrl)
        components.system.openExternalUrl(web.currentHoveredUrl)
      }
    }

    onFullScreenRequested:
    {
      console.log("Request fullscreen: " + request.toggleOn)
      mainWindow.setFullScreen(request.toggleOn)
      request.accept()
    }

    onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID)
    {
      components.system.jsLog(level, sourceID + ":" + lineNumber + " " + message);
    }

    onCertificateError: function(error)
    {
      console.log(error.url + " :" + error.description + error.error)
      if (components.settings.ignoreSSLErrors()) {
        error.acceptCertificate()
      }
    }
  }

  // ── Boot splash ──────────────────────────────────────────────────────────
  // The web client is fetched over the network at startup, so without this the
  // member sees an empty window for as long as that takes. Sits ABOVE the web
  // view (z 200 > 100) and is removed on the first successful load.
  Rectangle
  {
    id: bootSplash
    z: 200
    anchors.fill: parent
    color: "#080C14"
    visible: true

    Image
    {
      id: bootMark
      source: "qrc:/images/icon.png"
      width: 108
      height: 108
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -28
      smooth: true
      fillMode: Image.PreserveAspectFit
    }

    Text
    {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: bootMark.bottom
      anchors.topMargin: 26
      text: "MotionCast"
      color: "#E0EAF5"
      font.pixelSize: 19
      font.letterSpacing: 3
      font.bold: true
    }

    Text
    {
      id: bootHint
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: bootMark.bottom
      anchors.topMargin: 56
      text: "Connecting"
      color: "#7C8BA1"
      font.pixelSize: 13
      opacity: 0.0
      SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: bootSplash.visible
        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
      }
    }

    // Only complain if it is genuinely taking too long, so a normal 2-3s load
    // never shows a scary message.
    Timer
    {
      interval: 12000
      running: bootSplash.visible
      onTriggered: bootHint.text = "Still connecting. Check your internet connection."
    }

    Behavior on opacity { NumberAnimation { duration: 260 } }
  }

  Text
  {
    id: errorLabel
    z: 5
    anchors.centerIn: parent
    color: "#999999"
    linkColor: "#a85dc3"
    text: "Generic error"
    font.pixelSize: 32
    font.bold: true
    visible: false
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.StyledText
    onLinkActivated:
    {
      if (url == "reload")
      {
        errorLabel.visible = false
        web.reload()
      }
      else
      {
        Qt.openUrlExternally(url)
      }
    }
  }


  Rectangle
  {
    id: debug
    color: "black"
    z: 10
    anchors.centerIn: parent
    width: parent.width
    height: parent.height
    opacity: 0.7
    visible: mainWindow.showDebugLayer

    Text
    {
      id: debugLabel
      width: (parent.width - 50) / 2
      height: parent.height - 25
      anchors.left: parent.left
      anchors.leftMargin: 64
      anchors.top: parent.top
      anchors.topMargin: 54
      anchors.bottomMargin: 54
      color: "white"
      font.pixelSize: Math.round(height / 65)
      wrapMode: Text.WrapAnywhere

      function windowDebug()
      {
        var dbg = mainWindow.debugInfo + "Window and web\n";
        dbg += "  Window size: " + parent.width + "x" + parent.height + " - " + web.width + "x" + web.height + "\n";
        dbg += "  DevicePixel ratio: " + Screen.devicePixelRatio + "\n";

        return dbg;
      }

      text: windowDebug()
    }

    Text
    {
      id: videoLabel
      width: (parent.width - 50) / 2
      height: parent.height - 25
      anchors.right: parent.right
      anchors.left: debugLabel.right
      anchors.rightMargin: 64
      anchors.top: parent.top
      anchors.topMargin: 54
      anchors.bottomMargin: 54
      color: "white"
      font.pixelSize: Math.round(height / 65)
      wrapMode: Text.WrapAnywhere

      text: mainWindow.videoInfo
    }
  }

  property QtObject webChannel: web.webChannel

  Labs.SystemTrayIcon {
    visible: showSystemTrayIcon
    icon.source: "qrc:/images/icon.png"
    tooltip: "MotionCast"

    onActivated: function(reason) {
      if (reason === Labs.SystemTrayIcon.Context) {
        // Right click: open context menu
        contextMenu.open()
        components.window.setCursorVisibility(true)
      } else {
        // All other clicks: restore window
        restoreWindow()
      }
    }

    menu: Labs.Menu {
      id: contextMenu
      Labs.MenuItem {
        text: qsTr("Restore")
        onTriggered: restoreWindow()
      }
      Labs.MenuSeparator {}
      Labs.MenuItem {
        text: qsTr("Quit")
        onTriggered: Qt.quit()
      }
    }
  }
}
