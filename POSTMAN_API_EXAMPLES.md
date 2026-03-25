# 📖 Hướng Dẫn Test API với Postman - Category & Task

## 🎯 Chuẩn Bị

### 1. Backend Chạy
```bash
.\mvnw spring-boot:run
```

### 2. Postman Setup
- Mở Postman
- Import file: `TodoApp_CategoryTask_Collection.postman_collection.json`
- Environment: Chọn "TodoApp Development"

---

## 📝 VÍ DỤ TEST

### STEP 1: Đăng Ký User

**Endpoint:**
```
POST http://localhost:9090/api/users/register
```

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "username": "tuananhdev",
  "email": "tuananh@gmail.com",
  "password": "password123"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "username": "tuananhdev",
    "email": "tuananh@gmail.com"
  }
}
```

---

### STEP 2: Đăng Nhập (LƯU TOKEN)

**Endpoint:**
```
POST http://localhost:9090/api/users/login
```

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "username": "tuananhdev",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzcxNDEz...",
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzcxNDEz...",
  "username": "tuananhdev",
  "role": "USER",
  "email": "tuananh@gmail.com"
}
```

**👉 Lưu token này để dùng cho các request sau!**

---

## 📂 CATEGORY API EXAMPLES

### 1. Tạo Category

**Endpoint:**
```
POST http://localhost:9090/api/categories
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body - Ví dụ 1:**
```json
{
  "name": "Công Việc"
}
```

**Body - Ví dụ 2:**
```json
{
  "name": "Học Tập"
}
```

**Body - Ví dụ 3:**
```json
{
  "name": "Cá Nhân"
}
```

**Response (201):**
```json
{
  "id": 1,
  "name": "Công Việc",
  "userId": 1,
  "createdAt": "2026-03-25T11:30:00"
}
```

---

### 2. Lấy Danh Sách Categories

**Endpoint:**
```
GET http://localhost:9090/api/categories
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Công Việc",
    "userId": 1,
    "createdAt": "2026-03-25T11:30:00"
  },
  {
    "id": 2,
    "name": "Học Tập",
    "userId": 1,
    "createdAt": "2026-03-25T11:31:00"
  },
  {
    "id": 3,
    "name": "Cá Nhân",
    "userId": 1,
    "createdAt": "2026-03-25T11:32:00"
  }
]
```

---

### 3. Lấy Chi Tiết Category

**Endpoint:**
```
GET http://localhost:9090/api/categories/1
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
{
  "id": 1,
  "name": "Công Việc",
  "userId": 1,
  "createdAt": "2026-03-25T11:30:00"
}
```

---

### 4. Cập Nhật Category

**Endpoint:**
```
PATCH http://localhost:9090/api/categories/1
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:**
```json
{
  "name": "Công Việc Quan Trọng"
}
```

**Response (200):**
```json
{
  "id": 1,
  "name": "Công Việc Quan Trọng",
  "userId": 1,
  "updatedAt": "2026-03-25T11:35:00"
}
```

---

### 5. Xóa Category

**Endpoint:**
```
DELETE http://localhost:9090/api/categories/1
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
{
  "message": "Category deleted successfully"
}
```

---

## 📝 TASK API EXAMPLES

### 1. Tạo Task - HIGH Priority

**Endpoint:**
```
POST http://localhost:9090/api/tasks
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:**
```json
{
  "title": "Hoàn thành báo cáo dự án",
  "description": "Viết báo cáo chi tiết về tiến độ",
  "priority": "HIGH",
  "status": "TODO",
  "dueDate": "2026-03-30T17:00:00",
  "categoryId": 1
}
```

**Response (201):**
```json
{
  "id": 1,
  "title": "Hoàn thành báo cáo dự án",
  "description": "Viết báo cáo chi tiết về tiến độ",
  "priority": "HIGH",
  "status": "TODO",
  "dueDate": "2026-03-30T17:00:00",
  "categoryId": 1,
  "userId": 1,
  "createdAt": "2026-03-25T11:40:00"
}
```

---

### 2. Tạo Task - MEDIUM Priority

**Endpoint:**
```
POST http://localhost:9090/api/tasks
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:**
```json
{
  "title": "Học Spring Boot",
  "description": "Học về JPA, Security, JWT",
  "priority": "MEDIUM",
  "status": "DOING",
  "dueDate": "2026-04-05T18:00:00",
  "categoryId": 2
}
```

**Response (201):**
```json
{
  "id": 2,
  "title": "Học Spring Boot",
  "description": "Học về JPA, Security, JWT",
  "priority": "MEDIUM",
  "status": "DOING",
  "dueDate": "2026-04-05T18:00:00",
  "categoryId": 2,
  "userId": 1,
  "createdAt": "2026-03-25T11:41:00"
}
```

---

### 3. Tạo Task - LOW Priority

**Endpoint:**
```
POST http://localhost:9090/api/tasks
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:**
```json
{
  "title": "Đi mua thực phẩm",
  "description": "Mua rau, thịt, cá",
  "priority": "LOW",
  "status": "TODO",
  "dueDate": "2026-03-26T19:00:00",
  "categoryId": 3
}
```

**Response (201):**
```json
{
  "id": 3,
  "title": "Đi mua thực phẩm",
  "description": "Mua rau, thịt, cá",
  "priority": "LOW",
  "status": "TODO",
  "dueDate": "2026-03-26T19:00:00",
  "categoryId": 3,
  "userId": 1,
  "createdAt": "2026-03-25T11:42:00"
}
```

---

### 4. Lấy Danh Sách Tasks

**Endpoint:**
```
GET http://localhost:9090/api/tasks
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo dự án",
    "description": "Viết báo cáo chi tiết về tiến độ",
    "priority": "HIGH",
    "status": "TODO",
    "dueDate": "2026-03-30T17:00:00",
    "categoryId": 1,
    "userId": 1,
    "createdAt": "2026-03-25T11:40:00"
  },
  {
    "id": 2,
    "title": "Học Spring Boot",
    "description": "Học về JPA, Security, JWT",
    "priority": "MEDIUM",
    "status": "DOING",
    "dueDate": "2026-04-05T18:00:00",
    "categoryId": 2,
    "userId": 1,
    "createdAt": "2026-03-25T11:41:00"
  },
  {
    "id": 3,
    "title": "Đi mua thực phẩm",
    "priority": "LOW",
    "status": "TODO",
    "categoryId": 3,
    "userId": 1,
    "createdAt": "2026-03-25T11:42:00"
  }
]
```

---

### 5. Lấy Chi Tiết Task

**Endpoint:**
```
GET http://localhost:9090/api/tasks/1
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
{
  "id": 1,
  "title": "Hoàn thành báo cáo dự án",
  "description": "Viết báo cáo chi tiết về tiến độ",
  "priority": "HIGH",
  "status": "TODO",
  "dueDate": "2026-03-30T17:00:00",
  "categoryId": 1,
  "userId": 1,
  "createdAt": "2026-03-25T11:40:00"
}
```

---

### 6. Cập Nhật Task Status

**Endpoint:**
```
PATCH http://localhost:9090/api/tasks/1
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:**
```json
{
  "status": "DOING"
}
```

**Response (200):**
```json
{
  "id": 1,
  "title": "Hoàn thành báo cáo dự án",
  "description": "Viết báo cáo chi tiết về tiến độ",
  "priority": "HIGH",
  "status": "DOING",
  "dueDate": "2026-03-30T17:00:00",
  "categoryId": 1,
  "userId": 1,
  "updatedAt": "2026-03-25T11:45:00"
}
```

---

### 7. Xóa Task

**Endpoint:**
```
DELETE http://localhost:9090/api/tasks/1
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
{
  "message": "Task deleted successfully"
}
```

---

## 🔍 TASK FILTERS & SEARCH

### 1. Search Tasks (Tìm kiếm)

**Endpoint:**
```
GET http://localhost:9090/api/tasks/search?keyword=báo
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo dự án",
    "description": "Viết báo cáo chi tiết về tiến độ",
    "priority": "HIGH",
    "status": "TODO",
    ...
  }
]
```

---

### 2. Filter by Status - TODO

**Endpoint:**
```
GET http://localhost:9090/api/tasks/filter/status?status=TODO
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo dự án",
    "priority": "HIGH",
    "status": "TODO",
    ...
  },
  {
    "id": 3,
    "title": "Đi mua thực phẩm",
    "priority": "LOW",
    "status": "TODO",
    ...
  }
]
```

---

### 3. Filter by Status - DOING

**Endpoint:**
```
GET http://localhost:9090/api/tasks/filter/status?status=DOING
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 2,
    "title": "Học Spring Boot",
    "priority": "MEDIUM",
    "status": "DOING",
    ...
  }
]
```

---

### 4. Filter by Priority - HIGH

**Endpoint:**
```
GET http://localhost:9090/api/tasks/filter/priority?priority=HIGH
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo dự án",
    "priority": "HIGH",
    ...
  }
]
```

---

### 5. Filter by Priority - LOW

**Endpoint:**
```
GET http://localhost:9090/api/tasks/filter/priority?priority=LOW
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 3,
    "title": "Đi mua thực phẩm",
    "priority": "LOW",
    ...
  }
]
```

---

### 6. Get Tasks by Category

**Endpoint:**
```
GET http://localhost:9090/api/tasks/by-category/1
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo dự án",
    "categoryId": 1,
    ...
  }
]
```

---

### 7. Get Overdue Tasks

**Endpoint:**
```
GET http://localhost:9090/api/tasks/overdue
```

**Headers:**
```
Authorization: Bearer {{token}}
```

**Response (200):**
```json
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo dự án",
    "status": "OVERDUE",
    ...
  }
]
```

---

## 📋 Status & Priority Values

### Priority
```
- LOW
- MEDIUM
- HIGH
```

### Status
```
- TODO
- DOING
- DONE
- OVERDUE
```

---

## ⚠️ Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Token missing/invalid | Login lại, copy token vào header |
| 404 Not Found | Resource không tồn tại | Kiểm tra ID đúng không |
| 400 Bad Request | JSON format sai | Kiểm tra body JSON |
| 403 Forbidden | Không quyền truy cập | Task/Category phải của user đó |
| 500 Server Error | Lỗi backend | Kiểm tra logs backend |

---

## ✅ Test Checklist

- ☐ Đăng ký user
- ☐ Đăng nhập & lưu token
- ☐ Tạo 3 categories
- ☐ Lấy danh sách categories
- ☐ Tạo 3 tasks với priority khác nhau
- ☐ Lấy danh sách tasks
- ☐ Cập nhật task status
- ☐ Search tasks
- ☐ Filter by status
- ☐ Filter by priority
- ☐ Filter by category
- ☐ Xóa task
- ☐ Xóa category

---

## 🎉 Ready to Test!

Import file `TodoApp_CategoryTask_Collection.postman_collection.json` vào Postman và bắt đầu test! 🚀

