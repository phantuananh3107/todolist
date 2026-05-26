package com.example.demo.service;

import com.example.demo.dto.ChatRequest;
import com.example.demo.entity.Tasks;
import com.example.demo.repository.TaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ChatService {

    @Autowired
    private OpenAIService openAIService;

    @Autowired
    private TaskRepository taskRepository;

    /**
     * Xử lý yêu cầu chat, bổ sung ngữ cảnh là danh sách công việc hiện tại.
     */
    public String generateChatResponse(Long userId, ChatRequest request) {
        // 1. Lấy thông tin ngữ cảnh về các task hiện tại của user
        List<Tasks> activeTasks = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);
        
        StringBuilder context = new StringBuilder();
        context.append("Bạn là trợ lý AI thông minh của ứng dụng TodoList. Dưới đây là danh sách công việc hiện tại của người dùng:\n");
        
        if (activeTasks.isEmpty()) {
            context.append("- Người dùng hiện không có công việc nào trong danh sách.\n");
        } else {
            for (Tasks t : activeTasks) {
                context.append(String.format("- %s | Trạng thái: %s | Ưu tiên: %s | Hạn chót: %s\n",
                        t.getTitle(), t.getStatus(), t.getPriority(), t.getDueDate()));
            }
        }
        
        context.append("\nHãy trả lời bằng tiếng Việt một cách thân thiện, ngắn gọn. ");
        context.append("Nếu người dùng hỏi về công việc của họ, hãy dựa vào danh sách trên để trả lời. ");
        context.append("Ngoài ra, bạn có thể đưa ra lời khuyên để họ làm việc hiệu quả hơn.");

        // 2. Gọi OpenAI với lịch sử chat và ngữ cảnh hệ thống
        return openAIService.getChatResponse(request.getMessages(), context.toString());
    }
}
