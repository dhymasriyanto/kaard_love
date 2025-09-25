# Lobby Input Guide - Kaard TCG Multiplayer

## Fitur Baru yang Ditambahkan

### 🎯 **Input Fields untuk Client**
- **IP Address Field**: Input untuk alamat IP host
- **Port Field**: Input untuk port yang digunakan host
- **Visual Cursor**: Cursor berkedip saat mengetik
- **Keyboard Navigation**: Support untuk arrow keys, home, end, backspace

### 🖥️ **Port Display untuk Host**
- **Dynamic Port**: Host akan menampilkan port yang sedang digunakan
- **Auto Port Selection**: Host akan mencoba port 12345-12349 secara otomatis
- **Port Information**: Client bisa melihat port yang digunakan host

## Cara Menggunakan

### **Untuk Host:**
1. **Buka game** → Pilih "Multiplayer" → "Host Game"
2. **Lihat Port**: Host akan menampilkan "Port: XXXX" (misalnya Port: 12345)
3. **Tunggu Client**: Status akan berubah ke "Client connected!" ketika client konek
4. **Tekan Ready**: Ketika client ready, tekan "Ready" → "Start Game"

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
- **IP Address**: Hanya allow huruf, angka, titik, dan tanda hubung
- **Port**: Hanya allow angka (0-9)

## Troubleshooting

### **Jika Client Tidak Bisa Konek:**

#### **1. Cek IP Address:**
- **Local Testing**: Gunakan "localhost" atau "127.0.0.1"
- **Network Testing**: Gunakan IP address komputer host (misalnya 192.168.1.100)

#### **2. Cek Port:**
- **Lihat Port Host**: Host akan menampilkan port yang digunakan
- **Input Port yang Benar**: Pastikan client menggunakan port yang sama
- **Port Range**: Host akan mencoba port 12345-12349 secara otomatis

#### **3. Cek Connection Status:**
- **Host**: Status "Client connected!" ketika client berhasil konek
- **Client**: Status "Connected!" ketika berhasil konek ke host

### **Jika Input Tidak Berfungsi:**
1. **Klik Field**: Pastikan field ter-highlight (warna biru)
2. **Cek Cursor**: Cursor harus berkedip saat mengetik
3. **Save Input**: Tekan Enter untuk menyimpan input
4. **Restart**: Restart game jika masih bermasalah

## Testing Sequence

### **Step 1: Host Setup**
```
1. Host: "Multiplayer" → "Host Game"
2. Host: Lihat "Port: 12345" (atau port lain)
3. Host: Status "Waiting for players..."
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
Host: startHost() → bind port 12345 → accept client
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

Dengan fitur input ini, sekarang client bisa dengan mudah memasukkan IP dan port yang digunakan host! 🎉
