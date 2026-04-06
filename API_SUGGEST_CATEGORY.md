# Hướng dẫn API Gợi ý Category dựa vào Description

## Endpoint: POST /api/categories/suggest

Endpoint này sử dụng AI (OpenAI) để phân tích description công việc và gợi ý các category phù hợp nhất từ danh sách categories của user.

### Request

```json
{
  "description": "Viết báo cáo chi tiết về tiến độ dự án và phân tích kết quả"
}
```

### Response

```json
{
  "suggestions": [
    {
      "categoryId": 1,
      "categoryName": "Công Việc",
      "matchPercentage": 95,
      "reason": "Liên quan trực tiếp đến báo cáo dự án"
    },
    {
      "categoryId": 3,
      "categoryName": "Phân tích",
      "matchPercentage": 80,
      "reason": "Liên quan đến phân tích kết quả"
    },
    {
      "categoryId": 2,
      "categoryName": "Học Tập",
      "matchPercentage": 45,
      "reason": "Có liên quan nhẹ đến việc học hỏi từ phân tích"
    }
  ],
  "message": "Gợi ý category dựa trên mô tả công việc của bạn"
}
```

## Test với Postman

### Headers
```
Authorization: Bearer {TOKEN}
Content-Type: application/json
```

### Request Body
```json
{
  "description": "Hoàn thành báo cáo dự án, phân tích tiến độ và đánh giá kết quả"
}
```

### Quy trình Test

1. **Đăng nhập** để lấy token
   ```
   POST http://localhost:9090/api/users/login
   {
     "username": "tuananhdev",
     "password": "password123"
   }
   ```

2. **Lấy danh sách categories** của user
   ```
   GET http://localhost:9090/api/categories
   ```

3. **Gọi API gợi ý category**
   ```
   POST http://localhost:9090/api/categories/suggest
   Headers: Authorization: Bearer {TOKEN}
   Body: 
   {
     "description": "Phải hoàn thành bài tập lập trình Java và nộp báo cáo"
   }
   ```

4. **Kết quả mong đợi**: API sẽ trả về danh sách các categories được xếp theo % khớp giảm dần.

## Lưu ý quan trọng

- **Cần có OpenAI API Key**: Hãy thêm `OPENAI_API_KEY` vào file `.env`
  ```
  OPENAI_API_KEY=sk-xxx...
  ```

- **Chỉ gợi ý cho categories đang active**: Nếu user chưa tạo category nào, API sẽ báo lỗi.

- **Model sử dụng**: Mặc định là `gpt-3.5-turbo-0125` (có thể thay đổi trong `application.properties`)

## Ví dụ sử dụng trong Frontend

```javascript
// Gọi API gợi ý category
const description = "Chuẩn bị cho kỳ thi toán học";
const response = await fetch('http://localhost:9090/api/categories/suggest', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ description })
});

const data = await response.json();
console.log(data.suggestions); // [{ categoryId, categoryName, matchPercentage, reason }]

// Người dùng có thể nhấn vào gợi ý để apply category đó
const selectedCategory = data.suggestions[0]; // Category với % khớp cao nhất
```

## Cách hoạt động

1. User nhập description của task
2. Click nút "AI Suggest Category" 
3. Phía backend gọi OpenAI API với prompt chứa:
   - Danh sách tên categories của user
   - Description vừa nhập
   - Yêu cầu trả về 3 gợi ý tốt nhất với % match và lý do
4. Service parse response từ AI và match lại với database
5. Trả về danh sách gợi ý sắp xếp theo % match giảm dần
6. Frontend hiển thị gợi ý, user có thể nhấn để apply

## Xử lý lỗi

- Nếu user chưa tạo category: `message: "Người dùng chưa tạo category nào. Vui lòng tạo category trước."`
- Nếu OpenAI API key không hợp lệ: Sẽ nhận được lỗi từ OpenAI
- Nếu không authentication: Sẽ nhận được lỗi 401 Unauthorized

---
**Ngày tạo**: 2026-03-26  
**Version**: 1.0

