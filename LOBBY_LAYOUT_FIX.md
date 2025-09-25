# Lobby Layout Fix - Kaard TCG Multiplayer

## Masalah yang Diperbaiki

### 🎯 **Layout Host Lobby yang Berantakan**
- **Elemen Saling Timpa**: Text dan button saling menimpa karena posisi yang tidak terorganisir
- **Posisi Hard-coded**: Y position menggunakan nilai tetap yang menyebabkan overlap
- **Status Display**: Status muncul di posisi yang salah

### 🔧 **Perbaikan yang Dilakukan**

1. **Organized Layout Structure**:
   - **Port Input Section**: Port input dan label di posisi yang jelas
   - **Start Host Button**: Tombol start host di bawah port input
   - **Status Section**: Status hanya muncul setelah host dimulai
   - **Ready Section**: Ready status dan button di posisi yang terorganisir

2. **Dynamic Positioning**:
   - **Relative Positioning**: Semua elemen menggunakan posisi relatif dari elemen sebelumnya
   - **Conditional Display**: Elemen hanya muncul ketika diperlukan
   - **Proper Spacing**: Jarak antar elemen yang konsisten

## Layout Structure

### **Host Lobby Layout:**

```
┌─────────────────────────────────────┐
│           Host Game                  │  ← Title (Y: 80)
│                                     │
│  Port: [12345]                      │  ← Port Input (Y: 120)
│                                     │
│        [Start Host]                 │  ← Start Host Button (Y: 160)
│                                     │
│    Waiting for players...           │  ← Status (Y: 200) - Only if host started
│    Listening on port: 12345         │  ← Port Info (Y: 225)
│                                     │
│    Host: Not Ready                  │  ← Ready Status (Y: 280) - Only if host started
│    Client: No Client Connected      │  ← Client Status (Y: 305)
│                                     │
│        [Ready]                      │  ← Ready Button (Y: 340) - Only if host started
│                                     │
│      [Start Game]                  │  ← Start Game Button (Y: 390) - Only if both ready
│                                     │
│  [Back]                             │  ← Back Button (Y: h-50)
└─────────────────────────────────────┘
```

### **Client Lobby Layout:**

```
┌─────────────────────────────────────┐
│           Join Game                 │  ← Title (Y: 80)
│                                     │
│  IP Address: [localhost]            │  ← IP Input (Y: 120)
│  Port: [12345]                      │  ← Port Input (Y: 160)
│                                     │
│        [Connect]                    │  ← Connect Button (Y: 200)
│                                     │
│         Connected!                  │  ← Status (Y: 240) - Only if connected
│                                     │
│    Host: Not Ready                 │  ← Host Status (Y: 280) - Only if connected
│                                     │
│        [Ready]                      │  ← Ready Button (Y: 320) - Only if connected
│                                     │
│  [Back]                             │  ← Back Button (Y: h-50)
└─────────────────────────────────────┘
```

## Perbaikan Teknis

### **1. Dynamic Y Positioning:**
```lua
-- Before (Hard-coded positions)
love.graphics.printf('Host: ' .. readyText, w*0.5 - 200, 180, 400, 'center')
love.graphics.printf('Client: ' .. clientText, w*0.5 - 200, 210, 400, 'center')

-- After (Dynamic positions)
local readySectionY = startHostButton.y + 120
love.graphics.printf('Host: ' .. readyText, w*0.5 - 200, readySectionY, 400, 'center')
love.graphics.printf('Client: ' .. clientText, w*0.5 - 200, readySectionY + 25, 400, 'center')
```

### **2. Conditional Display:**
```lua
-- Before (Always visible)
love.graphics.printf('Host: ' .. readyText, w*0.5 - 200, 180, 400, 'center')

-- After (Only if host started)
if state.network and state.network.isHost() then
    love.graphics.printf('Host: ' .. readyText, w*0.5 - 200, readySectionY, 400, 'center')
end
```

### **3. Proper Spacing:**
```lua
-- Consistent spacing between elements
local spacing = 40
local portInputY = startY + spacing
local startHostButtonY = portInputY + spacing
local statusY = startHostButtonY + spacing + 20
local readySectionY = startHostButtonY + 120
```

## Status Flow

### **Host Status Flow:**
```
1. "Host Game" → Port input → "Start Host"
2. "Host started on port XXXX" → "Waiting for players..."
3. Client connects → "Client connected!"
4. Ready section appears → "Host: Not Ready" + "Client: No Client Connected"
5. Ready button appears → "Ready" button
6. Both ready → "Start Game" button appears
```

### **Client Status Flow:**
```
1. "Join Game" → IP & port input → "Connect"
2. "Connecting to localhost:XXXX" → "Connected!"
3. Host status appears → "Host: Not Ready"
4. Ready button appears → "Ready" button
5. Host starts game → Transition to deck builder
```

## Visual Improvements

### **1. No More Overlapping:**
- ✅ Text tidak saling timpa
- ✅ Button di posisi yang jelas
- ✅ Status muncul di tempat yang tepat

### **2. Better Organization:**
- ✅ Input section di atas
- ✅ Status section di tengah
- ✅ Button section di bawah
- ✅ Back button di pojok kiri bawah

### **3. Conditional Display:**
- ✅ Status hanya muncul ketika diperlukan
- ✅ Button hanya muncul ketika relevan
- ✅ Layout yang bersih dan tidak berantakan

## Testing

### **Test Host Lobby:**
1. **Start**: "Multiplayer" → "Host Game"
2. **Input**: Port input field terlihat jelas
3. **Start**: "Start Host" button di posisi yang tepat
4. **Status**: Status muncul di bawah button
5. **Ready**: Ready section muncul setelah host dimulai
6. **Button**: Ready dan Start Game button di posisi yang benar

### **Test Client Lobby:**
1. **Start**: "Multiplayer" → "Join Game"
2. **Input**: IP dan port input field terlihat jelas
3. **Connect**: "Connect" button di posisi yang tepat
4. **Status**: Status muncul setelah koneksi berhasil
5. **Ready**: Ready button muncul setelah koneksi berhasil

Dengan perbaikan ini, layout lobby sekarang terorganisir dengan baik dan tidak ada lagi elemen yang saling timpa! 🎉
