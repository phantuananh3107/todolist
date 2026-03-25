# 🚀 HƯỚNG DẪN SỬ DỤNG TASK & CATEGORY API

## 📝 DANH SÁCH ENDPOINT

### **CATEGORIES (Quản lý nhóm công việc)**

| Phương thức | Endpoint | Mô tả | Auth |
|-----------|----------|------|------|
| POST | `/api/categories` | Tạo nhóm mới | ✅ |
| GET | `/api/categories` | Lấy danh sách nhóm | ✅ |
| GET | `/api/categories/{id}` | Lấy chi tiết nhóm | ✅ |
| PATCH | `/api/categories/{id}` | Cập nhật nhóm | ✅ |
| DELETE | `/api/categories/{id}` | Xóa nhóm | ✅ |

### **TASKS (Quản lý công việc)**

| Phương thức | Endpoint | Mô tả | Auth |
|-----------|----------|------|------|
| POST | `/api/tasks` | Tạo công việc mới | ✅ |
| GET | `/api/tasks` | Lấy danh sách công việc | ✅ |
| GET | `/api/tasks/{id}` | Lấy chi tiết công việc | ✅ |
| PATCH | `/api/tasks/{id}` | Cập nhật công việc | ✅ |
| DELETE | `/api/tasks/{id}` | Xóa công việc | ✅ |
| GET | `/api/tasks/search?keyword=...` | Tìm kiếm công việc | ✅ |
| GET | `/api/tasks/filter/status?status=TODO` | Lọc theo trạng thái | ✅ |
| GET | `/api/tasks/filter/priority?priority=HIGH` | Lọc theo ưu tiên | ✅ |
| GET | `/api/tasks/overdue` | Lấy công việc quá hạn | ✅ |
| GET | `/api/tasks/by-category/{id}` | Lấy công việc theo nhóm | ✅ |

---

## 📋 VÍ DỤ REQUEST

### **1. Tạo nhóm công việc**
```bash
POST http://localhost:9090/api/categories
Headers:
  Authorization: Bearer <TOKEN>
  Content-Type: application/json

Body:
{
  "name": "Công việc"
}

Response (201 Created):
{
  "id": 1,
  "name": "Công việc",
  "isActive": true,
  "taskCount": 0
}
```

### **2. Tạo công việc**
```bash
POST http://localhost:9090/api/tasks
Headers:
  Authorization: Bearer <TOKEN>
  Content-Type: application/json

Body:
{
  "title": "Hoàn thành báo cáo",
  "description": "Báo cáo kỳ 1 năm 2026",
  "priority": "HIGH",
  "status": "TODO",
  "dueDate": "2026-03-30T17:00:00",
  "categoryId": 1
}

Response (201 Created):
{
  "id": 1,
  "title": "Hoàn thành báo cáo",
  "description": "Báo cáo kỳ 1 năm 2026",
  "priority": "HIGH",
  "status": "TODO",
  "dueDate": "2026-03-30T17:00:00",
  "createdAt": "2026-03-25T13:45:00",
  "isActive": true,
  "categoryName": "Công việc",
  "categoryId": 1,
  "username": "tuanh"
}
```

### **3. Lấy danh sách công việc**
```bash
GET http://localhost:9090/api/tasks
Headers:
  Authorization: Bearer <TOKEN>

Response (200 OK):
[
  {
    "id": 1,
    "title": "Hoàn thành báo cáo",
    "description": "Báo cáo kỳ 1 năm 2026",
    "priority": "HIGH",
    "status": "TODO",
    "dueDate": "2026-03-30T17:00:00",
    "createdAt": "2026-03-25T13:45:00",
    "isActive": true,
    "categoryName": "Công việc",
    "categoryId": 1,
    "username": "tuanh"
  }
]
```

### **4. Cập nhật công việc**
```bash
PATCH http://localhost:9090/api/tasks/1
Headers:
  Authorization: Bearer <TOKEN>
  Content-Type: application/json

Body:
{
  "status": "DOING",
  "priority": "MEDIUM"
}

Response (200 OK):
{
  "id": 1,
  "title": "Hoàn thành báo cáo",
  "status": "DOING",
  "priority": "MEDIUM",
  ...
}
```

### **5. Lọc công việc theo trạng thái**
```bash
GET http://localhost:9090/api/tasks/filter/status?status=TODO
Headers:
  Authorization: Bearer <TOKEN>

Response (200 OK):
[
  { "id": 1, "title": "Task 1", "status": "TODO", ... },
  { "id": 2, "title": "Task 2", "status": "TODO", ... }
]
```

### **6. Lọc công việc theo ưu tiên**
```bash
GET http://localhost:9090/api/tasks/filter/priority?priority=HIGH
Headers:
  Authorization: Bearer <TOKEN>

Response (200 OK):
[
  { "id": 1, "title": "Task HIGH", "priority": "HIGH", ... }
]
```

### **7. Tìm kiếm công việc**
```bash
GET http://localhost:9090/api/tasks/search?keyword=báo
Headers:
  Authorization: Bearer <TOKEN>

Response (200 OK):
[
  { "id": 1, "title": "Hoàn thành báo cáo", ... }
]
```

### **8. Lấy công việc quá hạn**
```bash
GET http://localhost:9090/api/tasks/overdue
Headers:
  Authorization: Bearer <TOKEN>

Response (200 OK):
[
  { "id": 1, "title": "Task quá hạn", "status": "TODO", ... }
]
```

### **9. Lấy công việc theo nhóm**
```bash
GET http://localhost:9090/api/tasks/by-category/1
Headers:
  Authorization: Bearer <TOKEN>

Response (200 OK):
[
  { "id": 1, "title": "Task 1", "categoryName": "Công việc", ... }
]
```

---

## 🔐 AUTHENTICATION FLOW

1. **Đăng ký**
```bash
POST /api/users/register
Body: { "username": "tuanh", "email": "tuanh@gmail.com", "password": "123456" }
```

2. **Đăng nhập để lấy token**
```bash
POST /api/users/login
Body: { "email": "tuanh@gmail.com", "password": "123456" }

Response:
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "username": "tuanh",
  "role": "USER",
  "email": "tuanh@gmail.com"
}
```

3. **Sử dụng token trong header**
```bash
Authorization: Bearer <accessToken>
```

---

## ⚠️ STATUS CODES

| Code | Ý nghĩa |
|------|---------|
| 200 | OK - Thành công |
| 201 | Created - Tạo mới thành công |
| 400 | Bad Request - Dữ liệu không hợp lệ |
| 401 | Unauthorized - Cần đăng nhập |
| 403 | Forbidden - Không có quyền |
| 404 | Not Found - Không tìm thấy |
| 500 | Server Error - Lỗi server |

---

## 🚨 COMMON ERRORS

### **1. Token không hợp lệ**
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```
**Fix:** Đăng nhập lại để lấy token mới

### **2. Không có quyền (IDOR)**
```json
{
  "error": "Forbidden",
  "message": "Bạn không có quyền xem công việc này!"
}
```
**Fix:** Chỉ có thể xem/sửa công việc của chính mình

### **3. Dữ liệu không hợp lệ**
```json
{
  "error": "Bad Request",
  "message": "Tiêu đề công việc không được để trống!"
}
```
**Fix:** Kiểm tra lại dữ liệu request

---

## 💾 PRIORITY VALUES
- `LOW` - Ưu tiên thấp
- `MEDIUM` - Ưu tiên trung bình
- `HIGH` - Ưu tiên cao

## 📊 STATUS VALUES
- `TODO` - Chưa làm
- `DOING` - Đang làm
- `DONE` - Hoàn thành
- `OVERDUE` - Quá hạn

---

## 📱 POSTMAN COLLECTION

Sử dụng file `TodoApp_Tasks_Categories.postman_collection.json` để import vào Postman:

1. Mở Postman
2. Click **File** → **Import**
3. Chọn file `TodoApp_Tasks_Categories.postman_collection.json`
4. Set biến `accessToken` trong Postman environment
5. Test tất cả endpoint

---

## 🔍 IDOR PROTECTION

Tất cả endpoint đều có bảo vệ IDOR:
- Bạn chỉ có thể xem/sửa/xóa công việc và nhóm của chính mình
- Nếu cố gắng xem của người khác → **Error 403 Forbidden**

---

## ✅ READY TO TEST!

**Server:** http://localhost:9090  
**Database:** MySQL  
**API Docs:** Xem ở `/` hoặc `/api/health`

Happy coding! 🚀

