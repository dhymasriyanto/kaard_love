# Multiplayer Guide - Kaard TCG

## Overview
Sistem multiplayer telah diimplementasikan menggunakan luasocket untuk memungkinkan dua pemain bermain game kartu secara online.

## Fitur Multiplayer

### 1. Lobby System
- **Host Game**: Player pertama membuat game dan menunggu client bergabung
- **Join Game**: Player kedua bergabung dengan memasukkan IP address host
- **Ready System**: Kedua player harus menekan "Ready" sebelum game dimulai
- **Start Game**: Hanya host yang bisa memulai game

### 2. Deck Builder Multiplayer
- Setiap player memilih deck mereka sendiri secara terpisah
- Tidak ada tombol switch player (Player A/B) dalam mode multiplayer
- Player menekan Enter untuk mengkonfirmasi deck selection
- Waiting popup muncul saat menunggu opponent selesai memilih deck
- Game otomatis dimulai ketika kedua player sudah siap

### 3. Game Flow Multiplayer
- **Setup Phase**: Kedua player bisa meletakkan kartu secara bersamaan
- **Pass Button**: Hanya player yang sedang bermain yang bisa menekan pass
- **Coin Toss**: Host menentukan hasil coin toss, client menerima hasilnya
- **Combat Phase**: Turn-based combat dengan sinkronisasi network
- **Card Display**: Kartu lawan terlihat tapi tidak terungkap (menampilkan card back)

### 4. Network Synchronization
- **Card Placement**: Sinkronisasi saat player meletakkan kartu
- **Card Reveal**: Sinkronisasi saat kartu diungkap
- **Turn Changes**: Sinkronisasi pergantian giliran
- **Setup Pass**: Sinkronisasi saat player pass di setup phase
- **Game State**: Sinkronisasi state game secara berkala

## Cara Menggunakan

### Untuk Host:
1. Jalankan game
2. Pilih "Multiplayer" di menu utama
3. Pilih "Host Game"
4. Tunggu client bergabung
5. Tekan "Ready" ketika siap
6. Tekan "Start Game" ketika kedua player ready
7. Pilih deck dan tekan Enter
8. Mulai bermain!

### Untuk Client:
1. Jalankan game
2. Pilih "Multiplayer" di menu utama
3. Pilih "Join Game"
4. Masukkan IP address host (default: localhost)
5. Tekan "Connect"
6. Tekan "Ready" ketika siap
7. Tunggu host memulai game
8. Pilih deck dan tekan Enter
9. Mulai bermain!

## Technical Details

### Network Module (`src/core/network.lua`)
- Menggunakan luasocket untuk TCP connection
- Port default: 12345
- Non-blocking socket operations
- Heartbeat system untuk menjaga koneksi
- Message queue untuk handling network messages

### Message Types
- `PLAYER_READY`: Status ready player
- `PLAYER_DECK_SELECTED`: Deck yang dipilih player
- `GAME_START`: Host memulai game
- `CARD_PLACED`: Kartu diletakkan di field
- `CARD_REVEALED`: Kartu diungkap
- `SETUP_PASSED`: Player pass di setup phase
- `TURN_CHANGED`: Pergantian giliran
- `COIN_TOSS_RESULT`: Hasil coin toss
- `GAME_STATE_SYNC`: Sinkronisasi state game

### Lobby System (`src/ui/lobby.lua`)
- UI untuk host/client selection
- Connection management
- Ready state tracking
- Error handling dan status display

### Deck Builder Multiplayer (`src/ui/deckbuilder.lua`)
- Individual deck selection
- Network synchronization
- Waiting states dan popups
- Validation untuk deck selection

## Troubleshooting

### Connection Issues
- Pastikan firewall tidak memblokir port 12345
- Pastikan kedua computer dalam network yang sama
- Cek IP address host dengan benar

### Game Sync Issues
- Pastikan kedua player menggunakan versi game yang sama
- Restart game jika ada masalah sinkronisasi
- Cek network connection stability

### Performance
- Game menggunakan non-blocking sockets untuk performa optimal
- Heartbeat system menjaga koneksi tetap hidup
- Message queue mencegah blocking operations

## Future Improvements
- Reconnection system
- Spectator mode
- Tournament system
- Chat system
- Replay system
- Better error handling
- Network optimization
