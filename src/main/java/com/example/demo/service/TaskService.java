package com.example.demo.service;

import com.example.demo.dto.CreateTaskRequest;
import com.example.demo.dto.TaskResponseDTO;
import com.example.demo.dto.UpdateTaskRequest;
import com.example.demo.entity.Category;
import com.example.demo.entity.Priority;
import com.example.demo.entity.Status;
import com.example.demo.entity.Tasks;
import com.example.demo.entity.User;
import com.example.demo.repository.CategoryRepository;
import com.example.demo.repository.TaskRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private OpenAIService openAIService;

    /**
     * Tạo công việc mới
     */
    public ResponseEntity<?> createTask(Long userId, CreateTaskRequest request) {
        // Validate
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tiêu đề công việc không được để trống!");
        }

        // Find user
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        User user = userOpt.get();

        // Find category if provided
        Category category = null;
        if (request.getCategoryId() != null) {
            Optional<Category> catOpt = categoryRepository.findById(request.getCategoryId());
            if (catOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
            }
            category = catOpt.get();

            // Kiểm tra IDOR: Category phải thuộc về user
            if (!category.getUser().getId().equals(userId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền dùng nhóm này!");
            }

            // Kiểm tra trùng tên task trong cùng category
            if (taskRepository.existsByTitleAndCategoryIdAndIsActiveTrue(request.getTitle().trim(), request.getCategoryId())) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tiêu đề công việc đã tồn tại trong nhóm này!");
            }
        }

        // Create task
        Tasks task = new Tasks();
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setUser(user);
        task.setCategory(category);
        task.setIsActive(true);
        task.setCreatedAt(LocalDateTime.now());

        // Set priority directly from Enum
        if (request.getPriority() != null) {
            task.setPriority(request.getPriority());
        }

        // Set status directly from Enum
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
        } else {
            task.setStatus(Status.TODO); // Default
        }

        task.setDueDate(request.getDueDate());

        Tasks savedTask = taskRepository.save(task);

        return ResponseEntity.status(HttpStatus.CREATED).body(new TaskResponseDTO(savedTask));
    }

    /**
     * Lấy danh sách công việc active của user
     */
    public ResponseEntity<?> getTasksByUserId(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        // Lấy chỉ tasks active từ database - sắp xếp theo ID tăng dần
        List<Tasks> tasks = taskRepository.findByUserIdAndIsActiveTrueOrderByIdAsc(userId);
        List<TaskResponseDTO> result = tasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Lấy chi tiết một công việc
     */
    public ResponseEntity<?> getTaskById(Long taskId, Long userId) {
        Optional<Tasks> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Công việc không tồn tại!");
        }

        Tasks task = taskOpt.get();

        // IDOR check: Chỉ user sở hữu task mới được xem
        if (!task.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền xem công việc này!");
        }

        return ResponseEntity.ok(new TaskResponseDTO(task));
    }

    /**
     * Cập nhật công việc
     */
    public ResponseEntity<?> updateTask(Long taskId, Long userId, UpdateTaskRequest request) {
        Optional<Tasks> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Công việc không tồn tại!");
        }

        Tasks task = taskOpt.get();

        // IDOR check
        if (!task.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền sửa công việc này!");
        }

        // Update fields
        if (request.getTitle() != null && !request.getTitle().trim().isEmpty()) {
            // Nếu update category hoặc title, cần kiểm tra trùng tên
            Long checkCategoryId = request.getCategoryId() != null ? request.getCategoryId() : (task.getCategory() != null ? task.getCategory().getId() : null);
            
            if (checkCategoryId != null) {
                // Kiểm tra trùng tên task trong category (nếu title mới khác title cũ)
                if (!task.getTitle().equals(request.getTitle().trim())) {
                    if (taskRepository.existsByTitleAndCategoryIdAndIsActiveTrue(request.getTitle().trim(), checkCategoryId)) {
                        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tiêu đề công việc đã tồn tại trong nhóm này!");
                    }
                }
            }
            task.setTitle(request.getTitle());
        }

        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }

        if (request.getPriority() != null) {
            task.setPriority(request.getPriority());
        }

        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
        }

        if (request.getDueDate() != null) {
            task.setDueDate(request.getDueDate());
        }

        // Update category
        if (request.getCategoryId() != null) {
            Optional<Category> catOpt = categoryRepository.findById(request.getCategoryId());
            if (catOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
            }
            Category category = catOpt.get();
            if (!category.getUser().getId().equals(userId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền dùng nhóm này!");
            }
            task.setCategory(category);
        }

        Tasks updated = taskRepository.save(task);

        return ResponseEntity.ok(new TaskResponseDTO(updated));
    }

    /**
     * Xóa công việc (soft delete)
     */
    public ResponseEntity<?> deleteTask(Long taskId, Long userId) {
        Optional<Tasks> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Công việc không tồn tại!");
        }

        Tasks task = taskOpt.get();

        // IDOR check
        if (!task.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền xóa công việc này!");
        }

        // Soft delete
        task.setIsActive(false);
        taskRepository.save(task);

        return ResponseEntity.ok("Xóa công việc thành công!");
    }

    /**
     * Tìm kiếm công việc theo từ khóa
     */
    public ResponseEntity<?> searchTasks(String keyword, Long userId) {
        List<Tasks> allTasks = taskRepository.findByTitleContainingIgnoreCase(keyword);
        List<TaskResponseDTO> result = allTasks.stream()
                .filter(t -> t.getUser().getId().equals(userId) && t.getIsActive())
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Tìm kiếm công việc với các tùy chọn filter (priority, status)
     */
    public ResponseEntity<?> searchTasksWithFilters(String keyword, String priority, String status, Long userId) {
        List<Tasks> tasks = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);

        // Filter theo keyword nếu có (chỉ search theo title)
        if (keyword != null && !keyword.trim().isEmpty()) {
            tasks = tasks.stream()
                    .filter(t -> t.getTitle().toLowerCase().contains(keyword.toLowerCase()))
                    .collect(Collectors.toList());
        }

        // Filter theo priority nếu có
        if (priority != null && !priority.trim().isEmpty()) {
            try {
                Priority priorityEnum = Priority.valueOf(priority.toUpperCase());
                tasks = tasks.stream()
                        .filter(t -> t.getPriority() == priorityEnum)
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Ưu tiên không hợp lệ! (LOW, MEDIUM, HIGH)");
            }
        }

        // Filter theo status nếu có
        if (status != null && !status.trim().isEmpty()) {
            try {
                Status statusEnum = Status.valueOf(status.toUpperCase());
                tasks = tasks.stream()
                        .filter(t -> t.getStatus() == statusEnum)
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Trạng thái không hợp lệ! (TODO, DOING, DONE, OVERDUE)");
            }
        }

        List<TaskResponseDTO> result = tasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Lấy công việc theo trạng thái
     */
    public ResponseEntity<?> getTasksByStatus(Long userId, String status) {
        try {
            Status statusEnum = Status.valueOf(status.toUpperCase());
            List<Tasks> tasks = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);
            List<TaskResponseDTO> result = tasks.stream()
                    .filter(t -> t.getStatus() == statusEnum)
                    .map(TaskResponseDTO::new)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Trạng thái không hợp lệ!");
        }
    }

    /**
     * Lấy công việc theo ưu tiên
     */
    public ResponseEntity<?> getTasksByPriority(Long userId, String priority) {
        try {
            Priority priorityEnum = Priority.valueOf(priority.toUpperCase());
            List<Tasks> tasks = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);
            List<TaskResponseDTO> result = tasks.stream()
                    .filter(t -> t.getPriority() == priorityEnum)
                    .map(TaskResponseDTO::new)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Ưu tiên không hợp lệ!");
        }
    }

    /**
     * Lấy công việc quá hạn
     */
    public ResponseEntity<?> getOverdueTasks(Long userId) {
        List<Tasks> tasks = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);
        LocalDateTime now = LocalDateTime.now();
        List<TaskResponseDTO> result = tasks.stream()
                .filter(t -> t.getDueDate() != null && 
                           t.getDueDate().isBefore(now) &&
                           t.getStatus() != Status.DONE)
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Lấy công việc theo nhóm
     */
    public ResponseEntity<?> getTasksByCategory(Long userId, Long categoryId) {
        Optional<Category> catOpt = categoryRepository.findById(categoryId);
        if (catOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
        }

        Category category = catOpt.get();

        // IDOR check
        if (!category.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền xem nhóm này!");
        }

        // Lấy task từ repository thay vì entity relationship để tránh lazy loading issues
        List<Tasks> tasks = taskRepository.findByCategoryIdAndIsActiveTrue(categoryId);
        List<TaskResponseDTO> result = tasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Lấy danh sách công việc được sắp xếp bởi AI (Gợi ý bởi AI)
     */
    public ResponseEntity<?> getAISuggestedOrder(Long userId) {
        // 1. Lấy tasks active (TODO, DOING, OVERDUE)
        List<Tasks> allActive = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);
        List<Tasks> activeTasks = allActive.stream()
                .filter(t -> t.getStatus() != Status.DONE)
                .collect(Collectors.toList());

        if (activeTasks.isEmpty()) {
            return ResponseEntity.ok(new ArrayList<>());
        }

        // 2. Lấy một số tasks hoàn thành để làm lịch sử (Context)
        List<Tasks> doneTasks = taskRepository.findByUserIdAndStatusAndIsActiveTrue(userId, Status.DONE);
        List<Tasks> history = doneTasks.stream().limit(10).collect(Collectors.toList());

        // 3. Xây dựng prompt cho AI
        StringBuilder prompt = new StringBuilder();
        prompt.append("Dựa trên mức độ ưu tiên (HIGH > MEDIUM > LOW), thời hạn (due date) và lịch sử hoàn thành, hãy sắp xếp danh sách công việc sau đây theo thứ tự nên thực hiện từ trên xuống dưới:\n\n");
        
        for (Tasks t : activeTasks) {
            prompt.append(String.format("- ID: %d | Tiêu đề: %s | Ưu tiên: %s | Hạn: %s | Trạng thái: %s\n",
                    t.getId(), t.getTitle(), t.getPriority(), t.getDueDate(), t.getStatus()));
        }

        if (!history.isEmpty()) {
            prompt.append("\nLịch sử các công việc đã hoàn thành gần đây:\n");
            for (Tasks t : history) {
                prompt.append(String.format("- %s (Ưu tiên: %s)\n", t.getTitle(), t.getPriority()));
            }
        }

        prompt.append("\nYêu cầu quan trọng: CHỈ TRẢ VỀ một mảng JSON chứa các ID của công việc đã sắp xếp (ví dụ: [102, 105, 101]). Không giải thích, không thêm văn bản gì khác.");

        // 4. Gọi OpenAI API qua OpenAIService
        String aiResponse = openAIService.getResponseFromAI(prompt.toString());
        
        if (aiResponse == null || aiResponse.startsWith("Lỗi")) {
            // Fallback nếu AI lỗi
            return ResponseEntity.ok(activeTasks.stream().map(TaskResponseDTO::new).collect(Collectors.toList()));
        }

        try {
            // Làm sạch response (loại bỏ markdown nếu có)
            String jsonPart = aiResponse.replaceAll("```json|```", "").trim();
            
            ObjectMapper mapper = new ObjectMapper();
            List<Long> orderedIds = mapper.readValue(jsonPart, new TypeReference<List<Long>>() {});
            
            // 5. Sắp xếp lại danh sách dựa trên thứ tự IDs từ AI
            Map<Long, Tasks> taskMap = activeTasks.stream().collect(Collectors.toMap(Tasks::getId, t -> t));
            List<Tasks> sortedTasks = new ArrayList<>();
            
            for (Object idObj : orderedIds) {
                Long id = Long.valueOf(idObj.toString());
                if (taskMap.containsKey(id)) {
                    sortedTasks.add(taskMap.get(id));
                    taskMap.remove(id);
                }
            }
            
            // Thêm các task còn sót lại mà AI có thể đã quên
            sortedTasks.addAll(taskMap.values());

            List<TaskResponseDTO> result = sortedTasks.stream()
                    .map(TaskResponseDTO::new)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            // Fallback: Trả về danh sách mặc định nếu parse JSON thất bại
            List<TaskResponseDTO> result = activeTasks.stream()
                    .map(TaskResponseDTO::new)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(result);
        }
    }

    /**
     * Sắp xếp lại thứ tự ưu tiên làm task của user
     * Endpoint: POST /api/tasks/reorder
     * 
     * Request: {
     *   "tasks": [
     *     {"taskId": 3, "orderIndex": 1},
     *     {"taskId": 1, "orderIndex": 2},
     *     {"taskId": 2, "orderIndex": 3}
     *   ]
     * }
     */
    public ResponseEntity<?> reorderTasks(Long userId, com.example.demo.dto.ReorderTaskRequest request) {
        // Validate
        if (request.getTasks() == null || request.getTasks().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Danh sách task không được để trống!");
        }

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        // Update orderIndex cho từng task
        for (com.example.demo.dto.ReorderTaskRequest.TaskOrderItem item : request.getTasks()) {
            Tasks task = taskRepository.findByIdAndUserId(item.getTaskId(), userId);
            
            // IDOR check: Chỉ user sở hữu task mới được sắp xếp
            if (task == null) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("Công việc với ID " + item.getTaskId() + " không tồn tại hoặc không thuộc về bạn!");
            }

            task.setOrderIndex(item.getOrderIndex());
            taskRepository.save(task);
        }

        // Trả về danh sách task đã sắp xếp theo orderIndex (chế độ reorder)
        List<Tasks> reorderedTasks = taskRepository.findByUserIdAndIsActiveTrueOrderByOrderIndexAscIdAsc(userId);
        List<TaskResponseDTO> result = reorderedTasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(Map.of(
                "message", "Sắp xếp công việc thành công!",
                "tasks", result
        ));
    }
}

