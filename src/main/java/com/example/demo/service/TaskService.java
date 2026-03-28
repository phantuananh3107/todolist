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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Stream;
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
     * Lấy danh sách công việc active của user
     */
    public ResponseEntity<?> getTasksByUserId(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        // Lấy chỉ tasks active từ database
        List<Tasks> tasks = taskRepository.findByUserIdAndIsActiveTrueOrderByDueDateAsc(userId);
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
                Tasks.Priority priorityEnum = Tasks.Priority.valueOf(priority.toUpperCase());
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
                Tasks.Status statusEnum = Tasks.Status.valueOf(status.toUpperCase());
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
            Tasks.Status statusEnum = Tasks.Status.valueOf(status.toUpperCase());
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
            Tasks.Priority priorityEnum = Tasks.Priority.valueOf(priority.toUpperCase());
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

        // Lấy task từ repository thay vì entity relationship để tránh lazy loading issues
        List<Tasks> tasks = taskRepository.findByCategoryIdAndIsActiveTrue(categoryId);
        List<TaskResponseDTO> result = tasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Lấy danh sách công việc theo 1 ngày (theo dueDate)
     */
    public ResponseEntity<?> getTasksByDate(Long userId, LocalDate date) {
        if (date == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("date không hợp lệ!");
        }

        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = date.plusDays(1).atStartOfDay(); // nửa mở: start <= dueDate < end

        List<Tasks> tasks = taskRepository.findActiveTasksByUserIdDueDateRange(userId, start, end);
        List<TaskResponseDTO> result = tasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Calendar view: trả về task theo từng ngày trong khoảng [startDate, endDate]
     */
    public ResponseEntity<?> getTasksCalendar(Long userId, LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("startDate/endDate không hợp lệ!");
        }
        if (endDate.isBefore(startDate)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("endDate phải >= startDate!");
        }

        LocalDateTime start = startDate.atStartOfDay();
        LocalDateTime end = endDate.plusDays(1).atStartOfDay(); // nửa mở

        List<Tasks> tasks = taskRepository.findActiveTasksByUserIdDueDateRange(userId, start, end);

        Map<LocalDate, List<Tasks>> grouped = tasks.stream()
                .filter(t -> t.getDueDate() != null)
                .collect(Collectors.groupingBy(t -> t.getDueDate().toLocalDate()));

        List<com.example.demo.dto.TaskCalendarDayDTO> days = Stream.iterate(startDate, d -> !d.isAfter(endDate), d -> d.plusDays(1))
                .map(d -> {
                    List<TaskResponseDTO> dayTasks = grouped.getOrDefault(d, List.of())
                            .stream()
                            .map(TaskResponseDTO::new)
                            .collect(Collectors.toList());
                    return new com.example.demo.dto.TaskCalendarDayDTO(d, dayTasks);
                })
                .collect(Collectors.toList());

        com.example.demo.dto.TaskCalendarResponseDTO response =
                new com.example.demo.dto.TaskCalendarResponseDTO(startDate, endDate, days);

        return ResponseEntity.ok(response);
    }
}

