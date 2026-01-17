# Hướng dẫn Cài đặt & Cấu hình PostgreSQL trên Linux

Tài liệu này tổng hợp các lệnh cần thiết để cập nhật hệ thống, cài đặt PostgreSQL, cấu hình Swap memory, quản lý User/Database và các lưu ý khi thao tác với Terminal.

## 1. Cài đặt và Khởi chạy PostgreSQL

### Cập nhật hệ thống
Trước khi cài đặt, hãy đảm bảo các gói tin hệ thống đã được cập nhật.

```bash
sudo apt update
```

### Cài đặt PostgreSQL
Cài đặt PostgreSQL và các gói hỗ trợ.

```bash
sudo apt install postgresql postgresql-contrib -y
```

### Quản lý Service PostgreSQL
Khởi động, bật chế độ tự khởi động cùng hệ thống và kiểm tra trạng thái.

```text
# Khởi động PostgreSQL
sudo systemctl start postgresql

# Tự khởi động khi reboot (Enable)
sudo systemctl enable postgresql

# Kiểm tra trạng thái hoạt động
sudo systemctl status postgresql
```

---

## 2. Thiết lập Mật khẩu và Truy cập Cơ bản

### Đăng nhập vào tài khoản hệ thống `postgres`
```bash
sudo -i -u postgres
```

### Truy cập giao diện dòng lệnh (CLI) của PostgreSQL
```bash
psql
```

### Đặt mật khẩu mới cho user mặc định `postgres`
Lệnh này thực hiện bên trong giao diện `postgres=#`.
```sql
\password postgres
```

### Thoát khỏi PostgreSQL
```sql
\q
```

### Thoát khỏi user hệ thống `postgres`
```bash
exit
```

---

## 3. Tạo và Cấu hình Swap (Bộ nhớ ảo)
Swap giúp hệ thống hoạt động ổn định hơn khi RAM bị đầy.

### Tạo file Swap (2GB)
```bash
sudo fallocate -l 2G /swapfile
```

### Phân quyền bảo mật (Chỉ root được đọc/ghi)
```bash
sudo chmod 600 /swapfile
```

### Thiết lập vùng Swap
```bash
sudo mkswap /swapfile
```

### Kích hoạt Swap ngay lập tức
```bash
sudo swapon /swapfile
```

### Giữ cấu hình sau khi khởi động lại (Reboot)
Thêm cấu hình vào file `/etc/fstab`.
```text
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Cấu hình Swappiness
Đặt mức độ ưu tiên sử dụng Swap về 10 (Mặc định là 60 - hệ thống sẽ ưu tiên dùng RAM thật hơn).

```text
# Cấu hình tạm thời
sudo sysctl vm.swappiness=10

# Cấu hình vĩnh viễn (Lưu vào sysctl.conf)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

---

## 4. Quản lý User và Database trong PostgreSQL

### Kiểm tra danh sách User/Role hiện có
Bạn có thể chạy lệnh này từ terminal (không cần vào psql shell).
```text
sudo -u postgres psql -c "\du"
```

### Tạo User và Database mới
Truy cập vào `psql` (bằng quyền root hoặc user postgres) và chạy các lệnh SQL sau:

```text
-- 1. Tạo User mới với mật khẩu
CREATE USER [người dùng] WITH PASSWORD '[mật khẩu]';

-- 2. Tạo Database và gán chủ sở hữu (Owner)
CREATE DATABASE db OWNER [người dùng];

-- 3. Cấp tất cả quyền trên Database cho User
GRANT ALL PRIVILEGES ON DATABASE db TO [người dùng];
```

---

## 5. Quản lý User Hệ thống (Linux User)

### Tạo User mới trên Linux
```text
sudo adduser [người dùng]
```

### Cấp quyền Sudo (Admin) cho User mới
```text
sudo usermod -aG sudo [người dùng]
```

### Kiểm tra user đã được tạo hay chưa
```text
cat /etc/passwd | grep [người dùng]
```

---

## 6. Các lệnh thao tác thường dùng trong PostgreSQL

### Truy cập vào một Database cụ thể
```bash
psql -d db
```

### Các lệnh tắt (Meta-commands) bên trong `psql`

| Lệnh | Mô tả |
| :--- | :--- |
| `\dt` | Liệt kê danh sách các bảng (Tables) trong database hiện tại. |
| `\d users` | Xem cấu trúc chi tiết (schema) của bảng `users`. |
| `\l` | Liệt kê tất cả các Database. |
| `\du` | Liệt kê tất cả các Users/Roles. |
| `\q` | Thoát khỏi giao diện psql. |

---

## 7. Cho phép truy cập từ xa (Remote Access)

1. Chỉnh sửa file cấu hình chính:
    ```text
    sudo nano /etc/postgresql/14/main/postgresql.conf
    ```

2. Tìm dòng #listen_addresses = 'localhost' và sửa thành:
    ```text
    listen_addresses = '*'
    ```

3. Chỉnh sửa quyền truy cập (pg_hba.conf):
    ```bash
    sudo nano /etc/postgresql/14/main/pg_hba.conf
    ```
    #### Kéo xuống cuối file, thêm dòng sau vào cuối cùng:
    ```bash
    host    all             all             0.0.0.0/0            md5
    ```
    *Nhấn Ctrl+O, Enter để lưu và Ctrl+X để thoát.*
4. Khởi động lại PostgreSQL:
    ```bash
    sudo systemctl restart postgresql
    ```
---

## 8. Lưu ý khi thoát SSH/Terminal (`exit`)

Khi bạn gõ lệnh `exit` để đăng xuất, đôi khi sẽ gặp thông báo sau:

```text
[người dùng]@[người dùng]:~$ exit
logout
There are stopped jobs.
```

### Nguyên nhân
Hệ thống cảnh báo rằng bạn còn các tiến trình (jobs) đang bị **tạm dừng** (thường do bạn lỡ bấm `Ctrl + Z` trước đó) nhưng chưa được tắt hẳn. Shell (Bash) ngăn bạn thoát ngay để tránh làm mất dữ liệu của các tiến trình này.

### Cách xử lý

1.  **Xem danh sách tiến trình đang treo:**
    ```text
    jobs
    ```
    *(Kết quả ví dụ: `[1]+ Stopped nano file.txt`)*

2.  **Khôi phục lại job để làm việc tiếp:**
    ```text
    fg %1
    ```
    *(Thay số `1` bằng ID của job hiển thị trong lệnh jobs)*.

3.  **Tắt hẳn job đó đi:**
    ```text
    kill %1
    ```

4.  **Vẫn muốn thoát ngay lập tức:**
    Gõ `exit` thêm một lần nữa. Hệ thống sẽ cưỡng chế tắt các tiến trình đang treo và ngắt kết nối.

---

## 9. Cài đặt Web Server và Bảo mật SSL

1. Cài đặt Web Server (Nginx)
    ```bash
    sudo apt install nginx -y
    ```
2. Cài đặt SSL (HTTPS) miễn phí với Certbot
    ```bash
    sudo apt install certbot python3-certbot-nginx -y
    ```
    *Cài đặt Certbot và plugin hỗ trợ cho Nginx.*

3. Kích hoạt SSL cho Domain
    ```bash
    sudo certbot --nginx -d nnanthanh.site -d www.nnanthanh.site
    ```
    *Lệnh này sẽ tự động xin chứng chỉ và cấu hình Nginx.*

---

# TÀI LIỆU KỸ THUẬT: HỆ THỐNG ĐIỂM DANH SINH VIÊN

## 1. TỔNG QUAN HẠ TẦNG & KIẾN TRÚC HỆ THỐNG

**1. Hạ tầng Server (VPS)**
    
Cấu hình
```text
Ubuntu 22.04 (64bit) | 1 CPU | 1 GB RAM | 20 GB SSD.
```

**Bộ nhớ mở rộng:**
Đã kích hoạt Swap File (RAM ảo) 2GB để hỗ trợ xử lý tác vụ nặng.

**Domain:** [nnanthanh.site](https://nnanthanh.site)

**Web Server & Reverse Proxy:**
Nginx (Quản lý luồng truy cập, Rate Limiting, SSL/TLS).

**SSL:**
Let's Encrypt (Certbot) cho giao thức HTTPS.

**Database:**
PostgreSQL (Lưu trữ dữ liệu quan hệ).

---

**2. Kiến trúc Phần mềm**
Hệ thống sử dụng Mô hình Client-Server tách biệt (Decoupled Architecture), giao tiếp qua RESTful API.

**Backend:**
Python (FastAPI Framework) - Xử lý logic, API, Async I/O.

**Frontend:**
Vue.js (Single Page Application - SPA) - Giao diện quản trị.

**Hardware Client:**
Raspberry Pi + Cảm biến AS608.

**Mobile App (Future):**
Android/iOS sẽ tái sử dụng API của Backend.

---

**3. Luồng dữ liệu (Data Flow)**

**Phần cứng:**
Raspberry Pi quét vân tay từ AS608 $\rightarrow$ Xử lý sơ bộ $\rightarrow$ Gửi request (JSON gồm ID thiết bị + Template vân tay) kèm chữ ký bảo mật tới API.

**Backend:**
FastAPI xác thực Header/Token $\rightarrow$ Xử lý logic nghiệp vụ $\rightarrow$ Tương tác Database.

**Database:**
PostgreSQL thực hiện truy vấn/lưu trữ $\rightarrow$ Trả kết quả về Backend.

**Frontend:**
Web Admin gọi API lấy danh sách điểm danh $\rightarrow$ Hiển thị dữ liệu realtime hoặc reload.

---

## 2. GIẢI PHÁP KỸ THUẬT CHO HIỆU NĂNG VÀ BẢO MẬT

Với cấu hình VPS 1 CPU/1GB RAM và yêu cầu xử lý 100 requests đồng thời, hệ thống áp dụng các giải pháp sau:

**1. Tối ưu Hiệu năng (Performance Optimization)**

**Xử lý Bất đồng bộ (Asynchronous):**
Backend sử dụng FastAPI (async/await). 100 request sẽ không block CPU mà được xếp hàng xử lý trong Event Loop, phù hợp với kiến trúc đơn nhân.

**Connection Pooling (SQLAlchemy):**
Không mở mới connection cho mỗi request. Sử dụng Pool size (giới hạn 5-10 kết nối thường trực) để tránh tràn RAM DB.

**Rate Limiting (Nginx):**
Cấu hình giới hạn request để chống DDoS/Spam từ phần cứng bị lỗi.
```text
Config: limit_req_zone $binary_remote_addr zone=api_limit:10m rate=5r/s;
```

**2. Cơ chế Bảo mật (Security Protocol)**

**Hardware Authentication:**
Raspberry Pi phải gửi kèm X-API-KEY trong Header. Server từ chối mọi request không có Key hợp lệ.

**Anti-Replay Attack:**
Gói tin JSON từ Pi phải bao gồm timestamp. Server kiểm tra: |Server_Time - Request_Time| < 30s. Nếu quá hạn $\rightarrow$ Từ chối.

**Input Validation:**
Sử dụng Pydantic (trong FastAPI) để validate dữ liệu đầu vào, loại bỏ hoàn toàn SQL Injection.

---

## 3. QUY ĐỊNH MÔ HÌNH VÀ CẤU TRÚC THƯ MỤC

Đây là kiến trúc chuẩn được chỉ định cho dự án, yêu cầu tuân thủ để đảm bảo tính mở rộng (Scalability) và bảo trì (Maintainability).

**1. BACKEND (PYTHON - FASTAPI)**

**Mô hình:**
Layered Architecture (Kiến trúc phân tầng). Kiến trúc này tách biệt rõ ràng giữa việc định nghĩa API, xử lý nghiệp vụ và truy xuất dữ liệu.

Cấu trúc thư mục tham khảo:
```text
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # Entry point của ứng dụng (Khởi tạo FastAPI app)
│   ├── api/                 # Chứa các Controller (Routes)
│   │   ├── __init__.py
│   │   ├── endpoints/       # Chia nhỏ API theo module
│   │   │   ├── auth.py      # API đăng nhập/đăng xuất
│   │   │   ├── users.py     # API quản lý sinh viên
│   │   │   ├── attendance.py# API nhận dữ liệu điểm danh
│   │   │   └── device.py    # API giao tiếp với Raspberry Pi
│   │   └── router.py        # Gom nhóm các router
│   ├── core/                # Cấu hình cốt lõi
│   │   ├── config.py        # Biến môi trường, cấu hình DB url
│   │   ├── security.py      # Logic Hash password, JWT token
│   │   └── exceptions.py    # Custom error handling
│   ├── db/                  # Tầng cơ sở dữ liệu
│   │   ├── base.py          # Import tất cả models
│   │   └── session.py       # Config SQLAlchemy Session & Engine
│   ├── models/              # Định nghĩa các Table (SQLAlchemy ORM Class)
│   │   ├── user.py
│   │   ├── attendance.py
│   │   └── ...
│   ├── schemas/             # Pydantic Models (Validation input/output JSON)
│   │   ├── user_schema.py
│   │   ├── token_schema.py
│   │   └── device_schema.py
│   └── services/            # Business Logic Layer (Xử lý nghiệp vụ phức tạp)
│       ├── user_service.py
│       └── attendance_service.py
├── .env                     # File chứa biến môi trường (DB_PASS, SECRET_KEY)
├── requirements.txt         # Danh sách thư viện
└── Dockerfile               # (Tùy chọn) Để đóng gói
```

---

**2. FRONTEND (VUE.JS)**

**Mô hình:**
Component-Based Architecture (Kiến trúc hướng thành phần) kết hợp với Modular Store (Pinia). Sử dụng Vue 3 (Composition API) để code gọn gàng và dễ tái sử dụng.

Cấu trúc thư mục tham khảo:
```text
frontend/
├── public/                  # File tĩnh (favicon, index.html)
├── src/
│   ├── assets/              # CSS, Images, Fonts
│   │   ├── main.css
│   │   └── logo.png
│   ├── components/          # Các thành phần giao diện nhỏ (Reusable)
│   │   ├── common/          # Button, Input, Modal, Table dùng chung
│   │   │   ├── BaseButton.vue
│   │   │   └── BaseTable.vue
│   │   └── layout/          # Header, Sidebar, Footer
│   │       ├── TheSidebar.vue
│   │       └── TheHeader.vue
│   ├── views/               # Các trang chính (Pages)
│   │   ├── Dashboard.vue
│   │   ├── Login.vue
│   │   ├── StudentList.vue
│   │   └── AttendanceHistory.vue
│   ├── router/              # Cấu hình Vue Router (Điều hướng trang)
│   │   └── index.js
│   ├── stores/              # Quản lý trạng thái (State Management - Pinia)
│   │   ├── auth.js          # Lưu trạng thái đăng nhập
│   │   └── attendance.js    # Lưu dữ liệu điểm danh tạm thời
│   ├── services/            # Tầng giao tiếp API (Axios configurations)
│   │   ├── api.js           # Cấu hình Axios instance (Base URL, Interceptors)
│   │   ├── authService.js
│   │   └── studentService.js
│   ├── utils/               # Các hàm tiện ích (Format date, validate)
│   │   └── validators.js
│   ├── App.vue              # Root Component
│   └── main.js              # Entry point (Mount Vue app)
├── .env                     # Biến môi trường Frontend (API_URL)
├── package.json             # Quản lý thư viện JS
└── vite.config.js           # Cấu hình build tool Vite
```

---

## 4. Cấu trúc bảng trong db

```text
    table_name    |     column_name      |     data_type     | is_nullable | column_default
------------------+----------------------+-------------------+-------------+----------------
 account          | username             | character varying | NO          |
 account          | password             | character varying | NO          |
 account          | role                 | integer           | NO          |
 account          | user_id              | character varying | YES         |
 attendance       | attendance_id        | character varying | NO          |
 attendance       | user_id              | character varying | YES         |
 attendance       | subject_id           | character varying | YES         |
 attendance       | class_id             | character varying | YES         |
 attendance       | attendance_date      | date              | YES         |
 attendance       | attendance_status    | integer           | YES         |
 class            | class_id             | character varying | NO          |
 class            | major_id             | character varying | YES         |
 class            | class_name           | character varying | YES         |
 class            | course               | character varying | YES         |
 class            | enrollment_year      | integer           | YES         |
 education_level  | education_level_id   | character varying | NO          |
 education_level  | education_level_name | character varying | NO          |
 faculty          | faculty_id           | character varying | NO          |
 faculty          | faculty_name         | character varying | NO          |
 fingerprint      | fingerprint_id       | character varying | NO          |
 fingerprint      | user_id              | character varying | YES         |
 fingerprint      | class_id             | character varying | YES         |
 major            | major_id             | character varying | NO          |
 major            | faculty_id           | character varying | YES         |
 major            | major_name           | character varying | NO          |
 personal_profile | student_id           | character varying | NO          |
 personal_profile | faculty_id           | character varying | YES         |
 personal_profile | class_id             | character varying | YES         |
 personal_profile | education_level_id   | character varying | YES         |
 personal_profile | major_id             | character varying | YES         |
 personal_profile | date_of_birth        | date              | YES         |
 personal_profile | gender               | integer           | YES         |
 personal_profile | place_of_birth       | character varying | YES         |
 personal_profile | permanent_address    | text              | YES         |
 personal_profile | temporary_address    | text              | YES         |
 personal_profile | phone_number         | character varying | YES         |
 room             | room_id              | character varying | NO          |
 room             | room_name            | character varying | NO          |
 schedule         | schedule_id          | character varying | NO          |
 schedule         | subject_id           | character varying | YES         |
 schedule         | room_id              | character varying | YES         |
 schedule         | user_id              | character varying | YES         |
 schedule         | schedule_date        | date              | YES         |
 schedule         | group_name           | character varying | YES         |
 schedule         | start                | integer           | YES         |
 schedule         | out                  | integer           | YES         |
 student_group    | group_id             | character varying | NO          |
 student_group    | user_id              | character varying | NO          |
 subject          | subject_id           | character varying | NO          |
 subject          | subject_name         | character varying | NO          |
 subject          | credits              | integer           | NO          |
 subject          | theory               | integer           | NO          |
 subject          | practice             | integer           | NO          |
 subject          | semester             | integer           | NO          |
 users            | user_id              | character varying | NO          |
 users            | faculty_id           | character varying | YES         |
 users            | class_id             | character varying | YES         |
 users            | full_name            | character varying | NO          |
```

---

## 5. Github

**1. Tạo repository trên [github](https://github.com/new)**

**2. Quy trình upload dự án lên github**
Dựng file gitignore bỏ qua các file chỉ định
Dựng ssh nếu chưa có
Kiểm tra ssh
```git
ls -al ~/.ssh
```

Tạo SSH Key mới
```git
ssh-keygen -t ed25519 -C "[nhập email]"
```

Mở SSH Key
```git
cat ~/.ssh/id_ed25519.pub
```

Thêm SSH Key vào [github](https://github.com/settings/ssh/new)

Commit lần đầu yêu cầu cấu hình tài khoản
```git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

Quy trình upload
```git
git init
git branch -M main
git add [tên file/.]
git commit -m "first commit"
git status
git remote add origin git@github.com:[username]/[link github]
git remote -v
git push -u origin main
```

Kiểm tra kết nối và Push
```git
ssh -T git@github.com
```

---