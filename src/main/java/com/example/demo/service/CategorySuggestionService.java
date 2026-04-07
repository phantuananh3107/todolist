package com.example.demo.service;

import com.example.demo.dto.*;
import com.example.demo.entity.Category;
import com.example.demo.entity.User;
import com.example.demo.repository.CategoryRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class CategorySuggestionService {

    @Autowired
    private OpenAIService openAIService;

    @Autowired
    private CategoryRepository categoryRepository;

    /**
     * Gợi ý category dựa vào description sử dụng OpenAI
     */
    public CategorySuggestionsResponse suggestCategories(Long userId, CategorySuggestionRequest request) {
        // Lấy categories của user
        List<Category> userCategories = categoryRepository.findByUserIdAndIsActiveTrue(userId);

        if (userCategories.isEmpty()) {
            return new CategorySuggestionsResponse(
                    new ArrayList<>(),
                    "Người dùng chưa tạo category nào. Vui lòng tạo category trước."
            );
        }

        // Tạo danh sách tên categories
        String categoryList = userCategories.stream()
                .map(Category::getName)
                .collect(Collectors.joining(", "));

        // Prompt cho AI
        String prompt = String.format(
                "Tôi có các category: %s\n\n" +
                "Dựa vào mô tả công việc sau, hãy gợi ý category phù hợp nhất với phần trăm khớp (0-100%%) và lý do ngắn gọn.\n\n" +
                "Mô tả công việc: \"%s\"\n\n" +
                "Trả lời theo format JSON như sau (không bao gồm ```json hay ```):\n" +
                "[\n" +
                "  {\"categoryName\": \"Tên category\", \"matchPercentage\": 85, \"reason\": \"Lý do ngắn gọn\"}\n" +
                "]\n\n" +
                "CHỈ TRẢ VỀ 1 CATEGORY TỐT NHẤT THÔI!",
                categoryList, request.getDescription()
        );

        // Gọi OpenAI
        String aiResponse = openAIService.getResponseFromAI(prompt);

        // Parse response từ AI
        List<CategorySuggestionDTO> suggestions = parseAISuggestions(aiResponse, userCategories);

        // Chỉ return suggestion tốt nhất (cái đầu tiên sau khi sort)
        if (!suggestions.isEmpty()) {
            return new CategorySuggestionsResponse(
                    List.of(suggestions.get(0)),
                    "Gợi ý category tốt nhất dựa trên mô tả công việc của bạn"
            );
        }

        return new CategorySuggestionsResponse(
                new ArrayList<>(),
                "Không thể gợi ý category. Vui lòng thử lại."
        );
    }

    /**
     * Parse JSON response từ AI và match với database
     */
    private List<CategorySuggestionDTO> parseAISuggestions(String aiResponse, List<Category> userCategories) {
        List<CategorySuggestionDTO> suggestions = new ArrayList<>();

        try {
            // Xóa các ký tự không cần thiết
            String cleanResponse = aiResponse.trim();
            if (cleanResponse.startsWith("```json")) {
                cleanResponse = cleanResponse.substring(7);
            }
            if (cleanResponse.startsWith("```")) {
                cleanResponse = cleanResponse.substring(3);
            }
            if (cleanResponse.endsWith("```")) {
                cleanResponse = cleanResponse.substring(0, cleanResponse.length() - 3);
            }

            // Parse JSON manually (hoặc dùng JSONArray)
            cleanResponse = cleanResponse.trim();

            // Tách từng object trong array
            if (cleanResponse.startsWith("[") && cleanResponse.endsWith("]")) {
                String content = cleanResponse.substring(1, cleanResponse.length() - 1);
                String[] objects = content.split("(?=\\{)");

                for (String obj : objects) {
                    obj = obj.trim();
                    if (obj.isEmpty()) continue;

                    // Tìm category name
                    String categoryName = extractJsonValue(obj, "categoryName");
                    String matchPercentageStr = extractJsonValue(obj, "matchPercentage");
                    String reason = extractJsonValue(obj, "reason");

                    if (categoryName != null && !categoryName.isEmpty()) {
                        // Tìm category trong database
                        Optional<Category> foundCategory = userCategories.stream()
                                .filter(c -> c.getName().equalsIgnoreCase(categoryName))
                                .findFirst();

                        if (foundCategory.isPresent()) {
                            Category cat = foundCategory.get();
                            Double percentage = 50.0; // Default
                            try {
                                percentage = Double.parseDouble(matchPercentageStr != null ? matchPercentageStr : "50");
                            } catch (NumberFormatException e) {
                                // Keep default
                            }

                            suggestions.add(new CategorySuggestionDTO(
                                    cat.getId(),
                                    cat.getName(),
                                    percentage,
                                    reason != null ? reason : "Phù hợp với mô tả"
                            ));
                        }
                    }
                }
            }

            // Sort by match percentage descending
            suggestions.sort((a, b) -> b.getMatchPercentage().compareTo(a.getMatchPercentage()));

        } catch (Exception e) {
            System.err.println("Error parsing AI response: " + e.getMessage());
        }

        return suggestions;
    }

    /**
     * Extract JSON value từ string
     */
    private String extractJsonValue(String json, String key) {
        try {
            String searchKey = "\"" + key + "\"";
            int keyIndex = json.indexOf(searchKey);
            if (keyIndex == -1) return null;

            int colonIndex = json.indexOf(":", keyIndex);
            if (colonIndex == -1) return null;

            int startIndex = colonIndex + 1;
            while (startIndex < json.length() && (json.charAt(startIndex) == ' ' || json.charAt(startIndex) == ':')) {
                startIndex++;
            }

            if (startIndex >= json.length()) return null;

            char firstChar = json.charAt(startIndex);
            String value;

            if (firstChar == '"') {
                // String value
                int endIndex = json.indexOf("\"", startIndex + 1);
                if (endIndex == -1) return null;
                value = json.substring(startIndex + 1, endIndex);
            } else {
                // Number or other value
                int endIndex = startIndex;
                while (endIndex < json.length() && json.charAt(endIndex) != ',' && json.charAt(endIndex) != '}') {
                    endIndex++;
                }
                value = json.substring(startIndex, endIndex).trim();
            }

            return value;
        } catch (Exception e) {
            return null;
        }
    }
}

