# API Test Guide - TodoApp Backend

## ✅ Các Lỗi Đã Fix

### 1. Fix: Get Tasks by Category endpoint
**Vấn đề:** `GET /api/tasks/by-category/{id}` chỉ trả về 1 task thay vì tất cả tasks trong category
**Nguyên nhân:** Sử dụng entity relationship `category.getTasks()` gặp Hibernate lazy loading issue
**Giải pháp:** Sử dụng repository query `taskRepository.findByCategoryIdAndIsActiveTrue(categoryId)`
**Status:** ✅ FIXED

### 2. Fix: Get Category by ID endpoint  
**Vấn đề:** `GET /api/categories/{id}` chỉ trả về tổng số task, không liệt kê chi tiết tasks
**Nguyên nhân:** CategoryResponseDTO chỉ có field `taskCount`
**Giải pháp:** Cập nhật endpoint để trả về object chứa danh sách tasks chi tiết kèm theo taskCount
**Status:** ✅ FIXED

---

## 🔧 Cách Test API

### Option 1: Dùng Postman (Khuyên dùng)
1. Mở Postman
2. Import file: `postman_collection.json` (trong thư mục gốc project)
3. Test các endpoint theo thứ tự

### Option 2: Dùng curl (từ PowerShell)

#### Bước 1: Login để lấy access token
```powershell
$loginResponse = Invoke-WebRequest -Uri "http://localhost:9090/api/users/login" `
  -Method Post `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"username":"tuananhdev","password":"password123"}' `
  -UseBasicParsing

$token = ($loginResponse.Content | ConvertFrom-Json).accessToken
Write-Output "Token: $token"
```

#### Bước 2: Test Get Category by ID (NEW - with tasks list)
```powershell
$headers = @{
    "Authorization" = "Bearer $token"
}

$categoryResponse = Invoke-WebRequest -Uri "http://localhost:9090/api/categories/2" `
  -Method Get `
  -Headers $headers `
  -UseBasicParsing

$categoryResponse.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

**Expected Response:**
```json
{
  "id": 2,
  "name": "Học Tập",
  "isActive": true,
  "tasks": [
    {
      "id": 2,
      "title": "Học Spring Boot",
      "description": "Học về JPA, Security, JWT",
      "priority": "MEDIUM",
      "status": "DOING",
      "dueDate": "2026-04-05T18:00:00",
      "createdAt": "2026-03-25T21:00:20",
      "isActive": true,
      "categoryName": "Học Tập",
      "categoryId": 2,
      "username": "tuananhdev"
    },
    {
      "id": 3,
      "title": "Học python",
      "description": "Học về JPA, Security, JWT",
      "priority": "MEDIUM",
      "status": "DOING",
      "dueDate": "2026-04-05T18:00:00",
      "createdAt": "2026-03-26T08:34:11",
      "isActive": true,
      "categoryName": "Học Tập",
      "categoryId": 2,
      "username": "tuananhdev"
    }
  ],
  "taskCount": 2
}
```

#### Bước 3: Test Get Tasks by Category (NEW - fixed lazy loading)
```powershell
$tasksResponse = Invoke-WebRequest -Uri "http://localhost:9090/api/tasks/by-category/2" `
  -Method Get `
  -Headers $headers `
  -UseBasicParsing

$tasksResponse.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

**Expected:** Trả về mảng 2 tasks (Học Spring Boot + Học python)

---

## 📝 Các Endpoint Chính

### Categories
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/categories` | Tạo category mới |
| GET | `/api/categories` | Lấy danh sách categories của user |
| GET | `/api/categories/{id}` | **[FIXED]** Lấy chi tiết category + danh sách tasks |
| PATCH | `/api/categories/{id}` | Cập nhật category |
| DELETE | `/api/categories/{id}` | Xóa category (cascade soft delete tasks) |

### Tasks
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/tasks` | Tạo task mới |
| GET | `/api/tasks` | Lấy danh sách tasks của user |
| GET | `/api/tasks/{id}` | Lấy chi tiết task |
| GET | `/api/tasks/by-category/{categoryId}` | **[FIXED]** Lấy tất cả tasks trong category |
| GET | `/api/tasks/filter/status?status=TODO` | Lọc tasks theo status |
| GET | `/api/tasks/filter/priority?priority=HIGH` | Lọc tasks theo priority |
| GET | `/api/tasks/search?keyword=...` | Tìm kiếm tasks |
| GET | `/api/tasks/overdue` | Lấy tasks quá hạn |
| PATCH | `/api/tasks/{id}` | Cập nhật task |
| DELETE | `/api/tasks/{id}` | Xóa task |

---

## 🎯 Quy Tắc Kinh Doanh (Business Rules)

### Category Rules
✅ **Anti-duplicate:** Một user không được tạo 2 category có cùng tên (nhưng khác user có thể trùng)
✅ **Cascade soft delete:** Khi xóa category, tất cả tasks active trong category sẽ bị soft delete

### Task Rules  
✅ **Anti-duplicate:** Trong cùng 1 category, không được tạo 2 task có cùng title (nhưng khác category có thể trùng)
✅ **Category required:** Task có thể không có category (null), hoặc phải thuộc category của user đó

---

## 🔐 Security Notes

1. **JWT Authentication:** Tất cả endpoint (ngoài `/api/health`, `/api/users/register`, `/api/users/login`) đều yêu cầu header `Authorization: Bearer {accessToken}`

2. **IDOR Protection:** 
   - User chỉ có thể xem/edit/delete category của mình
   - User chỉ có thể xem/edit/delete task của mình
   - Server sẽ kiểm tra quyền trước khi thực hiện hành động

3. **Token Expiry:**
   - `accessToken`: 15 phút (900000ms)
   - `refreshToken`: 7 ngày (604800000ms)

---

## 📦 Files Đã Sửa/Thêm

### Sửa:
- `src/main/java/com/example/demo/service/CategoryService.java` - Cập nhật `getCategoryById()`
- `src/main/java/com/example/demo/service/TaskService.java` - Cập nhật `getTasksByCategory()`

### Xóa:
- `src/main/java/com/example/demo/dto/CategoryDetailResponseDTO.java` (không cần dùng)

---

## 🚀 Next Steps

1. Chạy server: `.\mvnw spring-boot:run "-Dspring-boot.run.arguments=--server.port=9090"`
2. Import Postman collection để test
3. Verify endpoints return correct data with task lists

---

**Updated:** March 26, 2026
**Author:** GitHub Copilot

