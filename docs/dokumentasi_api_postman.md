# Panduan & Dokumentasi Pengujian API (Postman)
*Panduan Praktis Uji Coba API untuk E-Ticketing Helpdesk Mobile*

---

## 1. Konfigurasi Global & Otorisasi

Setiap permintaan (*Request*) ke API Supabase **wajib** menyertakan informasi otorisasi dan kunci proyek di bagian **Headers** Postman.

### A. Informasi Server
- **Base URL:** `https://cssmgixdcyhsxjqxjrku.supabase.co`

### B. Headers Wajib
Konfigurasikan baris-baris berikut pada tab **Headers** di Postman Anda:

| Key | Value | Keterangan |
| :--- | :--- | :--- |
| **`apikey`** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzc21naXhkY3loc3hqcXhqcmt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3OTQwNjEsImV4cCI6MjA5ODM3MDA2MX0.nENDORP9rV-oDJ_pXp6baej8scpwgtwTcCbl1d84y4U` | Anon Key Proyek Anda |
| **`Authorization`** | `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzc21naXhkY3loc3hqcXhqcmt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3OTQwNjEsImV4cCI6MjA5ODM3MDA2MX0.nENDORP9rV-oDJ_pXp6baej8scpwgtwTcCbl1d84y4U` | Diawali dengan kata `Bearer ` diikuti Anon Key Anda |
| **`Content-Type`** | `application/json` | Ditambahkan otomatis saat memilih format raw JSON |

---

## 2. Koleksi Endpoint Uji Coba API

### 2.1 Mengambil Semua Data Tiket (GET Tickets)
Mengambil daftar keluhan tiket yang tersimpan di dalam database.
- **HTTP Method:** `GET`
- **URL:** 
  ```text
  https://cssmgixdcyhsxjqxjrku.supabase.co/rest/v1/tickets?select=*
  ```
- **Response (200 OK):**
  ```json
  [
    {
      "id": "1e5c3e06-bfbe-4d92-94b1-e28a50de70fa",
      "title": "Printer Kantor Rusak",
      "description": "Tidak merespon cetak dokumen di lantai 2",
      "status": "open",
      "priority": "high",
      "creator_id": "2",
      "creator_name": "Fadhil Ilyas",
      "assignee_id": null,
      "assignee_name": null,
      "image_path": null,
      "created_at": "2026-07-02T12:00:00.000Z"
    }
  ]
  ```

---

### 2.2 Membuat Tiket Baru (POST Create Ticket)
Menyimpan satu tiket kendala baru ke dalam tabel `tickets`.
- **HTTP Method:** `POST`
- **URL:**
  ```text
  https://cssmgixdcyhsxjqxjrku.supabase.co/rest/v1/tickets
  ```
- **Body Tab:** Pilih `raw` $\rightarrow$ pilih tipe `JSON`.
- **Payload (JSON):**
  ```json
  {
    "title": "Uji Coba Tiket Postman",
    "description": "Ini adalah tiket uji coba pertama menggunakan Postman API",
    "priority": "low",
    "creator_id": "2",
    "creator_name": "Tester Postman",
    "status": "open"
  }
  ```
- **Response (201 Created):** Mengembalikan data tiket yang baru saja berhasil dibuat.

---

### 2.3 Login Autentikasi Pengguna (POST Login)
Mengirim kredensial username/email untuk mendapatkan token akses pengguna (*User JWT Token*).
- **HTTP Method:** `POST`
- **URL:**
  ```text
  https://cssmgixdcyhsxjqxjrku.supabase.co/auth/v1/token?grant_type=password
  ```
- **Body Tab:** Pilih `raw` $\rightarrow$ tipe `JSON`.
- **Payload (JSON):**
  ```json
  {
    "email": "user@gmail.com",
    "password": "password123"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6Ik...",
    "token_type": "bearer",
    "user": {
      "id": "uuid-user-123",
      "email": "user@gmail.com"
    }
  }
  ```
> [!NOTE]
> Setelah berhasil login, Anda dapat menyalin nilai `access_token` hasil response ini untuk menggantikan Anon Key pada header **`Authorization`** (`Bearer <access_token_di_sini>`) saat melakukan kueri lain agar bertindak sebagai pengguna tersebut.

---

### 2.4 Mengubah Status / Delegasi Tiket (PATCH Update Ticket)
Memperbarui status tiket (untuk skenario "Terima", "Tugaskan", atau "Selesaikan").
- **HTTP Method:** `PATCH`
- **URL:** Ganti `{ticketId}` dengan ID tiket riil dari database Anda.
  ```text
  https://cssmgixdcyhsxjqxjrku.supabase.co/rest/v1/tickets?id=eq.{ticketId}
  ```
- **Body Tab:** Pilih `raw` $\rightarrow$ tipe `JSON`.
- **Payload Skenario A (Terima Tiket oleh Admin):**
  ```json
  {
    "status": "assign"
  }
  ```
- **Payload Skenario B (Tugaskan Helpdesk oleh Admin):**
  ```json
  {
    "status": "on progress",
    "assignee_id": "h1",
    "assignee_name": "Budi - Networking"
  }
  ```
- **Payload Skenario C (Selesai Pekerjaan oleh Helpdesk/Admin):**
  ```json
  {
    "status": "close"
  }
  ```
- **Response (204 No Content):** Update sukses tanpa error.

---

### 2.5 Mengirim Komentar di Tiket (POST Comment)
Menulis pesan tanggapan di dalam ruang obrolan tiket teknis.
- **HTTP Method:** `POST`
- **URL:**
  ```text
  https://cssmgixdcyhsxjqxjrku.supabase.co/rest/v1/ticket_comments
  ```
- **Body Tab:** Pilih `raw` $\rightarrow$ tipe `JSON`.
- **Payload (JSON):**
  ```json
  {
    "ticket_id": "GANTI_DENGAN_ID_TIKET_AKTIF",
    "user_id": "h1",
    "user_name": "Budi - Networking",
    "message": "Kabel LAN sedang kami ganti dengan yang baru, harap tunggu."
  }
  ```
- **Response (201 Created):** Komentar berhasil ditambahkan ke database.

---

### 2.6 Mengambil Notifikasi Masuk (GET Notifications)
Mengambil daftar pemberitahuan khusus untuk akun pengguna tertentu.
- **HTTP Method:** `GET`
- **URL:** Ganti `{userId}` dengan ID pengguna terdaftar.
  ```text
  https://cssmgixdcyhsxjqxjrku.supabase.co/rest/v1/notifications?user_id=eq.{userId}
  ```
- **Response (200 OK):** Mengembalikan daftar notifikasi untuk pengguna tersebut.
