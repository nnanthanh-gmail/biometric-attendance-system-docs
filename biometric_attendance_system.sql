/* ========================================================================== */
/* DATABASE: biometric_attendance_system                                      */
/* DESCRIPTION: Hệ thống quản lý điểm danh sinh trắc học                      */
/* ========================================================================== */

/* ========================================================================== */
/* 1. MASTER DATA MANAGEMENT (QUẢN LÝ DỮ LIỆU DANH MỤC)                       */
/* ========================================================================== */

-- [Catalog] Danh mục Khoa/Viện (Organizational Units)
CREATE TABLE faculty (
    faculty_id          VARCHAR(20),
    faculty_name        TEXT            NOT NULL, -- Tên hiển thị đầy đủ
    CONSTRAINT pk_faculty PRIMARY KEY (faculty_id)
);

-- [Catalog] Danh mục Cơ sở vật chất/Phòng học (Physical Resources)
CREATE TABLE room (
    room_id             VARCHAR(20),
    room_name           TEXT            NOT NULL,
    CONSTRAINT pk_room PRIMARY KEY (room_id)
);

-- [Catalog] Bậc hệ đào tạo (Academic Levels: ĐH, CĐ, Sau ĐH)
CREATE TABLE education_level (
    edu_level_id        VARCHAR(20),
    edu_level_name      TEXT            NOT NULL,
    CONSTRAINT pk_edu_level PRIMARY KEY (edu_level_id)
);

/* ========================================================================== */
/* 2. ACADEMIC STRUCTURE (CẤU TRÚC ĐÀO TẠO & HÀNH CHÍNH)                      */
/* ========================================================================== */

-- [Curriculum] Chuyên ngành đào tạo (Academic Major)
CREATE TABLE major (
    major_id            VARCHAR(20),
    faculty_id          VARCHAR(20)     NOT NULL, -- FK: Thuộc khoa nào
    major_name          TEXT            NOT NULL,

    CONSTRAINT pk_major PRIMARY KEY (major_id),
    CONSTRAINT fk_major_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
);

-- [Curriculum] Danh mục Học phần/Môn học (Subject Definition)
CREATE TABLE subject (
    subject_id          VARCHAR(20),
    subject_name        TEXT            NOT NULL,
    credits             SMALLINT        NOT NULL DEFAULT 0, -- Số tín chỉ
    theory              SMALLINT        NOT NULL DEFAULT 0, -- Số tiết lý thuyết
    practice            SMALLINT        NOT NULL DEFAULT 0, -- Số tiết thực hành
    semester            SMALLINT        NOT NULL,           -- Học kỳ mặc định

    CONSTRAINT pk_subject PRIMARY KEY (subject_id)
);

-- [Admin] Lớp danh chế/Lớp hành chính (Administrative Class)
CREATE TABLE class (
    class_id            VARCHAR(20),
    major_id            VARCHAR(20)     NOT NULL,
    edu_level_id        VARCHAR(20)     NOT NULL,
    class_name          TEXT            NOT NULL,
    course              VARCHAR(10)     NOT NULL, -- Khóa học (VD: K15, K16)
    enroll_year         SMALLINT        NOT NULL, -- Năm nhập học

    CONSTRAINT pk_class PRIMARY KEY (class_id),
    CONSTRAINT fk_class_major FOREIGN KEY (major_id) REFERENCES major(major_id),
    CONSTRAINT fk_class_edulevel FOREIGN KEY (edu_level_id) REFERENCES education_level(edu_level_id)
);

/* ========================================================================== */
/* 3. USER MANAGEMENT (QUẢN LÝ NGƯỜI DÙNG & HỒ SƠ)                            */
/* Pattern: Table-per-Type Inheritance (Users -> Student/Lecturer Profile)    */
/* ========================================================================== */

-- [Core Entity] Bảng định danh người dùng cơ sở (Base User Identity)
CREATE TABLE users (
    user_id             VARCHAR(32),    -- Unique Identifier (Employee/Student ID)
    class_id            VARCHAR(20),    -- Nullable: Giảng viên không thuộc lớp danh chế
    full_name           TEXT            NOT NULL,

    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT fk_users_class FOREIGN KEY (class_id) REFERENCES class(class_id)
);

-- [Profile] Thông tin mở rộng cho Sinh viên (Student Attributes)
CREATE TABLE student_profile (
    user_id             VARCHAR(32),
    birth_date          DATE            NOT NULL,
    gender              BOOLEAN         NOT NULL,
    phone               VARCHAR(15)     NOT NULL,
    address             TEXT            NOT NULL,
    
    CONSTRAINT pk_student_profile PRIMARY KEY (user_id),
    CONSTRAINT fk_sp_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- [Profile] Thông tin mở rộng cho Giảng viên (Lecturer Attributes)
CREATE TABLE lecturer_profile (
    user_id             VARCHAR(32),
    faculty_id          VARCHAR(20)     NOT NULL,
    degree              TEXT            NOT NULL, -- Học vị
    research_area       TEXT,                     -- Lĩnh vực nghiên cứu

    CONSTRAINT pk_lecturer_profile PRIMARY KEY (user_id),
    CONSTRAINT fk_lp_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_lp_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
);

/* ========================================================================== */
/* 4. SECURITY & BIOMETRICS (BẢO MẬT & SINH TRẮC HỌC)                         */
/* ========================================================================== */

-- [AuthN/AuthZ] Tài khoản & Phân quyền (RBAC)
CREATE TABLE account (
    user_id             VARCHAR(32),
    password_hash       VARCHAR(255)    NOT NULL, -- Encrypted Password
    role                CHAR(1)         NOT NULL DEFAULT 's' CHECK (role IN ('a', 'l', 's')), -- Admin, Lecturer, Student

    CONSTRAINT pk_account PRIMARY KEY (user_id),
    CONSTRAINT fk_account_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- [Biometrics] Dữ liệu vân tay (Fingerprint Storage)
CREATE TABLE fingerprint (
    finger_id           VARCHAR(32),
    user_id             VARCHAR(32)     NOT NULL,
    finger_data         BYTEA           NOT NULL, -- Binary Large Object (BLOB)

    CONSTRAINT pk_fingerprint PRIMARY KEY (finger_id),
    CONSTRAINT fk_finger_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

/* ========================================================================== */
/* 5. TRANSACTIONAL OPERATIONS (NGHIỆP VỤ HÀNG NGÀY)                          */
/* ========================================================================== */

-- [Enrollment] Đăng ký học phần (Student-Subject Mapping)
CREATE TABLE course_registration (
    reg_id              SERIAL,         -- Auto-increment Primary Key
    user_id             VARCHAR(32)     NOT NULL,
    subject_id          VARCHAR(20)     NOT NULL,
    host_class_id       VARCHAR(20)     NOT NULL, -- Lớp học phần/Lớp ghép
    semester            SMALLINT        NOT NULL,
    year                SMALLINT        NOT NULL,
    created_at          TIMESTAMPTZ     NOT NULL    DEFAULT CURRENT_TIMESTAMP, -- Audit Log

    CONSTRAINT pk_course_registration PRIMARY KEY (reg_id),
    CONSTRAINT uq_course_reg UNIQUE (user_id, subject_id, host_class_id, semester, year), -- Chặn trùng lặp
    CONSTRAINT fk_cr_users    FOREIGN KEY (user_id)       REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_cr_subject  FOREIGN KEY (subject_id)    REFERENCES subject(subject_id),
    CONSTRAINT fk_cr_host     FOREIGN KEY (host_class_id) REFERENCES class(class_id)
);

-- [Scheduling] Thời khóa biểu chi tiết (Time Slot Management)
CREATE TABLE schedule (
    schedule_id         SERIAL,
    subject_id          VARCHAR(20)     NOT NULL,
    room_id             VARCHAR(20)     NOT NULL,
    lecturer_id         VARCHAR(32)     NOT NULL,
    class_id            VARCHAR(20)     NOT NULL, -- Lớp tham gia học
    learn_date          DATE            NOT NULL,
    start_period        SMALLINT        NOT NULL, -- Tiết bắt đầu
    end_period          SMALLINT        NOT NULL, -- Tiết kết thúc
    is_open             BOOLEAN         NOT NULL DEFAULT FALSE, -- Trạng thái điểm danh (Mở/Đóng)
    
    CONSTRAINT pk_schedule PRIMARY KEY (schedule_id),
    CONSTRAINT fk_sch_subject  FOREIGN KEY (subject_id)  REFERENCES subject(subject_id),
    CONSTRAINT fk_sch_room     FOREIGN KEY (room_id)     REFERENCES room(room_id),
    CONSTRAINT fk_sch_lecturer FOREIGN KEY (lecturer_id) REFERENCES users(user_id),
    CONSTRAINT fk_sch_class    FOREIGN KEY (class_id)    REFERENCES class(class_id)
);

-- [Logging] Lịch sử điểm danh (Attendance Logs)
CREATE TABLE attendance (
    attend_id           SERIAL,
    schedule_id         INT             NOT NULL,
    user_id             VARCHAR(32)     NOT NULL,
    attend_time         TIMESTAMPTZ     NOT NULL    DEFAULT CURRENT_TIMESTAMP, -- Thời gian check-in thực tế
    status              BOOLEAN         NOT NULL    DEFAULT FALSE, -- True: Có mặt, False: Vắng

    CONSTRAINT pk_attendance PRIMARY KEY (attend_id),
    CONSTRAINT uq_att_user_sch UNIQUE (schedule_id, user_id), -- Một người chỉ điểm danh 1 lần/buổi
    CONSTRAINT fk_att_users    FOREIGN KEY (user_id)     REFERENCES users(user_id),
    CONSTRAINT fk_att_schedule FOREIGN KEY (schedule_id) REFERENCES schedule(schedule_id)
);