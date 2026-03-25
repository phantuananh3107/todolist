package com.example.demo.service;

import com.example.demo.dto.CreateTaskRequest;
import com.example.demo.dto.TaskResponseDTO;
import com.example.demo.dto.UpdateTaskRequest;
import com.example.demo.entity.Category;
import com.example.demo.entity.Tasks;
import com.example.demo.entity.User;
import com.example.demo.repository.CategoryRepository;
import com.example.demo.repository.TaskRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
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
        }

        // Create task
        Tasks task = new Tasks();
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setUser(user);
        task.setCategory(category);
        task.setIsActive(true);
        task.setCreatedAt(LocalDateTime.now());

        // Parse priority
        if (request.getPriority() != null) {
            try {
                task.setPriority(Tasks.Priority.valueOf(request.getPriority().toUpperCase()));
            } catch (IllegalArgumentException e) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Ưu tiên không hợp lệ! (LOW, MEDIUM, HIGH)");
            }
        }

        // Parse status
        if (request.getStatus() != null) {
            try {
                task.setStatus(Tasks.Status.valueOf(request.getStatus().toUpperCase()));
            } catch (IllegalArgumentException e) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Trạng thái không hợp lệ! (TODO, DOING, DONE, OVERDUE)");
            }
        } else {
            task.setStatus(Tasks.Status.TODO); // Default
        }

        task.setDueDate(request.getDueDate());

        Tasks savedTask = taskRepository.save(task);

        return ResponseEntity.status(HttpStatus.CREATED).body(new TaskResponseDTO(savedTask));
    }

    /**
     * Lấy danh sách công việc của user
     */
    public ResponseEntity<?> getTasksByUserId(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        List<Tasks> tasks = taskRepository.findByUserIdOrderByDueDateAsc(userId);
        List<TaskResponseDTO> result = tasks.stream()
                .filter(Tasks::getIsActive)  // Chỉ lấy task active
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
            task.setTitle(request.getTitle());
        }

        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }

        if (request.getPriority() != null) {
            try {
                task.setPriority(Tasks.Priority.valueOf(request.getPriority().toUpperCase()));
            } catch (IllegalArgumentException e) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Ưu tiên không hợp lệ!");
            }
        }

        if (request.getStatus() != null) {
            try {
                task.setStatus(Tasks.Status.valueOf(request.getStatus().toUpperCase()));
            } catch (IllegalArgumentException e) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Trạng thái không hợp lệ!");
            }
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
     * Lấy công việc theo trạng thái
     */
    public ResponseEntity<?> getTasksByStatus(Long userId, String status) {
        try {
            Tasks.Status statusEnum = Tasks.Status.valueOf(status.toUpperCase());
            List<Tasks> tasks = taskRepository.findByUserIdOrderByDueDateAsc(userId);
            List<TaskResponseDTO> result = tasks.stream()
                    .filter(t -> t.getStatus() == statusEnum && t.getIsActive())
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
            Tasks.Priority priorityEnum = Tasks.Priority.valueOf(priority.toUpperCase());
            List<Tasks> tasks = taskRepository.findByUserIdOrderByDueDateAsc(userId);
            List<TaskResponseDTO> result = tasks.stream()
                    .filter(t -> t.getPriority() == priorityEnum && t.getIsActive())
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
        List<Tasks> tasks = taskRepository.findByUserIdOrderByDueDateAsc(userId);
        LocalDateTime now = LocalDateTime.now();
        List<TaskResponseDTO> result = tasks.stream()
                .filter(t -> t.getIsActive() && 
                           t.getDueDate() != null && 
                           t.getDueDate().isBefore(now) &&
                           t.getStatus() != Tasks.Status.DONE)
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

        List<TaskResponseDTO> result = category.getTasks().stream()
                .filter(Tasks::getIsActive)
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }
}

