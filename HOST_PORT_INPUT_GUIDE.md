# Host Port Input Guide - Kaard TCG Multiplayer

## Perbaikan yang Ditambahkan

### 🎯 **Host Port Input**
- **Port Input Field**: Host bisa memasukkan port yang ingin digunakan
- **Start Host Button**: Tombol untuk memulai hosting dengan port yang dimasukkan
- **Port Validation**: Hanya allow angka untuk port input
- **Error Handling**: Pesan error jika port tidak bisa digunakan

### 🔧 **Perbaikan Status Display**
- **Conditional Status**: Status "Client connected!" hanya muncul setelah client benar-benar konek
- **Host Status**: Status "Waiting for players..." muncul setelah host dimulai
- **Port Display**: Menampilkan port yang sedang digunakan setelah host dimulai

## Cara Menggunakan

### **Untuk Host:**
1. **Buka game** → Pilih "Multiplayer" → "Host Game"
2. **Input Port**: Klik field "Port" dan ketik port yang ingin digunakan (default: 12345)
3. **Start Host**: Tekan "Start Host" untuk memulai hosting
4. **Lihat Status**: Status akan berubah ke "Waiting for players..." dan menampilkan "Listening on port: XXXX"
5. **Tunggu Client**: Ketika client konek, status berubah ke "Client connected!"
6. **Tekan Ready**: Ketika client ready, tekan "Ready" → "Start Game"

### **Untuk Client:**
1. **Buka game** → Pilih "Multiplayer" → "Join Game"
2. **Input IP**: Klik field "IP Address" dan ketik IP host (default: localhost)
3. **Input Port**: Klik field "Port" dan ketik port yang digunakan host
4. **Connect**: Tekan "Connect" untuk konek ke host
5. **Tekan Ready**: Ketika host ready, tekan "Ready"

## Input Controls

### **Keyboard Shortcuts:**
- **Enter**: Simpan input dan keluar dari input mode
- **Escape**: Batalkan input
- **Backspace**: Hapus karakter
- **Left/Right Arrow**: Pindah cursor
- **Home**: Pindah ke awal text
- **End**: Pindah ke akhir text

### **Input Validation:**
- **Port**: Hanya allow angka (0-9)
- **IP Address**: Hanya allow huruf, angka, titik, dan tanda hubung

## Status Flow

### **Host Status Flow:**
```
1. "Host Game" → Input port → "Start Host"
2. "Host started on port XXXX" → "Waiting for players..."
3. Client connects → "Client connected!"
4. Client ready → "Client Ready"
5. Host ready → "Start Game" button appears
```

### **Client Status Flow:**
```
1. "Join Game" → Input IP & port → "Connect"
2. "Connecting to localhost:XXXX" → "Connected!"
3. Host ready → "Host Ready"
4. Client ready → "Client Ready"
5. Host starts game → Transition to deck builder
```

## Troubleshooting

### **Jika Host Tidak Bisa Start:**

#### **1. Port Already in Use:**
- **Error**: "Failed to bind to port XXXX - Port already in use"
- **Solution**: Coba port lain (misalnya 12346, 12347, dll)
- **Check**: Pastikan tidak ada aplikasi lain yang menggunakan port tersebut

#### **2. Invalid Port:**
- **Error**: "Failed to bind to port XXXX - Invalid port"
- **Solution**: Gunakan port yang valid (1024-65535)
- **Avoid**: Port 0-1023 biasanya reserved untuk system

#### **3. Permission Denied:**
- **Error**: "Failed to bind to port XXXX - Permission denied"
- **Solution**: Gunakan port di atas 1024
- **Check**: Pastikan tidak ada firewall yang memblokir

### **Jika Client Tidak Bisa Konek:**

#### **1. Wrong Port:**
- **Error**: "Failed to connect to localhost:XXXX - Connection refused"
- **Solution**: Pastikan port client sama dengan port host
- **Check**: Lihat "Listening on port: XXXX" di host

#### **2. Wrong IP:**
- **Error**: "Failed to connect to XXXX:XXXX - Connection refused"
- **Solution**: Pastikan IP address benar
- **Local**: Gunakan "localhost" atau "127.0.0.1"
- **Network**: Gunakan IP address komputer host

#### **3. Host Not Started:**
- **Error**: "Failed to connect to localhost:XXXX - Connection refused"
- **Solution**: Pastikan host sudah menekan "Start Host"
- **Check**: Host harus menampilkan "Waiting for players..."

## Testing Sequence

### **Step 1: Host Setup**
```
1. Host: "Multiplayer" → "Host Game"
2. Host: Input port = "12345" (atau port lain)
3. Host: Tekan "Start Host"
4. Host: Lihat "Host started on port 12345"
5. Host: Status "Waiting for players..."
6. Host: Lihat "Listening on port: 12345"
```

### **Step 2: Client Connection**
```
1. Client: "Multiplayer" → "Join Game"
2. Client: Input IP = "localhost"
3. Client: Input Port = "12345" (sesuai dengan host)
4. Client: Tekan "Connect"
5. Client: Status "Connected!"
6. Host: Status berubah ke "Client connected!"
```

### **Step 3: Ready Phase**
```
1. Host: Tekan "Ready" → Status "Host Ready"
2. Client: Status berubah ke "Host Ready"
3. Client: Tekan "Ready" → Status "Client Ready"
4. Host: Status berubah ke "Client Ready"
5. Host: Tombol "Start Game" muncul
6. Host: Tekan "Start Game" untuk mulai
```

## Network Flow

```
Host: startHost(12345) → bind port 12345 → accept client
Client: connectToHost("localhost", 12345) → connect to host
Host: sendPlayerReady(true) → client: receive → lobby: handleNetworkMessage()
Client: sendPlayerReady(true) → host: receive → lobby: handleNetworkMessage()
Host: sendGameStart() → client: receive → transition to deck builder
```

## Debug Information

### **Console Logs:**
```
Host started on port 12345
Connecting to localhost:12345
Client connected!
Sending PLAYER_READY: true from player 1
Host received: type:PLAYER_READY|playerId:1|timestamp:123.45|ready:true
Lobby received message: PLAYER_READY ready: true
Host: Client ready status updated to true
```

### **Visual Indicators:**
- **Blue Highlight**: Field sedang aktif untuk input
- **Blinking Cursor**: Sedang mengetik
- **Green Status**: Koneksi berhasil
- **Red Status**: Error atau tidak terhubung
- **Yellow Status**: Waiting atau connecting

Dengan fitur ini, sekarang host bisa memilih port yang ingin digunakan dan status tidak akan menampilkan "Client connected!" sebelum client benar-benar konek! 🎉
