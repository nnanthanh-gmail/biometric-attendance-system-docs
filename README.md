# TÀI LIỆU KỸ THUẬT: HỆ THỐNG ĐIỂM DANH SINH VIÊN

## MỤC LỤC

1. [Tổng quan Hạ tầng & Kiến trúc Hệ thống](#1-tổng-quan-hạ-tầng--kiến-trúc-hệ-thống)
2. [Giải pháp Kỹ thuật cho Hiệu năng và Bảo mật](#2-giải-pháp-kỹ-thuật-cho-hiệu-năng-và-bảo-mật)
3. [Quy định Mô hình và Cấu trúc Thư mục](#3-quy-định-mô-hình-và-cấu-trúc-thư-mục)
4. [Cài đặt và Cấu hình PostgreSQL](#4-cài-đặt-và-cấu-hình-postgresql)
5. [Cài đặt Backend (FastAPI)](#5-cài-đặt-backend-fastapi)
6. [Cài đặt Web Server và SSL](#6-cài-đặt-web-server-và-ssl)
7. [Quản lý Mã nguồn với Git](#7-quản-lý-mã-nguồn-với-git)

---

## 1. TỔNG QUAN HẠ TẦNG & KIẾN TRÚC HỆ THỐNG

### 1.1. Hạ tầng Server (VPS)

**Cấu hình:**
```text
Ubuntu 22.04 (64bit) | 1 CPU | 1 GB RAM | 20 GB SSD
```

**Bộ nhớ mở rộng:**  
Đã kích hoạt Swap File (RAM ảo) 2GB để hỗ trợ xử lý tác vụ nặng.

**Domain:** [nnanthanh.site](https://nnanthanh.site)

**Web Server & Reverse Proxy:**  
Nginx - Quản lý luồng truy cập, Rate Limiting, SSL/TLS.

**SSL:**  
Let's Encrypt (Certbot) cho giao thức HTTPS.

**Database:**  
PostgreSQL - Lưu trữ dữ liệu quan hệ.

---

### 1.2. Kiến trúc Phần mềm

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

### 1.3. Luồng dữ liệu (Data Flow)

**Phần cứng:**  
Raspberry Pi quét vân tay từ AS608 → Xử lý sơ bộ → Gửi request (JSON gồm ID thiết bị + Template vân tay) kèm chữ ký bảo mật tới API.

**Backend:**  
FastAPI xác thực Header/Token → Xử lý logic nghiệp vụ → Tương tác Database.

**Database:**  
PostgreSQL thực hiện truy vấn/lưu trữ → Trả kết quả về Backend.

**Frontend:**  
Web Admin gọi API lấy danh sách điểm danh → Hiển thị dữ liệu realtime hoặc reload.

---

## 2. GIẢI PHÁP KỸ THUẬT CHO HIỆU NĂNG VÀ BẢO MẬT

Với cấu hình VPS 1 CPU/1GB RAM và yêu cầu xử lý 100 requests đồng thời, hệ thống áp dụng các giải pháp sau:

### 2.1. Tối ưu Hiệu năng (Performance Optimization)

**Xử lý Bất đồng bộ (Asynchronous):**  
Backend sử dụng FastAPI (async/await). 100 request sẽ không block CPU mà được xếp hàng xử lý trong Event Loop, phù hợp với kiến trúc đơn nhân.

**Connection Pooling (SQLAlchemy):**  
Không mở mới connection cho mỗi request. Sử dụng Pool size (giới hạn 5-10 kết nối thường trực) để tránh tràn RAM DB.

**Rate Limiting (Nginx):**  
Cấu hình giới hạn request để chống DDoS/Spam từ phần cứng bị lỗi.
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=5r/s;
```

---

### 2.2. Cơ chế Bảo mật (Security Protocol)

**Hardware Authentication:**  
Raspberry Pi phải gửi kèm X-API-KEY trong Header. Server từ chối mọi request không có Key hợp lệ.

**Anti-Replay Attack:**  
Gói tin JSON từ Pi phải bao gồm timestamp. Server kiểm tra: `|Server_Time - Request_Time| < 30s`. Nếu quá hạn → Từ chối.

**Input Validation:**  
Sử dụng Pydantic (trong FastAPI) để validate dữ liệu đầu vào, loại bỏ hoàn toàn SQL Injection.

---

## 3. QUY ĐỊNH MÔ HÌNH VÀ CẤU TRÚC THƯ MỤC

Đây là kiến trúc chuẩn được chỉ định cho dự án, yêu cầu tuân thủ để đảm bảo tính mở rộng (Scalability) và bảo trì (Maintainability).

### 3.1. BACKEND (PYTHON - FASTAPI)

**Mô hình:**  
Layered Architecture (Kiến trúc phân tầng). Kiến trúc này tách biệt rõ ràng giữa việc định nghĩa API, xử lý nghiệp vụ và truy xuất dữ liệu.

**Repository:** [biometric-attendance-system-backend](https://github.com/nnanthanh-gmail/biometric-attendance-system-backend)

**Cấu trúc thư mục:**
```text
backend/
├── app/
│   ├── main.py                    # Entry point của ứng dụng FastAPI
│   ├── api/
│   │   ├── deps.py               # Dependencies injection
│   │   ├── router.py             # Tổng hợp các router
│   │   └── endpoints/            # API endpoints theo module
│   │       ├── account.py
│   │       ├── attendance.py
│   │       ├── class_room.py
│   │       ├── device.py
│   │       ├── faculty.py
│   │       ├── lecturer_profile.py
│   │       ├── room.py
│   │       ├── schedule.py
│   │       ├── student_profile.py
│   │       ├── subject.py
│   │       └── users.py
│   ├── core/
│   │   └── config.py             # Cấu hình hệ thống (Database, Secret Key)
│   ├── db/
│   │   ├── base.py               # Base class cho models
│   │   └── session.py            # Database session & connection pool
│   ├── models/                   # SQLAlchemy ORM Models
│   │   ├── __init__.py
│   │   ├── account.py
│   │   ├── attendance.py
│   │   ├── class_model.py
│   │   ├── course_registration.py
│   │   ├── education_level.py
│   │   ├── faculty.py
│   │   ├── fingerprint.py
│   │   ├── lecturer_profile.py
│   │   ├── major.py
│   │   ├── room.py
│   │   ├── schedule.py
│   │   ├── student_profile.py
│   │   ├── subject.py
│   │   └── user.py
│   └── schemas/                  # Pydantic schemas cho validation
│       ├── __init__.py
│       ├── account.py
│       ├── attendance.py
│       ├── attendance_schema.py
│       ├── class_schema.py
│       ├── course_registration.py
│       ├── education_level.py
│       ├── faculty.py
│       ├── fingerprint.py
│       ├── lecturer_profile.py
│       ├── major.py
│       ├── room.py
│       ├── schedule.py
│       ├── student_profile.py
│       ├── subject.py
│       └── user.py
├── .env                          # Biến môi trường (Database URL, Secret)
├── .gitignore                    # Loại trừ file nhạy cảm khỏi Git
└── requirements.txt              # Danh sách thư viện Python
```

---

### 3.2. FRONTEND (VUE.JS)

**Mô hình:**  
Component-Based Architecture (Kiến trúc hướng thành phần) kết hợp với Modular Store (Pinia). Sử dụng Vue 3 (Composition API).

**Cấu trúc thư mục:**
```text
frontend/
├── public/                       # File tĩnh (favicon, index.html)
├── src/
│   ├── assets/                   # CSS, Images, Fonts
│   │   ├── main.css
│   │   └── logo.png
│   ├── components/               # Các thành phần giao diện nhỏ (Reusable)
│   │   ├── common/               # Button, Input, Modal, Table dùng chung
│   │   │   ├── base_button.vue
│   │   │   └── base_table.vue
│   │   └── layout/               # Header, Sidebar, Footer
│   │       ├── the_sidebar.vue
│   │       └── the_header.vue
│   ├── views/                    # Các trang chính (Pages)
│   │   ├── dashboard.vue
│   │   ├── login.vue
│   │   ├── student_list.vue
│   │   └── attendance_history.vue
│   ├── router/                   # Cấu hình Vue Router (Điều hướng trang)
│   │   └── index.js
│   ├── stores/                   # Quản lý trạng thái (State Management - Pinia)
│   │   ├── auth.js               # Lưu trạng thái đăng nhập
│   │   └── attendance.js         # Lưu dữ liệu điểm danh tạm thời
│   ├── services/                 # Tầng giao tiếp API (Axios configurations)
│   │   ├── api.js                # Cấu hình Axios instance (Base URL, Interceptors)
│   │   ├── auth_service.js
│   │   └── student_service.js
│   ├── utils/                    # Các hàm tiện ích (Format date, validate)
│   │   └── validators.js
│   ├── App.vue                   # Root Component
│   └── main.js                   # Entry point (Mount Vue app)
├── .env                          # Biến môi trường Frontend (API_URL)
├── package.json                  # Quản lý thư viện JS
└── vite.config.js                # Cấu hình build tool Vite
```

---

## 4. CÀI ĐẶT VÀ CẤU HÌNH POSTGRESQL

### 4.1. Cài đặt và Khởi chạy PostgreSQL

**Cập nhật hệ thống:**
```bash
sudo apt update
```

**Cài đặt PostgreSQL:**
```bash
sudo apt install postgresql postgresql-contrib -y
```

**Quản lý Service PostgreSQL:**
```bash
# Khởi động PostgreSQL
sudo systemctl start postgresql

# Tự khởi động khi reboot
sudo systemctl enable postgresql

# Kiểm tra trạng thái
sudo systemctl status postgresql
```

---

### 4.2. Thiết lập Mật khẩu và Truy cập

**Đăng nhập vào tài khoản hệ thống `postgres`:**
```bash
sudo -i -u postgres
```

**Truy cập giao diện dòng lệnh (CLI) của PostgreSQL:**
```bash
psql
```

**Đặt mật khẩu cho user mặc định `postgres`:**
```sql
\password postgres
```

**Thoát khỏi PostgreSQL:**
```sql
\q
```

**Thoát khỏi user hệ thống `postgres`:**
```bash
exit
```

---

### 4.3. Tạo và Cấu hình Swap (Bộ nhớ ảo)

Swap giúp hệ thống hoạt động ổn định hơn khi RAM bị đầy.

**Tạo file Swap (2GB):**
```bash
sudo fallocate -l 2G /swapfile
```

**Phân quyền bảo mật:**
```bash
sudo chmod 600 /swapfile
```

**Thiết lập vùng Swap:**
```bash
sudo mkswap /swapfile
```

**Kích hoạt Swap:**
```bash
sudo swapon /swapfile
```

**Giữ cấu hình sau khi khởi động lại:**
```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Cấu hình Swappiness:**
```bash
# Cấu hình tạm thời
sudo sysctl vm.swappiness=10

# Cấu hình vĩnh viễn
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

---

### 4.4. Quản lý User và Database

**Kiểm tra danh sách User/Role:**
```bash
sudo -u postgres psql -c "\du"
```

**Tạo User và Database mới:**
```sql
-- Tạo User mới với mật khẩu
CREATE USER [người_dùng] WITH PASSWORD '[mật_khẩu]';

-- Tạo Database và gán chủ sở hữu
CREATE DATABASE db OWNER [người_dùng];

-- Cấp tất cả quyền trên Database
GRANT ALL PRIVILEGES ON DATABASE db TO [người_dùng];
```

---

### 4.5. Cho phép truy cập từ xa (Remote Access)

**Chỉnh sửa file cấu hình chính:**
```bash
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Tìm dòng `#listen_addresses = 'localhost'` và sửa thành:
```text
listen_addresses = '*'
```

**Chỉnh sửa quyền truy cập:**
```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Thêm dòng sau vào cuối file:
```text
host    all             all             0.0.0.0/0            md5
```

**Khởi động lại PostgreSQL:**
```bash
sudo systemctl restart postgresql
```

---

### 4.6. Cấu trúc Database

**Sơ đồ Database:** [biometric_attendance_system](https://dbdiagram.io/d/biometric_attendance_system-69671f14d6e030a024fa19f5)

**Lấy thông tin các bảng:**
```sql
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable,
    character_maximum_length AS max_len
FROM 
    information_schema.columns 
WHERE 
    table_schema = 'public'
ORDER BY 
    table_name, 
    ordinal_position;
```

**Kết quả**
```text
     table_name      |  column_name   |        data_type         | is_nullable | max_len
---------------------+----------------+--------------------------+-------------+---------
 account             | user_id        | varchar                  | NO          |      32
 account             | password_hash  | varchar                  | NO          |     255
 account             | role           | character                | NO          |       1
 attendance          | attend_id      | int                      | NO          |
 attendance          | schedule_id    | int                      | NO          |
 attendance          | user_id        | varchar                  | NO          |      32
 attendance          | attend_time    | timestamp                | NO          |
 attendance          | status         | boolean                  | NO          |
 class               | class_id       | varchar                  | NO          |      20
 class               | major_id       | varchar                  | NO          |      20
 class               | edu_level_id   | varchar                  | NO          |      20
 class               | class_name     | text                     | NO          |
 class               | course         | varchar                  | NO          |      10
 class               | enroll_year    | smallint                 | NO          |
 course_registration | reg_id         | int                      | NO          |
 course_registration | user_id        | varchar                  | NO          |      32
 course_registration | subject_id     | varchar                  | NO          |      20
 course_registration | host_class_id  | varchar                  | NO          |      20
 course_registration | semester       | smallint                 | NO          |
 course_registration | year           | smallint                 | NO          |
 course_registration | created_at     | timestamp                | NO          |
 education_level     | edu_level_id   | varchar                  | NO          |      20
 education_level     | edu_level_name | text                     | NO          |
 faculty             | faculty_id     | varchar                  | NO          |      20
 faculty             | faculty_name   | text                     | NO          |
 fingerprint         | finger_id      | varchar                  | NO          |      32
 fingerprint         | user_id        | varchar                  | NO          |      32
 fingerprint         | finger_data    | bytea                    | NO          |
 lecturer_profile    | user_id        | varchar                  | NO          |      32
 lecturer_profile    | faculty_id     | varchar                  | NO          |      20
 lecturer_profile    | degree         | text                     | NO          |
 lecturer_profile    | research_area  | text                     | YES         |
 major               | major_id       | varchar                  | NO          |      20
 major               | faculty_id     | varchar                  | NO          |      20
 major               | major_name     | text                     | NO          |
 room                | room_id        | varchar                  | NO          |      20
 room                | room_name      | text                     | NO          |
 schedule            | schedule_id    | int                      | NO          |
 schedule            | subject_id     | varchar                  | NO          |      20
 schedule            | room_id        | varchar                  | NO          |      20
 schedule            | lecturer_id    | varchar                  | NO          |      32
 schedule            | class_id       | varchar                  | NO          |      20
 schedule            | learn_date     | date                     | NO          |
 schedule            | start_period   | smallint                 | NO          |
 schedule            | end_period     | smallint                 | NO          |
 schedule            | is_open        | boolean                  | NO          |
 student_profile     | user_id        | varchar                  | NO          |      32
 student_profile     | birth_date     | date                     | NO          |
 student_profile     | gender         | boolean                  | NO          |
 student_profile     | phone          | varchar                  | NO          |      15
 student_profile     | address        | text                     | NO          |
 subject             | subject_id     | varchar                  | NO          |      20
 subject             | subject_name   | text                     | NO          |
 subject             | credits        | smallint                 | NO          |
 subject             | theory         | smallint                 | NO          |
 subject             | practice       | smallint                 | NO          |
 subject             | semester       | smallint                 | NO          |
 users               | user_id        | varchar                  | NO          |      32
 users               | class_id       | varchar                  | YES         |      20
 users               | full_name      | text                     | NO          |
(60 rows)
```

**Các lệnh thao tác thường dùng trong `psql`:**

| Lệnh | Mô tả |
|:-----|:------|
| `\dt` | Liệt kê danh sách các bảng (Tables) |
| `\d users` | Xem cấu trúc chi tiết của bảng `users` |
| `\l` | Liệt kê tất cả các Database |
| `\du` | Liệt kê tất cả các Users/Roles |
| `\q` | Thoát khỏi giao diện psql |

---

### 4.7. Ràng buộc toàn vẹn dữ liệu

**Khóa chính (Primary Key - PK):**
```sql
CONSTRAINT pk_faculty PRIMARY KEY (faculty_id)
```

**Khóa ngoại (Foreign Key - FK):**
```sql
CONSTRAINT fk_major_faculty FOREIGN KEY (faculty_id) 
    REFERENCES faculty(faculty_id)
```

**Cascade Delete (Xóa tầng):**
```sql
CONSTRAINT fk_sp_users FOREIGN KEY (user_id) 
    REFERENCES users(user_id) ON DELETE CASCADE
```

---

## 5. CÀI ĐẶT BACKEND (FASTAPI)

### 5.1. Yêu cầu hệ thống

- Python 3.8+
- PostgreSQL 12+
- Git

---

### 5.2. Clone Repository từ GitHub

```bash
# Di chuyển đến thư mục dự án
cd /path/to/project

# Clone repository
git clone git@github.com:nnanthanh-gmail/biometric-attendance-system-backend.git

# Di chuyển vào thư mục backend
cd biometric-attendance-system-backend
```

---

### 5.3. Tạo và Kích hoạt Virtual Environment

**Tạo virtual environment:**
```bash
python3 -m venv venv
```

**Kích hoạt virtual environment:**
```bash
# Linux/Mac
source venv/bin/activate

# Windows
venv\Scripts\activate
```

---

### 5.4. Cài đặt Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Danh sách thư viện chính:**
- `fastapi` - Web framework
- `uvicorn[standard]` - ASGI server
- `sqlalchemy` - ORM
- `psycopg2-binary` - PostgreSQL driver
- `pydantic` - Data validation
- `python-jose[cryptography]` - JWT authentication
- `passlib[bcrypt]` - Password hashing
- `python-multipart` - Form data handling

---

### 5.5. Cấu hình Biến môi trường (.env)

Tạo file `.env` trong thư mục gốc của backend:

```bash
nano .env
```

Nội dung file `.env`:
```env
# Database Configuration
DATABASE_URL=postgresql+asyncpg://[người_dùng]:[mật_khẩu]@localhost:db

# Security
SECRET_KEY=your-secret-key-here-change-this-in-production

# Hardware Authentication
HARDWARE_API_KEY=your-hardware-api-key-here

# Admin
ADMIN_USERNAME=username
```

**Tạo SECRET_KEY ngẫu nhiên:**
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

### 5.6. Khởi tạo Database Schema

**Chạy migrations (nếu có sử dụng Alembic):**
```bash
alembic upgrade head
```

**Hoặc tạo bảng trực tiếp từ models:**
```python
# Chạy script Python để tạo bảng
python -c "from app.db.base import Base; from app.db.session import engine; Base.metadata.create_all(bind=engine)"
```

---

### 5.7. Chạy Development Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Kiểm tra API đang hoạt động:**
```bash
curl http://localhost:8000/api/[table_name]
```

**Truy cập API Documentation:**
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

### 5.8. Cấu hình Production với Systemd

Tạo service file để tự động khởi động backend:

```bash
sudo nano /etc/systemd/system/fastapi_app.service
```

Nội dung file:
```ini
[Unit]
# Định danh dịch vụ và quản lý phụ thuộc (Dependency Management)
Description=Uvicorn instance to serve FastAPI
# Đảm bảo lớp mạng (Network Layer) sẵn sàng trước khi khởi chạy
After=network.target

[Service]
# Thiết lập ngữ cảnh bảo mật và quyền truy cập tối thiểu (Least Privilege)
User=[user]
Group=www-data

# Định vị thư mục gốc thực thi ứng dụng (Execution Context)
WorkingDirectory=/home/[user]/biometric_attendance_system/backend

# Cấu hình biến môi trường trỏ tới Python Virtual Environment (Environment Isolation)
Environment="PATH=/home/[user]/biometric_attendance_system/.venv/bin"

# Khởi tạo tiến trình (Process Spawn) và giới hạn tài nguyên (Concurrency Control)
ExecStart=/home/[user]/biometric_attendance_system/.venv/bin/uvicorn app.main:app --workers 1 --host 127.0.0.1 --port 8000

[Install]
# Gắn kết dịch vụ vào quy trình khởi động hệ thống (System Runlevel 3/Multi-user)
WantedBy=multi-user.target
```

**Kích hoạt service:**
```bash
# Reload systemd
sudo systemctl daemon-reload

# Kích hoạt service
sudo systemctl enable fastapi_app

# Khởi động service
sudo systemctl start fastapi_app

# Kiểm tra trạng thái
sudo systemctl status fastapi_app
```

---

### 5.9. Phân quyền thư mục

**Chuyển quyền sở hữu cho user hiện tại:**
```bash
sudo chown -R $USER:$USER /path/to/biometric-attendance-system-backend
```

**Trả lại quyền cho root (nếu cần):**
```bash
sudo chown -R root:root /path/to/biometric-attendance-system-backend
```

---

### 5.10. Logging và Monitoring

**Xem logs của service:**
```bash
# Xem logs realtime
sudo journalctl -u fastapi-backend -f

# Xem logs từ thời điểm cụ thể
sudo journalctl -u fastapi-backend --since "2025-01-01"
```

---

## 6. CÀI ĐẶT WEB SERVER VÀ SSL

### 6.1. Cài đặt Nginx

```bash
sudo apt install nginx -y
```

---

### 6.2. Cấu hình Nginx làm Reverse Proxy

Tạo file cấu hình cho domain:

```bash
sudo nano /etc/nginx/sites-available/nnanthanh.site
```

Nội dung cấu hình:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=5r/s;

server {

    server_name nnanthanh.site www.nnanthanh.site;

    root /var/www/biometric_attendance_system/frontend;

    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/nnanthanh.site/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/nnanthanh.site/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    # --- BLOCK 2: XỬ LÝ API BACKEND ---
    # Chuyển tất cả request bắt đầu bằng /api vào FastAPI
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Áp dụng giới hạn rate limit cho API
        limit_req zone=api_limit burst=10 nodelay;
    }

    # --- BLOCK 3: XỬ LÝ TÀI LIỆU API (SWAGGER UI) ---
    # Chuyển hướng /docs vào FastAPI
    location /docs {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Quan trọng: Swagger UI cần file openapi.json để hiển thị
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

}
server {
    if ($host = www.nnanthanh.site) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    if ($host = nnanthanh.site) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    listen [::]:80;
    server_name nnanthanh.site www.nnanthanh.site;
    return 404; # managed by Certbot

}
```

**Kích hoạt cấu hình:**
```bash
sudo ln -s /etc/nginx/sites-available/nnanthanh.site /etc/nginx/sites-enabled/

# Test cấu hình
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

### 6.3. Cài đặt SSL với Let's Encrypt

```bash
# Cài đặt Certbot
sudo apt install certbot python3-certbot-nginx -y

# Xin chứng chỉ SSL và tự động cấu hình Nginx
sudo certbot --nginx -d nnanthanh.site -d www.nnanthanh.site

# Test tự động gia hạn
sudo certbot renew --dry-run
```

**Khởi động lại Nginx:**
```bash
sudo systemctl restart nginx
```

---

## 7. QUẢN LÝ MÃ NGUỒN VỚI GIT

### 7.1. Cấu hình Git

**Kiểm tra SSH Key:**
```bash
ls -al ~/.ssh
```

**Tạo SSH Key mới:**
```bash
ssh-keygen -t ed25519 -C "[email]"
```

**Mở SSH Key:**
```bash
cat ~/.ssh/id_ed25519.pub
```

**Thêm SSH Key vào GitHub:** [GitHub SSH Settings](https://github.com/settings/ssh/new)

**Kiểm tra kết nối:**
```bash
ssh -T git@github.com
```

---

### 7.2. Cấu hình User Git

```bash
git config --global user.email "email@example.com"
git config --global user.name "Your Name"
```

---

### 7.3. Quy trình Upload dự án

```bash
# Khởi tạo repository
git init

# Tạo nhánh main
git branch -M main

# Thêm file vào staging
git add .

# Commit
git commit -m "first commit"

# Kiểm tra trạng thái
git status

# Thêm remote repository
git remote add origin git@github.com:[username]/[repository].git

# Kiểm tra remote
git remote -v

# Push lên GitHub
git push -u origin main
```

---

### 7.4. File .gitignore

Tạo file `.gitignore` để loại trừ các file nhạy cảm:

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# Environment variables
.env
.env.local

# Database
*.db
*.sqlite3

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db
```

---

## 8. LƯU Ý THAO TÁC TERMINAL

### 8.1. Xử lý "Stopped jobs" khi thoát SSH

Khi gõ lệnh `exit` và gặp thông báo:
```text
There are stopped jobs.
```

**Nguyên nhân:**  
Hệ thống cảnh báo còn các tiến trình đang bị tạm dừng (thường do lỡ bấm `Ctrl + Z`).

**Cách xử lý:**

1. Xem danh sách tiến trình:
```bash
jobs
```

2. Khôi phục lại job:
```bash
fg %1
```

3. Tắt hẳn job:
```bash
kill %1
```

4. Thoát cưỡng chế:
```bash
exit  # Gõ thêm lần nữa
```

---

### 8.2. Quản lý User Hệ thống Linux

**Tạo User mới:**
```bash
sudo adduser [người_dùng]
```

**Cấp quyền Sudo:**
```bash
sudo usermod -aG sudo [người_dùng]
```

**Kiểm tra user đã tồn tại:**
```bash
cat /etc/passwd | grep [người_dùng]
```

---

## PHỤ LỤC: KIỂU DỮ LIỆU POSTGRESQL

### Bảng Tham khảo Kiểu dữ liệu

| Nhóm | Kiểu dữ liệu | Kích thước (Bytes) | Mô tả & Khuyến nghị |
|:-----|:-------------|:-------------------|:--------------------|
| Chuỗi | `CHAR(n)` | n bytes | Chuỗi độ dài cố định. Hạn chế dùng do chậm hơn TEXT/VARCHAR. |
| | `VARCHAR(n)` | n + 1 | Chuỗi biến đổi có giới hạn. Dùng khi cần ràng buộc độ dài. |
| | `TEXT` | Biến đổi + 1 | Chuỗi không giới hạn. **Ưu tiên dùng** cho PostgreSQL. |
| Số nguyên | `SMALLINT` | 2 bytes | -32,768 đến +32,767. Tiết kiệm 50% so với INTEGER. |
| | `INTEGER` | 4 bytes | -2 tỷ đến +2 tỷ. Dùng cho ID tự tăng. |
| | `BIGINT` | 8 bytes | Phạm vi cực lớn. Chỉ dùng khi INTEGER không đủ. |
| | `SERIAL` | 4 bytes | Auto-increment. Thực chất là INTEGER + SEQUENCE. |
| Thời gian | `DATE` | 4 bytes | Chỉ ngày (Năm-Tháng-Ngày). Dùng cho ngày sinh. |
| | `TIMESTAMP` | 8 bytes | Ngày + Giờ (Không múi giờ). Có rủi ro khi chuyển vùng. |
| | `TIMESTAMPTZ` | 8 bytes | Ngày + Giờ + Múi giờ. **Ưu tiên dùng** cho created_at. |
| Logic & Binary | `BOOLEAN` | 1 byte | True/False. Tốt hơn CHAR(1) hay INT(0/1). |
| | `BYTEA` | Biến đổi | Mảng byte. Phù hợp lưu mẫu vân tay hoặc ảnh nhỏ. |

---

## THAM KHẢO

- **Backend Repository:** [biometric-attendance-system-backend](https://github.com/nnanthanh-gmail/biometric-attendance-system-backend)
- **Database Schema:** [dbdiagram.io](https://dbdiagram.io/d/biometric_attendance_system-69671f14d6e030a024fa19f5)
- **FastAPI Documentation:** [fastapi.tiangolo.com](https://fastapi.tiangolo.com)
- **PostgreSQL Documentation:** [postgresql.org/docs](https://www.postgresql.org/docs)
- **Nginx Documentation:** [nginx.org/en/docs](https://nginx.org/en/docs)