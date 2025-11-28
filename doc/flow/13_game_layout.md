# 13. Game Layout & Frame System

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **game.html.erb Layout** | ✅ Implemented | `app/views/layouts/game.html.erb` — Neverlands-style dark CSS Grid layout |
| **game_layout_controller.js** | ✅ Implemented | `app/javascript/controllers/game_layout_controller.js` — Resize, tabs, player menu, shortcuts |
| **_vitals_bar.html.erb** | ✅ Implemented | `app/views/shared/_vitals_bar.html.erb` — Status bar vitals (dark theme) |
| **_online_players_compact.html.erb** | ✅ Implemented | `app/views/shared/_online_players_compact.html.erb` — Compact sidebar list |
| **RealtimeChatChannel** | ✅ Implemented | `app/channels/realtime_chat_channel.rb` — Global chat |
| **PresenceChannel** | ✅ Implemented | `app/channels/presence_channel.rb` — Online tracking |
| **CSS Grid Layout** | ✅ Implemented | `app/assets/stylesheets/application.css` — `.nl-game-layout` dark fantasy theme |
| **Resize Handle** | ✅ Implemented | Drag to resize bottom panel with min/max constraints |
| **Tabbed Log System** | ✅ Implemented | Chat, Battle Log, Events, System tabs |
| **Chat Modes** | ✅ Implemented | All/Private/None filtering via CSS classes |
| **Keyboard Shortcuts** | ✅ Implemented | Alt+H (toggle), Alt+C (chat mode), Alt+1-4 (tabs), Alt+Enter (focus) |
| **Player Context Menu** | ✅ Implemented | Right-click for whisper, profile, invite, ignore |
| **localStorage Preferences** | ✅ Implemented | Panel height, active tab, chat mode persisted |

---

## Use Cases

### UC-1: Navigate Game Interface
**Actor:** Logged-in player
**Flow:**
1. Player lands on any game page with `game.html.erb` layout
2. Header shows: logo, character name/level, HP/MP bars, nav buttons, exit
3. Main content area displays current view (world, arena, quests, etc.)
4. Bottom panel shows chat messages + online players list
5. Resize handle allows adjusting bottom panel height

### UC-2: Chat in Real-Time
**Actor:** Player wanting to communicate
**Flow:**
1. Player types message in chat input, presses Enter
2. Form submits via Turbo, `ChatMessagesController#create` processes
3. `RealtimeChatChannel` broadcasts to all subscribers
4. All online players see message appear without page reload
5. Stimulus controller auto-scrolls to bottom

### UC-3: Resize Chat Panel
**Actor:** Player preferring larger/smaller chat
**Flow:**
1. Player drags resize handle (the `═══` bar)
2. `game_layout_controller.js` calculates new height
3. Height snaps to 60px increments (like Neverlands)
4. CSS custom property `--bottom-panel-height` updates
5. Preference saved to localStorage for persistence

### UC-4: Toggle Chat Mode
**Actor:** Player wanting to filter messages
**Flow:**
1. Player clicks chat mode button (💬)
2. Cycles: All → Private Only → Hidden → All
3. CSS class filters visible messages
4. "Private Only" shows only whispers
5. "Hidden" shows placeholder text

---

## Key Behavior

### Panel Layout (Neverlands Style)
```
┌─────────────────────────────────────────┐
│  STATUS BAR (32px) - minimal dark theme │
│  [Name][Lvl] | HP/MP bars | 📜🎒📋🗺️⚔️ | ✕ │
├─────────────────────────────────────────┤
│                                         │
│  MAIN CONTENT (~90% of screen)          │
│  (Map / Profile / Combat / Quest, etc.) │
│                                         │
├─────────────────────────────────────────┤
│  RESIZE HANDLE (6px) - drag to resize   │
├─────────────────────────────────────────┤
│  BOTTOM PANEL (~10%, 180px default)     │
│  ┌─────────────────────────────┬───────┐│
│  │ TABS: 💬Chat ⚔️Battle 📢Events ⚙️Sys│ONLINE││
│  ├─────────────────────────────┤PLAYERS││
│  │ Messages / Logs             │  LIST ││
│  ├─────────────────────────────┤(120px)││
│  │ [Chat Input ▸]              │       ││
│  └─────────────────────────────┴───────┘│
└─────────────────────────────────────────┘
```

### Resize Constraints
- Minimum height: 80px
- Maximum height: 400px
- Default: 180px

### Tabbed Log System
| Tab | Icon | Content |
|-----|------|---------|
| Chat | 💬 | Real-time chat messages |
| Battle | ⚔️ | Combat log entries |
| Events | 📢 | Game events, achievements |
| System | ⚙️ | System messages, errors |

### Chat Modes
| Mode | Behavior |
|------|----------|
| All | Show all messages |
| Private | Show only whispers |
| None | Hide chat messages |

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Alt+H | Toggle bottom panel |
| Alt+C | Cycle chat mode |
| Alt+1-4 | Switch tabs |
| Alt+Enter | Focus chat input |
| Escape | Close menus |

---

## Overview
This document describes the main game layout, inspired by Neverlands' frame-based design but implemented with modern CSS Grid and Turbo Frames. The layout provides:
- Top area for main game content (map, city, profile, combat)
- Resizable bottom panel for chat and online players
- Persistent header with character vitals
- Real-time updates via ActionCable instead of iframe polling

## Neverlands Reference Analysis

The original Neverlands uses a frameset:
```html
<frameset rows="*,8,1,240,1,30,0" id="mainframes">
  <frame src="./main.php" name="main_top">         <!-- Game content -->
  <frame src="./resize.html" name="resize">        <!-- Resize handle -->
  <frame src="./temp.html" name="temp_f">          <!-- Spacer -->
  <frameset cols="*,300">
    <frame src="./msg.php" name="chmain">          <!-- Chat messages -->
    <frame src="./ch.php?lo=1" name="ch_list">     <!-- Online players -->
  </frameset>
  <frame src="./tempw.html" name="temp_s">         <!-- Spacer -->
  <frame src="./but.php" name="ch_buttons">        <!-- Chat input -->
  <frame src="./refr.html" name="ch_refr">         <!-- Hidden refresh -->
</frameset>
```

Key features:
- `fr_size = 240` — Default chat panel height (adjustable ±60px)
- `ChatDelay = 12` — Chat refresh interval (10s/30s/60s options)
- `OnlineDelay = 60` — Online list refresh interval
- `ChatClearSize = 12228` — Max chat content before cleanup
- `ChatFyo` modes: 0=all, 1=private only, 2=none

## Modern Implementation

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  HEADER: Logo | Character Name [Lvl] | HP/MP Bars | Nav | Exit │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                      MAIN CONTENT AREA                          │
│           (Map / City / Profile / Combat / Quests)              │
│                                                                 │
│                     [Turbo Frame: main_content]                 │
│                                                                 │
├───────────────────────────── ═══ ───────────────────────────────┤  ← Resize Handle
│                         BOTTOM PANEL                            │
│  ┌──────────────────────────────┬───────────────────────────┐  │
│  │       CHAT MESSAGES          │    ONLINE PLAYERS         │  │
│  │   [Turbo Frame: chat]        │  [Turbo Frame: online]    │  │
│  │                              │                           │  │
│  └──────────────────────────────┴───────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  [Chat Input] [Send] [⚙ Settings] [🔔 Mode] [⏱ Speed]   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### HTML Structure

```erb
<%# app/views/layouts/game.html.erb %>
<!DOCTYPE html>
<html lang="en">
<head>
  <title><%= content_for(:title) || "Elselands" %></title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application", data: { turbo_track: "reload" } %>
  <%= javascript_importmap_tags %>
</head>
<body class="game-layout" data-controller="game-layout">

  <%# === GAME HEADER === %>
  <header class="game-header" data-game-layout-target="header">
    <div class="header-left">
      <%= link_to root_path, class: "game-logo" do %>
        <%= image_tag "elselands-logo.png", alt: "Elselands", height: 32 %>
      <% end %>

      <div class="header-character">
        <span class="char-name"><%= current_character.name %></span>
        <span class="char-level">[<%= current_character.level %>]</span>
      </div>

      <%= render "shared/vitals_bar", character: current_character %>
    </div>

    <nav class="header-nav">
      <%= link_to "Character", character_path, class: "header-btn" %>
      <%= link_to "Inventory", inventory_path, class: "header-btn" %>
      <%= link_to "Quests", quests_path, class: "header-btn" %>
      <%= link_to "Map", world_path, class: "header-btn" %>
    </nav>

    <div class="header-right">
      <%= link_to "Exit", destroy_user_session_path,
          method: :delete,
          class: "header-exit",
          data: { turbo_confirm: "Are you sure you want to leave the game?" } %>
    </div>
  </header>

  <%# === MAIN CONTENT AREA === %>
  <main class="game-main" data-game-layout-target="main">
    <%= turbo_frame_tag "main_content" do %>
      <%= yield %>
    <% end %>
  </main>

  <%# === RESIZE HANDLE === %>
  <div class="resize-handle"
       data-game-layout-target="resizeHandle"
       data-action="mousedown->game-layout#startResize">
    <div class="resize-grip">═══</div>
  </div>

  <%# === BOTTOM PANEL (Chat + Online) === %>
  <footer class="game-bottom" data-game-layout-target="bottom">
    <div class="bottom-content">
      <%# Chat Messages %>
      <div class="bottom-chat" data-game-layout-target="chatPanel">
        <%= turbo_frame_tag "chat_panel", src: chat_panel_path do %>
          <div class="loading-placeholder">Loading chat...</div>
        <% end %>
      </div>

      <%# Online Players List %>
      <div class="bottom-online" data-game-layout-target="onlinePanel">
        <%= turbo_frame_tag "online_panel", src: online_players_path do %>
          <div class="loading-placeholder">Loading players...</div>
        <% end %>
      </div>
    </div>

    <%# Chat Input Bar %>
    <div class="bottom-input">
      <%= form_with url: chat_messages_path,
                    method: :post,
                    class: "chat-input-form",
                    data: {
                      controller: "chat-input",
                      action: "turbo:submit-end->chat-input#reset"
                    } do |f| %>
        <%= f.text_field :body,
            class: "chat-input-field",
            placeholder: "Type a message...",
            autocomplete: "off",
            data: { chat_input_target: "input" } %>
        <%= f.submit "Send", class: "chat-send-btn" %>
      <% end %>

      <div class="chat-controls">
        <button class="chat-control-btn"
                data-action="click->game-layout#toggleChatMode"
                data-game-layout-target="chatModeBtn"
                title="Chat mode: All messages">
          💬
        </button>
        <button class="chat-control-btn"
                data-action="click->game-layout#cycleChatSpeed"
                data-game-layout-target="chatSpeedBtn"
                title="Refresh speed: 10s">
          ⏱
        </button>
        <button class="chat-control-btn"
                data-action="click->game-layout#toggleClanChat"
                title="Clan chat">
          🏰
        </button>
        <button class="chat-control-btn"
                data-action="click->game-layout#clearChat"
                title="Clear chat">
          🗑
        </button>
      </div>
    </div>
  </footer>

</body>
</html>
```

### Stimulus Controller: `game_layout_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Game layout controller - manages resizable panels and chat settings
// Inspired by Neverlands' frame-based layout
export default class extends Controller {
  static targets = [
    "header", "main", "resizeHandle", "bottom",
    "chatPanel", "onlinePanel", "chatModeBtn", "chatSpeedBtn"
  ]

  static values = {
    bottomHeight: { type: Number, default: 240 },
    minHeight: { type: Number, default: 120 },
    maxHeight: { type: Number, default: 500 },
    chatMode: { type: Number, default: 0 },     // 0=all, 1=private, 2=none
    chatSpeed: { type: Number, default: 10 },   // seconds
    onlineSpeed: { type: Number, default: 60 }  // seconds
  }

  // Resize step (like Neverlands' 60px increments)
  resizeStep = 60
  isResizing = false

  connect() {
    this.loadPreferences()
    this.applyLayout()
    this.subscribeToChannels()
    this.startRefreshTimers()

    // Keyboard shortcuts
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.stopRefreshTimers()
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  // === LAYOUT RESIZING ===

  startResize(event) {
    event.preventDefault()
    this.isResizing = true
    this.startY = event.clientY
    this.startHeight = this.bottomHeightValue

    document.addEventListener("mousemove", this.doResize.bind(this))
    document.addEventListener("mouseup", this.stopResize.bind(this))
    document.body.style.cursor = "ns-resize"
    document.body.style.userSelect = "none"
  }

  doResize(event) {
    if (!this.isResizing) return

    const deltaY = this.startY - event.clientY
    let newHeight = this.startHeight + deltaY

    // Snap to grid (60px increments like Neverlands)
    newHeight = Math.round(newHeight / this.resizeStep) * this.resizeStep

    // Clamp to min/max
    newHeight = Math.max(this.minHeightValue, Math.min(this.maxHeightValue, newHeight))

    this.bottomHeightValue = newHeight
    this.applyLayout()
  }

  stopResize() {
    this.isResizing = false
    document.removeEventListener("mousemove", this.doResize.bind(this))
    document.removeEventListener("mouseup", this.stopResize.bind(this))
    document.body.style.cursor = ""
    document.body.style.userSelect = ""

    this.savePreferences()
  }

  // Quick resize buttons (like Neverlands' change_chatsize)
  increaseChatSize() {
    this.bottomHeightValue = Math.min(
      this.bottomHeightValue + this.resizeStep,
      this.maxHeightValue
    )
    this.applyLayout()
    this.savePreferences()
  }

  decreaseChatSize() {
    this.bottomHeightValue = Math.max(
      this.bottomHeightValue - this.resizeStep,
      this.minHeightValue
    )
    this.applyLayout()
    this.savePreferences()
  }

  applyLayout() {
    document.documentElement.style.setProperty(
      "--bottom-panel-height",
      `${this.bottomHeightValue}px`
    )
  }

  // === CHAT MODE ===

  // Cycle through: All → Private Only → None → All
  toggleChatMode() {
    this.chatModeValue = (this.chatModeValue + 1) % 3
    this.updateChatModeUI()
    this.savePreferences()

    // Apply filter to chat panel
    if (this.hasChatPanelTarget) {
      this.chatPanelTarget.dataset.chatMode = this.chatModeValue
    }
  }

  updateChatModeUI() {
    if (!this.hasChatModeBtnTarget) return

    const modes = [
      { icon: "💬", title: "All messages" },
      { icon: "🔒", title: "Private only" },
      { icon: "🔇", title: "Chat hidden" }
    ]

    const mode = modes[this.chatModeValue]
    this.chatModeBtnTarget.textContent = mode.icon
    this.chatModeBtnTarget.title = `Chat mode: ${mode.title}`
  }

  // === CHAT REFRESH SPEED ===

  cycleChatSpeed() {
    const speeds = [10, 30, 60]
    const currentIndex = speeds.indexOf(this.chatSpeedValue)
    this.chatSpeedValue = speeds[(currentIndex + 1) % speeds.length]

    this.updateChatSpeedUI()
    this.restartChatRefresh()
    this.savePreferences()
  }

  updateChatSpeedUI() {
    if (!this.hasChatSpeedBtnTarget) return
    this.chatSpeedBtnTarget.title = `Refresh speed: ${this.chatSpeedValue}s`
  }

  // === CHAT ACTIONS ===

  toggleClanChat() {
    // Insert clan prefix into chat input
    const input = document.querySelector("[data-chat-input-target='input']")
    if (input) {
      input.value = "%clan% " + input.value
      input.focus()
    }
  }

  clearChat() {
    const chatMessages = this.chatPanelTarget.querySelector(".chat-messages")
    if (chatMessages && confirm("Clear all chat messages?")) {
      chatMessages.innerHTML = ""
    }
  }

  // === REFRESH TIMERS ===

  startRefreshTimers() {
    // Chat refresh (via ActionCable, no polling needed)
    // Online players refresh
    this.onlineTimer = setInterval(() => {
      this.refreshOnlinePlayers()
    }, this.onlineSpeedValue * 1000)
  }

  stopRefreshTimers() {
    if (this.onlineTimer) clearInterval(this.onlineTimer)
  }

  restartChatRefresh() {
    // ActionCable handles chat - this is for fallback polling if needed
  }

  refreshOnlinePlayers() {
    if (this.hasOnlinePanelTarget) {
      const frame = this.onlinePanelTarget.querySelector("turbo-frame")
      if (frame) frame.reload()
    }
  }

  // === CHANNEL SUBSCRIPTIONS ===

  subscribeToChannels() {
    // Chat channel subscription
    this.chatSubscription = consumer.subscriptions.create(
      { channel: "ChatChannel" },
      {
        received: (data) => this.handleChatMessage(data)
      }
    )

    // Online presence channel
    this.presenceSubscription = consumer.subscriptions.create(
      { channel: "PresenceChannel" },
      {
        received: (data) => this.handlePresenceUpdate(data)
      }
    )
  }

  handleChatMessage(data) {
    // Filter based on chat mode
    if (this.chatModeValue === 2) return // Hidden
    if (this.chatModeValue === 1 && !data.is_private) return // Private only

    // Append message to chat
    const chatMessages = this.chatPanelTarget.querySelector(".chat-messages")
    if (chatMessages) {
      chatMessages.insertAdjacentHTML("beforeend", data.html)
      this.scrollChatToBottom()
      this.trimChatHistory()
    }
  }

  handlePresenceUpdate(data) {
    // Update online players list
    const onlineList = this.onlinePanelTarget.querySelector(".online-list")
    if (onlineList) {
      // Update or add player entry
    }
  }

  scrollChatToBottom() {
    const chatMessages = this.chatPanelTarget.querySelector(".chat-messages")
    if (chatMessages) {
      chatMessages.scrollTop = chatMessages.scrollHeight
    }
  }

  // Prevent memory issues (like Neverlands' ChatClearSize)
  trimChatHistory() {
    const chatMessages = this.chatPanelTarget.querySelector(".chat-messages")
    if (!chatMessages) return

    const maxLength = 12000 // ~12KB of HTML
    if (chatMessages.innerHTML.length > maxLength) {
      // Keep only recent messages
      const messages = chatMessages.querySelectorAll(".chat-msg")
      const keepCount = Math.floor(messages.length / 2)

      for (let i = 0; i < messages.length - keepCount; i++) {
        messages[i].remove()
      }
    }
  }

  // === KEYBOARD SHORTCUTS ===

  handleKeydown(event) {
    // Enter to focus chat input
    if (event.key === "Enter" && !event.target.matches("input, textarea")) {
      event.preventDefault()
      const input = document.querySelector("[data-chat-input-target='input']")
      if (input) input.focus()
    }

    // Escape to blur chat input
    if (event.key === "Escape") {
      document.activeElement?.blur()
    }

    // Ctrl+Up/Down to resize chat panel
    if (event.ctrlKey && event.key === "ArrowUp") {
      event.preventDefault()
      this.increaseChatSize()
    }
    if (event.ctrlKey && event.key === "ArrowDown") {
      event.preventDefault()
      this.decreaseChatSize()
    }
  }

  // === PREFERENCES ===

  loadPreferences() {
    try {
      const prefs = JSON.parse(localStorage.getItem("gameLayoutPrefs") || "{}")
      if (prefs.bottomHeight) this.bottomHeightValue = prefs.bottomHeight
      if (prefs.chatMode !== undefined) this.chatModeValue = prefs.chatMode
      if (prefs.chatSpeed) this.chatSpeedValue = prefs.chatSpeed

      this.updateChatModeUI()
      this.updateChatSpeedUI()
    } catch (e) {
      console.warn("Failed to load layout preferences", e)
    }
  }

  savePreferences() {
    try {
      localStorage.setItem("gameLayoutPrefs", JSON.stringify({
        bottomHeight: this.bottomHeightValue,
        chatMode: this.chatModeValue,
        chatSpeed: this.chatSpeedValue
      }))
    } catch (e) {
      console.warn("Failed to save layout preferences", e)
    }
  }
}
```

### CSS Styles

```css
/* ============================================
   GAME LAYOUT - MAIN STRUCTURE
   (Replaces iframe-based Neverlands layout)
   ============================================ */

:root {
  --header-height: 50px;
  --bottom-panel-height: 240px;
  --resize-handle-height: 8px;
  --chat-input-height: 40px;
  --online-panel-width: 300px;
}

.game-layout {
  display: grid;
  grid-template-rows: var(--header-height) 1fr var(--resize-handle-height) var(--bottom-panel-height);
  height: 100vh;
  overflow: hidden;
  background: #1a1a1a;
}

/* === HEADER === */
.game-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--nl-space-md);
  background: linear-gradient(180deg, #FCFAF3 0%, #F3ECD7 100%);
  border-bottom: 2px solid #B9A05C;
}

.header-left {
  display: flex;
  align-items: center;
  gap: var(--nl-space-md);
}

.game-logo img {
  height: 32px;
}

.header-character {
  font-weight: bold;
}

.char-name {
  color: #222;
}

.char-level {
  color: #666;
  font-size: 0.9em;
}

.header-nav {
  display: flex;
  gap: var(--nl-space-xs);
}

.header-btn {
  padding: 6px 14px;
  background: linear-gradient(180deg, #fff 0%, #f0f0f0 100%);
  border: 1px solid #ccc;
  border-radius: var(--nl-radius-sm);
  color: #333;
  font-weight: bold;
  font-size: 0.85rem;
  text-decoration: none;
  transition: all 0.2s;
}

.header-btn:hover {
  background: linear-gradient(180deg, #f0f0f0 0%, #e0e0e0 100%);
}

.header-btn--active {
  background: #EAEAEA;
  border-color: #999;
}

.header-right {
  display: flex;
  align-items: center;
}

.header-exit {
  padding: 4px 8px;
  color: #c00;
  font-size: 0.85rem;
}

.header-exit:hover {
  text-decoration: underline;
}

/* === MAIN CONTENT AREA === */
.game-main {
  overflow: auto;
  background: #fff;
}

.game-main turbo-frame {
  display: block;
  height: 100%;
}

/* === RESIZE HANDLE === */
.resize-handle {
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(180deg, #B9A05C 0%, #9a8040 100%);
  cursor: ns-resize;
  user-select: none;
  transition: background 0.2s;
}

.resize-handle:hover {
  background: linear-gradient(180deg, #d4b96a 0%, #B9A05C 100%);
}

.resize-grip {
  color: rgba(255,255,255,0.6);
  font-size: 10px;
  letter-spacing: 2px;
}

/* === BOTTOM PANEL === */
.game-bottom {
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
  border-top: 1px solid #ccc;
  overflow: hidden;
}

.bottom-content {
  display: grid;
  grid-template-columns: 1fr var(--online-panel-width);
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

/* Chat Panel */
.bottom-chat {
  display: flex;
  flex-direction: column;
  border-right: 1px solid #ccc;
  overflow: hidden;
}

.bottom-chat turbo-frame {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: var(--nl-space-xs);
  background: #fff;
}

/* Hidden mode */
.bottom-chat[data-chat-mode="2"] .chat-messages {
  display: none;
}

.bottom-chat[data-chat-mode="2"]::after {
  content: "Chat hidden";
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 1;
  color: #999;
  font-style: italic;
}

/* Private only mode */
.bottom-chat[data-chat-mode="1"] .chat-msg:not(.chat-msg--private):not(.chat-msg--whisper) {
  display: none;
}

/* Online Players Panel */
.bottom-online {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #fafafa;
}

.online-header {
  padding: var(--nl-space-xs) var(--nl-space-sm);
  background: #f0f0f0;
  border-bottom: 1px solid #ddd;
  font-weight: bold;
  font-size: 0.85rem;
}

.online-count {
  color: #666;
  font-weight: normal;
}

.online-list {
  flex: 1;
  overflow-y: auto;
  padding: var(--nl-space-xs);
}

.online-player {
  display: flex;
  align-items: center;
  gap: var(--nl-space-xs);
  padding: 3px var(--nl-space-xs);
  border-radius: var(--nl-radius-sm);
  cursor: pointer;
  transition: background 0.1s;
}

.online-player:hover {
  background: #e8e8e8;
}

.online-player-status {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #40c057;
}

.online-player-status--idle {
  background: #fab005;
}

.online-player-status--busy {
  background: #e03131;
}

.online-player-name {
  flex: 1;
  font-size: 0.85rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.online-player-level {
  color: #666;
  font-size: 0.75rem;
}

/* Chat Input Bar */
.bottom-input {
  display: flex;
  align-items: center;
  gap: var(--nl-space-sm);
  padding: var(--nl-space-xs) var(--nl-space-sm);
  background: #FCFAF3;
  border-top: 1px solid #ddd;
  height: var(--chat-input-height);
}

.chat-input-form {
  display: flex;
  flex: 1;
  gap: var(--nl-space-xs);
}

.chat-input-field {
  flex: 1;
  padding: 6px 12px;
  border: 1px solid #ccc;
  border-radius: var(--nl-radius-sm);
  font-size: 0.9rem;
}

.chat-input-field:focus {
  outline: none;
  border-color: var(--nl-gold);
}

.chat-send-btn {
  padding: 6px 16px;
  background: linear-gradient(180deg, #4CAF50 0%, #388E3C 100%);
  border: 1px solid #2E7D32;
  border-radius: var(--nl-radius-sm);
  color: #fff;
  font-weight: bold;
  cursor: pointer;
}

.chat-send-btn:hover {
  background: linear-gradient(180deg, #66BB6A 0%, #43A047 100%);
}

.chat-controls {
  display: flex;
  gap: 4px;
}

.chat-control-btn {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f0f0f0;
  border: 1px solid #ccc;
  border-radius: var(--nl-radius-sm);
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s;
}

.chat-control-btn:hover {
  background: #e0e0e0;
}

.chat-control-btn--active {
  background: var(--nl-gold);
  border-color: #c9a030;
}

/* === LOADING PLACEHOLDER === */
.loading-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #999;
  font-style: italic;
}

/* === RESPONSIVE === */
@media (max-width: 768px) {
  :root {
    --online-panel-width: 0px;
  }

  .bottom-online {
    display: none;
  }

  .header-nav {
    display: none;
  }
}
```

## Feature Comparison

| Feature | Neverlands (iframes) | Our Implementation |
|---------|---------------------|-------------------|
| Layout | `<frameset>` rows/cols | CSS Grid |
| Main content loading | `<frame src="...">` | Turbo Frames |
| Chat updates | Polling (`setInterval`) | ActionCable WebSocket |
| Resize panels | JavaScript `rows="..."` | CSS custom properties + drag |
| Online players | Iframe refresh | Turbo Frame reload |
| Chat modes | `ChatFyo` variable | Stimulus value + CSS |
| Preferences | None (session) | localStorage |
| Keyboard shortcuts | Frame focus | Stimulus keydown |

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Enter` | Focus chat input |
| `Escape` | Blur chat input |
| `Ctrl+↑` | Increase chat panel size |
| `Ctrl+↓` | Decrease chat panel size |

---

## Responsible for Implementation Files
- **Layouts:** `app/views/layouts/game.html.erb` (Neverlands-style dark theme)
- **Controllers:** `app/javascript/controllers/game_layout_controller.js` (resize, tabs, player menu, keyboard shortcuts)
- **Partials:**
  - `app/views/shared/_vitals_bar.html.erb` — HP/MP bars for status bar
  - `app/views/shared/_online_players_compact.html.erb` — Compact sidebar player list
  - `app/views/shared/_online_players.html.erb` — Full player list (legacy)
- **Channels:** `app/channels/realtime_chat_channel.rb`, `app/channels/presence_channel.rb`
- **CSS:** `app/assets/stylesheets/application.css` (`.nl-game-layout` section with dark fantasy theme)
- **Routes:** `config/routes.rb` (`chat_channels_path`, `chat_messages_path`)

