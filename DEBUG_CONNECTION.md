# Debug Connection Guide

## Cara Melihat Status Koneksi

### 1. **Visual Indicators di Lobby:**
- **Host**: Akan menampilkan "Client connected!" ketika client berhasil konek
- **Client**: Akan menampilkan "Connected!" ketika berhasil konek ke host
- **Ready Status**: Akan berubah warna ketika opponent ready

### 2. **Console Logs (F12 di browser atau terminal):**
Ketika menjalankan game, Anda akan melihat log seperti:
```
Sending PLAYER_READY: true from player 1
Sending message: type:PLAYER_READY|playerId:1|timestamp:123.45|ready:true
Host message sent successfully
Host received: type:PLAYER_READY|playerId:1|timestamp:123.45|ready:true
Host parsed message: PLAYER_READY
Lobby received message: PLAYER_READY ready: true
Host: Client ready status updated to true
```

### 3. **Troubleshooting Steps:**

#### **Jika Client Tidak Bisa Konek:**
1. **Cek IP Address**: Pastikan menggunakan "localhost" untuk testing lokal
2. **Cek Port**: Host akan mencoba port 12345-12349 secara otomatis
3. **Cek Firewall**: Pastikan Windows Firewall tidak memblokir koneksi
4. **Restart Game**: Tutup dan buka ulang kedua instance

#### **Jika Ready Status Tidak Sinkron:**
1. **Cek Console Logs**: Lihat apakah messages dikirim dan diterima
2. **Cek Connection Status**: Pastikan status "Connected!" muncul
3. **Test Manual**: Coba tekan Ready beberapa kali
4. **Restart Connection**: Disconnect dan reconnect

#### **Jika Tidak Ada Logs:**
1. **Cek Network Module**: Pastikan network.lua ter-load dengan benar
2. **Cek Game Loop**: Pastikan network.update() dipanggil di game loop
3. **Cek Message Processing**: Pastikan handleNetworkMessage() dipanggil

### 4. **Testing Sequence:**

#### **Step 1: Host Setup**
1. Buka game instance pertama
2. Pilih "Multiplayer" → "Host Game"
3. Lihat console untuk: "Host started on port XXXX"
4. Status harus menunjukkan "Waiting for players..."

#### **Step 2: Client Connection**
1. Buka game instance kedua
2. Pilih "Multiplayer" → "Join Game"
3. Masukkan "localhost" → "Connect"
4. Lihat console untuk: "Connecting to localhost:XXXX"
5. Status harus berubah ke "Connected!"

#### **Step 3: Ready Testing**
1. **Host**: Tekan "Ready" button
2. Lihat console untuk: "Sending PLAYER_READY: true from player 1"
3. **Client**: Status harus berubah ke "Host Ready"
4. **Client**: Tekan "Ready" button
5. Lihat console untuk: "Sending PLAYER_READY: true from player 2"
6. **Host**: Status harus berubah ke "Client Ready"
7. **Host**: Tombol "Start Game" harus muncul

### 5. **Common Issues:**

#### **"Cannot send message - not connected"**
- Koneksi terputus, restart game

#### **"Host send error: Connection refused"**
- Client belum konek, tunggu client connect

#### **"Client receive error: Connection reset"**
- Host disconnect, restart host

#### **"No client connection available for sending"**
- Socket belum ter-setup dengan benar, restart game

### 6. **Debug Commands:**
Jika masih ada masalah, jalankan:
```bash
lua debug_network.lua
```
Untuk test basic network connectivity.

### 7. **Network Flow:**
```
Host: startHost() → bind port → accept client
Client: connectToHost() → connect to host
Host: sendPlayerReady() → client: receive → lobby: handleNetworkMessage()
Client: sendPlayerReady() → host: receive → lobby: handleNetworkMessage()
```

Dengan debug logging ini, Anda bisa melihat exactly dimana masalahnya terjadi!
