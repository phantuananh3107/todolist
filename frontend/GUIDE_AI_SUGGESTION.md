# Hướng dẫn sử dụng AI Category Suggestion - Frontend Flutter

## Chức năng

Khi user tạo task mới, sau khi nhập **description**, hệ thống sẽ tự động gợi ý category phù hợp nhất dựa trên nội dung mô tả.

## Cách hoạt động

1. **User nhập description** → Chờ 1 giây
2. **Frontend gọi API** `POST /api/categories/suggest` 
3. **Backend phân tích** bằng OpenAI API
4. **Hiển thị suggestion** với:
   - Tên category gợi ý
   - Phần trăm khớp (%)
   - Nút "Apply" để chọn

## UI Chi tiết

### Khi đang phân tích:
```
💡 AI SUGGESTION
Đang phân tích...
```

### Khi có suggestion:
```
🔴 AI SUGGESTION
Suggested Category: Công Việc
90% Match          [Apply Button]
```

## Các tính năng

✅ **Tự động phân tích**: Không cần user nhấn nút, tự động sau 1s nhập xong  
✅ **Chỉ 1 gợi ý tốt nhất**: Không hiển thị list, chỉ cái match % cao nhất  
✅ **Apply ngay**: User nhấn "Apply" để sử dụng category được gợi ý  
✅ **Debounced**: Chờ 1s không nhập mới gọi API (không spam request)  

## Code changes

### 1. API Service (`api_service.dart`)
```dart
static Future<Map<String, dynamic>?> suggestCategory({required String description}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/categories/suggest'),
    headers: await _headers(),
    body: jsonEncode({'description': description}),
  );
  // Return suggestion tốt nhất
}
```

### 2. Task Form State (`task_form_screen.dart`)
```dart
// Variables
Map<String, dynamic>? _suggestion;
bool _suggestingCategory = false;

// Listener on description change
descriptionController.addListener(_onDescriptionChanged);

// Call API with debounce
Future<void> _onDescriptionChanged() {
  final desc = descriptionController.text.trim();
  Future.delayed(Duration(seconds: 1), () async {
    final suggestion = await ApiService.suggestCategory(description: desc);
  });
}
```

### 3. UI Widget
- Container với border màu đỏ
- Icon lightbulb
- Text "AI SUGGESTION" (màu đỏ, bold)
- Hiển thị: Category name + % match
- Nút "Apply" (màu đỏ) để chọn category

## Testing

### Ví dụ descriptions để test:

**1. Công việc - sẽ gợi ý "Công Việc"**
```
"Hoàn thành báo cáo chi tiết về tiến độ dự án và phân tích kết quả"
```

**2. Học tập - sẽ gợi ý "Học Tập"**
```
"Phải hoàn thành bài tập lập trình Java, học Spring Boot, JPA và Security"
```

**3. Chuẩn bị thi - sẽ gợi ý "Study/Học Tập"**
```
"Chuẩn bị cho kỳ thi toán học, ôn tập các công thức và làm bài tập"
```

## Điều kiện hoạt động

✅ Backend chạy trên `http://10.0.2.2:9090` (trong emulator)  
✅ OpenAI API Key đã cấu hình trong backend `.env`  
✅ User đã đăng nhập (có token)  
✅ User đã tạo ít nhất 1 category  

## Commit Message

```
feat: add AI category suggestion to task form

- Add suggestCategory API method to ApiService
- Implement debounced description listener
- Display AI suggestion UI when available
- Add Apply button to select suggested category
- Show match percentage and suggestion reason
```

---
**Date**: 2026-04-06  
**Version**: 1.0

