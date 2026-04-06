# Hướng dẫn Test Chức năng Gợi ý Category bằng AI

## Mục tiêu
Test endpoint `/api/categories/suggest` - gợi ý category dựa vào mô tả công việc của user bằng OpenAI API.

## Yêu cầu
- Backend chạy trên `http://localhost:8080`
- Có account user: `truong_admin` / `123456`
- OpenAI API Key đã được cấu hình trong `.env`
- Postman hoặc công cụ test API khác

## Các bước test

### 1️⃣ Chuẩn bị dữ liệu
Trước tiên, đảm bảo user có ít nhất 3 categories:
```
GET http://localhost:8080/api/categories
Authorization: Bearer {TOKEN}
```

Nếu chưa có, hãy tạo vài categories:
```
POST http://localhost:8080/api/categories
{
  "name": "Công Việc"
}
```

### 2️⃣ Test Endpoint Gợi ý

**Endpoint**: `POST http://localhost:8080/api/categories/suggest`

**Headers**:
```
Authorization: Bearer {TOKEN}
Content-Type: application/json
```

**Request Body** (Ví dụ 1 - Báo cáo dự án):
```json
{
  "description": "Hoàn thành báo cáo chi tiết về tiến độ dự án và phân tích kết quả"
}
```

**Expected Response** (Chỉ trả về 1 category tốt nhất):
```json
{
  "suggestions": [
    {
      "categoryId": 1,
      "categoryName": "Công Việc",
      "matchPercentage": 90.0,
      "reason": "Hoàn thành báo cáo chi tiết về tiến độ dự án liên quan đến công việc chính"
    }
  ],
  "message": "Gợi ý category tốt nhất dựa trên mô tả công việc của bạn"
}
```

**Lưu ý**: 
- API chỉ trả về **1 category** có match % cao nhất
- User có thể nhấn **Apply** để sử dụng category này hoặc **Skip** để chọn category khác

### 3️⃣ Các ví dụ thêm

**Ví dụ 2 - Học lập trình**:
```json
{
  "description": "Phải hoàn thành bài tập lập trình Java, học Spring Boot, JPA và Security"
}
```

**Ví dụ 3 - Chuẩn bị thi**:
```json
{
  "description": "Chuẩn bị cho kỳ thi toán học, ôn tập các công thức và làm bài tập"
}
```

## Cách nhập thông tin

### ✅ Sử dụng Postman
1. Import file `postman_collection_suggest_category.json` vào Postman
2. Chạy request "1. Login" để lấy access token (tự động lưu vào biến environment)
3. Chạy các request "3. Suggest Category" trở đi để test

### ✅ Dùng cURL (Command Line)
```bash
# Login
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"truong_admin","password":"123456"}'

# Lấy accessToken từ response, sau đó:
curl -X POST http://localhost:8080/api/categories/suggest \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"description":"Hoàn thành báo cáo dự án và phân tích kết quả"}'
```

### ✅ Dùng JavaScript/Fetch
```javascript
// 1. Login
const loginRes = await fetch('http://localhost:8080/api/users/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'truong_admin', password: '123456' })
});
const { accessToken } = await loginRes.json();

// 2. Gợi ý category
const suggestRes = await fetch('http://localhost:8080/api/categories/suggest', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    description: 'Hoàn thành báo cáo dự án và phân tích kết quả'
  })
});
const suggestions = await suggestRes.json();
console.log(suggestions);
```

## Kết quả mong đợi

✅ **Success (200)**:
- API trả về danh sách suggestions
- Mỗi suggestion có: categoryId, categoryName, matchPercentage (0-100%), reason

❌ **Error Cases**:
- `401 Unauthorized`: TOKEN hết hạn hoặc không hợp lệ
- `400 Bad Request`: Description rỗng
- `400 Bad Request`: User chưa tạo category nào

## Ghi chú quan trọng

- 🔑 OpenAI API Key phải hợp lệ trong `.env`
- 📝 Description phải là tiếng Việt (được test tốt nhất)
- ⏱️ Response có thể mất 2-5 giây do gọi OpenAI API
- 📊 % Match là gợi ý của AI dựa trên sự tương đồng của text
- 🎯 Suggestions được sắp xếp theo % Match giảm dần (cao nhất lên đầu)

## ✅ Fix lỗi 405 Method Not Allowed

Nếu nhận lỗi 405, hãy kiểm tra:
1. **URL phải là**: `http://localhost:8080/api/categories/suggest` (not 9090)
2. **Method phải là**: `POST` (không phải GET)
3. **Token phải hợp lệ**: Check Authorization header

---

## Commit Message

```
feat: add AI category suggestion feature

- Add POST /api/categories/suggest endpoint
- Use OpenAI API to analyze task description
- Return only the best matching category with percentage
- User can Apply or Skip the suggestion
```

---
**Ngày tạo**: 2026-04-06  
**Version**: 2.0 (Fixed port to 8080)


