-- --- 1. NHÓM BẢNG DANH MỤC (Tạo trước vì không phụ thuộc ai) ---

CREATE TABLE faculty (
    faculty_id VARCHAR(50) PRIMARY KEY,
    faculty_name VARCHAR(100) NOT NULL
);

CREATE TABLE room (
    room_id VARCHAR(50) PRIMARY KEY,
    room_name VARCHAR(50) NOT NULL
);

CREATE TABLE education_level (
    education_level_id VARCHAR(50) PRIMARY KEY,
    education_level_name VARCHAR(100) NOT NULL
);

-- --- 2. NHÓM BẢNG PHỤ THUỘC CẤP 1 ---

CREATE TABLE major (
    major_id VARCHAR(50) PRIMARY KEY,
    faculty_id VARCHAR(50) REFERENCES faculty(faculty_id),
    major_name VARCHAR(100) NOT NULL
);

CREATE TABLE subject (
    subject_id VARCHAR(50) PRIMARY KEY,
    subject_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL,
    theory INT NOT NULL,
    practice INT NOT NULL,
    semester INT NOT NULL
);

-- --- 3. NHÓM BẢNG PHỤ THUỘC CẤP 2 ---

CREATE TABLE class (
    class_id VARCHAR(50) PRIMARY KEY,
    major_id VARCHAR(50) REFERENCES major(major_id),
    class_name VARCHAR(50),
    course VARCHAR(50),
    education_system VARCHAR(50),
    enrollment_year INT
);

-- --- 4. BẢNG TRUNG TÂM: USERS ---
-- Bảng này phụ thuộc vào Faculty và Class nên phải tạo sau cùng trong nhóm danh mục

CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY, -- Đã đồng bộ kiểu VARCHAR
    faculty_id VARCHAR(50) REFERENCES faculty(faculty_id),
    class_id VARCHAR(50) REFERENCES class(class_id),
    full_name VARCHAR(100) NOT NULL
);

-- --- 5. NHÓM BẢNG NGHIỆP VỤ (Phụ thuộc vào Users) ---

CREATE TABLE account (
    username VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    role INT NOT NULL CHECK (role IN (0,1,2)),
    -- Sửa kiểu INT thành VARCHAR(50) để khớp với bảng users
    user_id VARCHAR(50) UNIQUE REFERENCES users(user_id)
);

CREATE TABLE personal_profile (
    student_id VARCHAR(50) PRIMARY KEY REFERENCES users(user_id),
    faculty_id VARCHAR(50) REFERENCES faculty(faculty_id),
    class_id VARCHAR(50) REFERENCES class(class_id),
    education_level_id VARCHAR(50) REFERENCES education_level(education_level_id),
    major_id VARCHAR(50) REFERENCES major(major_id),
    date_of_birth DATE,
    gender INT CHECK (gender IN (0,1)),
    place_of_birth VARCHAR(255),
    permanent_address TEXT, -- PostgreSQL dùng TEXT rất tốt cho địa chỉ dài
    temporary_address TEXT,
    phone_number VARCHAR(15)
);

CREATE TABLE schedule (
    schedule_id VARCHAR(50) PRIMARY KEY,
    subject_id VARCHAR(50) REFERENCES subject(subject_id),
    room_id VARCHAR(50) REFERENCES room(room_id),
    user_id VARCHAR(50) REFERENCES users(user_id), -- Sửa INT thành VARCHAR
    schedule_date DATE,
    period VARCHAR(20),
    start INT,
    out INT,
    group_name VARCHAR(50)
);

-- Sửa logic: Một nhóm có nhiều sinh viên, nên khóa chính phải là cặp (group_id, user_id)
CREATE TABLE student_group (
    group_id VARCHAR(50),
    user_id VARCHAR(50) REFERENCES users(user_id),
    PRIMARY KEY (group_id, user_id)
);
CREATE TABLE attendance (
    attendance_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    subject_id VARCHAR(50) REFERENCES subject(subject_id),
    class_id VARCHAR(50) REFERENCES class(class_id),
    attendance_date DATE,
    attendance_status INT CHECK (attendance_status IN (0,1))
);

CREATE TABLE fingerprint (
    fingerprint_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id),
    class_id VARCHAR(50) REFERENCES class(class_id)
);