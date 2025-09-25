# 🎮 Panduan Multiplayer Kaard

## Cara Menggunakan Multiplayer

### ⚠️ Catatan Penting
Implementasi multiplayer saat ini menggunakan **shared memory** untuk komunikasi lokal. Ini berarti:
- **Hanya bisa digunakan untuk testing lokal** (dua instance game di komputer yang sama)
- **Tidak bisa digunakan untuk multiplayer melalui internet**
- Untuk multiplayer internet, perlu implementasi networking yang lebih advanced

### 🚀 Cara Menjalankan Multiplayer Lokal

#### Langkah 1: Buka Dua Instance Game
1. Buka **instance pertama** dari game Kaard
2. Buka **instance kedua** dari game Kaard (drag folder ke love.exe lagi atau jalankan dari terminal)

#### Langkah 2: Setup Host (Instance Pertama)
1. Di instance pertama, klik **"Host Game"**
2. Masukkan port: `12345` (atau port lain)
3. Klik **"Connect"**
4. Anda akan masuk ke **lobby** dengan status "Waiting for opponent..."

#### Langkah 3: Setup Client (Instance Kedua)
1. Di instance kedua, klik **"Join Game"**
2. Masukkan host: `localhost`
3. Masukkan port: `12345` (sama dengan host)
4. Klik **"Connect"**
5. Anda akan masuk ke **lobby** dengan status "Connected"

#### Langkah 4: Mulai Game
1. Di kedua instance, klik **"Ready"** untuk menandai siap
2. Ketika kedua pemain sudah ready, klik **"Start Game"**
3. Game akan dimulai dan Anda bisa bermain multiplayer!

### 🎯 Fitur Multiplayer yang Tersedia

#### ✅ Yang Sudah Bekerja:
- **Lobby System** - Menunggu pemain kedua bergabung
- **Ready System** - Konfirmasi kedua pemain siap
- **Turn Management** - Hanya pemain yang gilirannya yang bisa bermain
- **Game State Sync** - Sinkronisasi state game real-time
- **Card Placement** - Menempatkan kartu di fase setup
- **Combat Actions** - Reveal kartu dan combat
- **Pass Actions** - Pass di fase setup
- **Status Indicators** - Status koneksi di UI

#### 🔧 Status Koneksi:
- **Connected** (Hijau) - Koneksi berhasil
- **Connecting** (Kuning) - Sedang mencoba koneksi
- **Error** (Merah) - Ada masalah koneksi
- **Disconnected** (Abu-abu) - Tidak terhubung

### 🐛 Troubleshooting

#### Problem: "Connection timeout"
**Solusi**: Pastikan kedua instance game berjalan dan menggunakan port yang sama.

#### Problem: Tidak bisa join game
**Solusi**: 
1. Pastikan host sudah dibuat terlebih dahulu
2. Pastikan menggunakan `localhost` sebagai host
3. Pastikan port sama dengan host

#### Problem: Game tidak sinkron
**Solusi**: 
1. Pastikan kedua pemain sudah ready
2. Restart kedua instance jika ada masalah
3. Pastikan tidak ada error di log

### 🔮 Untuk Multiplayer Internet

Untuk multiplayer melalui internet, perlu implementasi yang lebih advanced:

1. **Real TCP/UDP Sockets** - Menggunakan library seperti luasocket
2. **NAT Traversal** - Untuk koneksi melalui router
3. **Server Infrastructure** - Dedicated server atau relay server
4. **Security** - Encryption dan validation

### 📝 Catatan Developer

Implementasi saat ini menggunakan:
- **Shared Memory** untuk komunikasi
- **JSON** untuk serialisasi data
- **File-based** message passing
- **Simple state management**

Ini cocok untuk:
- ✅ Testing lokal
- ✅ Development dan debugging
- ✅ Prototype multiplayer

Tidak cocok untuk:
- ❌ Multiplayer internet
- ❌ Production deployment
- ❌ High-performance gaming

### 🎉 Selamat Bermain!

Multiplayer lokal sudah siap digunakan! Buka dua instance game dan nikmati bermain bersama teman di komputer yang sama.

