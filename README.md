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

### Đã có tài khoản postgresql
```text
psql -U [người dùng] -d postgres
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

# PostgreSQL

**Sơ đồ postgresql:** [biometric_attendance_system](https://dbdiagram.io/d/biometric_attendance_system-69671f14d6e030a024fa19f5)

## 1. Cấu trúc bảng trong db
Lệnh lấy tất cả kiểu dữ liệu trong cơ sở dữ liệu
```text
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

```text
     table_name      |  column_name   |        data_type         | is_nullable | max_len
---------------------+----------------+--------------------------+-------------+---------
 account             | user_id        | character varying        | NO          |      32
 account             | password_hash  | character varying        | NO          |     255
 account             | role           | character                | NO          |       1
 attendance          | attend_id      | integer                  | NO          |
 attendance          | schedule_id    | integer                  | NO          |
 attendance          | user_id        | character varying        | NO          |      32
 attendance          | attend_time    | timestamp with time zone | NO          |
 attendance          | status         | boolean                  | NO          |
 class               | class_id       | character varying        | NO          |      20
 class               | major_id       | character varying        | NO          |      20
 class               | edu_level_id   | character varying        | NO          |      20
 class               | class_name     | text                     | NO          |
 class               | course         | character varying        | NO          |      10
 class               | enroll_year    | smallint                 | NO          |
 course_registration | reg_id         | integer                  | NO          |
 course_registration | user_id        | character varying        | NO          |      32
 course_registration | subject_id     | character varying        | NO          |      20
 course_registration | host_class_id  | character varying        | NO          |      20
 course_registration | semester       | smallint                 | NO          |
 course_registration | year           | smallint                 | NO          |
 course_registration | created_at     | timestamp with time zone | NO          |
 education_level     | edu_level_id   | character varying        | NO          |      20
 education_level     | edu_level_name | text                     | NO          |
 faculty             | faculty_id     | character varying        | NO          |      20
 faculty             | faculty_name   | text                     | NO          |
 fingerprint         | finger_id      | character varying        | NO          |      32
 fingerprint         | user_id        | character varying        | NO          |      32
 fingerprint         | finger_data    | bytea                    | NO          |
 lecturer_profile    | user_id        | character varying        | NO          |      32
 lecturer_profile    | faculty_id     | character varying        | NO          |      20
 lecturer_profile    | degree         | text                     | NO          |
 lecturer_profile    | research_area  | text                     | YES         |
 major               | major_id       | character varying        | NO          |      20
 major               | faculty_id     | character varying        | NO          |      20
 major               | major_name     | text                     | NO          |
 room                | room_id        | character varying        | NO          |      20
 room                | room_name      | text                     | NO          |
 schedule            | schedule_id    | integer                  | NO          |
 schedule            | subject_id     | character varying        | NO          |      20
 schedule            | room_id        | character varying        | NO          |      20
 schedule            | lecturer_id    | character varying        | NO          |      32
 schedule            | class_id       | character varying        | NO          |      20
 schedule            | learn_date     | date                     | NO          |
 schedule            | start_period   | smallint                 | NO          |
 schedule            | end_period     | smallint                 | NO          |
 schedule            | is_open        | boolean                  | NO          |
 student_profile     | user_id        | character varying        | NO          |      32
 student_profile     | birth_date     | date                     | NO          |
 student_profile     | gender         | boolean                  | NO          |
 student_profile     | phone          | character varying        | NO          |      15
 student_profile     | address        | text                     | NO          |
 subject             | subject_id     | character varying        | NO          |      20
 subject             | subject_name   | text                     | NO          |
 subject             | credits        | smallint                 | NO          |
 subject             | theory         | smallint                 | NO          |
 subject             | practice       | smallint                 | NO          |
 subject             | semester       | smallint                 | NO          |
 users               | user_id        | character varying        | NO          |      32
 users               | class_id       | character varying        | YES         |      20
 users               | full_name      | text                     | NO          |
(60 rows)
```

## 2. Kiểu dữ liệu trường
```text
+----------------------------------------------------------------------------------------------------------------------------------+
| Nhóm              | Tên kiểu dữ liệu | Kích thước (Bytes)  | Mô tả & Khuyến nghị Tối ưu                                          |
+-------------------+------------------+---------------------+---------------------------------------------------------------------+
| Chuỗi (String)    | CHAR(n)          | n bytes             | Chuỗi độ dài cố định. Nếu dữ liệu ngắn hơn n, hệ thống sẽ chèn thêm |
|                   |                  |                     | khoảng trắng. Lưu ý: Trong Postgres, CHAR thường chậm hơn TEXT hoặc |
|                   |                  |                     | VARCHAR vì tốn chi phí xử lý khoảng trắng thừa. Hạn chế dùng.       |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | VARCHAR(n)       | n + 1               | Chuỗi độ dài biến đổi có giới hạn. Dùng khi cần ràng buộc độ dài    |
|                   |                  |                     | nghiệp vụ (VD: Mã sinh viên tối đa 20 ký tự).                       |
|                   |                  |                     | Tối ưu: Tốt cho việc đảm bảo tính toàn vẹn dữ liệu (Constraint).    |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | TEXT             | Biến đổi + 1        | Chuỗi độ dài biến đổi không giới hạn.                               |
|                   |                  |                     | Tối ưu: Đây là kiểu dữ liệu chuỗi native và tối ưu nhất của         |
|                   |                  |                     | Postgres. Nếu không cần giới hạn độ dài cứng, hãy ưu tiên dùng TEXT.|
+-------------------+------------------+---------------------+---------------------------------------------------------------------+
| Số nguyên (Int)   | SMALLINT         | 2 bytes             | Phạm vi: -32,768 đến +32,767.                                       |
|                   |                  |                     | Tối ưu: Dùng tốt cho các cột như credits, semester. Tiết kiệm 50%   |
|                   |                  |                     | dung lượng so với INTEGER.                                          |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | INTEGER (INT)    | 4 bytes             | Phạm vi: -2 tỷ đến +2 tỷ.                                           |
|                   |                  |                     | Tối ưu: Dùng cho ID tự tăng hoặc số lượng thông thường.             |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | BIGINT           | 8 bytes             | Phạm vi cực lớn.                                                    |
|                   |                  |                     | Lưu ý: Chỉ dùng khi INTEGER không đủ chứa (VD: ID mạng xã hội).     |
|                   |                  |                     | Dùng thừa sẽ tốn dung lượng ổ cứng và RAM khi đánh index.           |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | SERIAL           | 4 bytes             | Tự động tăng (Auto-increment). Thực chất là tạo một INTEGER và      |
|                   |                  |                     | gắn với một SEQUENCE.                                               |
+-------------------+------------------+---------------------+---------------------------------------------------------------------+
| Thời gian         | DATE             | 4 bytes             | Chỉ chứa ngày (Năm-Tháng-Ngày). Không có giờ.                       |
| (Date/Time)       |                  |                     | Tối ưu: Dùng cho ngày sinh, ngày nhập học.                          |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | TIMESTAMP        | 8 bytes             | Ngày + Giờ (Không múi giờ).                                         |
|                   |                  |                     | Rủi ro: Nếu server chuyển vùng, dữ liệu có thể bị hiểu sai lệch.    |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | TIMESTAMPTZ      | 8 bytes             | Ngày + Giờ + Múi giờ (Lưu trữ dưới dạng UTC).                       |
|                   |                  |                     | Tối ưu: Luôn dùng cho created_at, log_time để đảm bảo chính xác.    |
+-------------------+------------------+---------------------+---------------------------------------------------------------------+
| Logic & Binary    | BOOLEAN          | 1 byte              | True/False.                                                         |
|                   |                  |                     | Tối ưu: Tốt hơn so với việc dùng CHAR(1) ('Y'/'N') hay INT (0/1).   |
|                   +------------------+---------------------+---------------------------------------------------------------------+
|                   | BYTEA            | Biến đổi            | Mảng byte (Binary Data).                                            |
|                   |                  |                     | Tối ưu: Phù hợp để lưu mẫu vân tay hoặc ảnh nhỏ.                    |
+-------------------+------------------+---------------------+---------------------------------------------------------------------+
```

---

## 3. Ràng buộc toàn vẹn dữ liệu

**Khóa chính (Primary Key - PK):** Đảm bảo tính duy nhất và định danh của bản ghi trong bảng.
```text
CONSTRAINT pk_faculty PRIMARY KEY (faculty_id)
```
**Khóa ngoại (Foreign Key - FK):** Đảm bảo tính toàn vẹn tham chiếu (Referential Integrity) giữa bảng con (Child Table) và bảng cha (Parent Table).
```text
CONSTRAINT fk_major_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
```

**Cú pháp nâng cao (Cascade Delete):** Áp dụng cho quan hệ phụ thuộc mạnh (Composition). Khi bản ghi cha bị xóa, bản ghi con sẽ bị xóa theo tự động.
```text
CONSTRAINT fk_sp_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
```

# Github

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