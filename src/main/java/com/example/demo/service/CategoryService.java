package com.example.demo.service;

import com.example.demo.dto.CategoryResponseDTO;
import com.example.demo.dto.TaskResponseDTO;
import com.example.demo.dto.CreateCategoryRequest;
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

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class CategoryService {

    private String normalizeColorHex(String rawColorHex) {
        if (rawColorHex == null || rawColorHex.trim().isEmpty()) {
            return null;
        }

        String normalized = rawColorHex.trim().toUpperCase(Locale.ROOT);
        if (!normalized.startsWith("#")) {
            normalized = "#" + normalized;
        }

        if (!normalized.matches("^#[0-9A-F]{6}$")) {
            throw new IllegalArgumentException("Màu category không hợp lệ! Dùng định dạng #RRGGBB.");
        }

        return normalized;
    }


    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TaskRepository taskRepository;

    /**
     * Tạo nhóm công việc mới
     */
    public ResponseEntity<?> createCategory(Long userId, CreateCategoryRequest request) {
        // Validate
        if (request.getName() == null || request.getName().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tên nhóm không được để trống!");
        }

        // Find user
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        User user = userOpt.get();

        // Kiểm tra trùng tên Category cho user này
        if (categoryRepository.existsByNameAndUserIdAndIsActiveTrue(request.getName().trim(), userId)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tên nhóm đã tồn tại!");
        }

        final String normalizedColorHex;
        try {
            normalizedColorHex = normalizeColorHex(request.getColorHex());
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ex.getMessage());
        }

        // Create category
        Category category = new Category();
        category.setName(request.getName().trim());
        category.setColorHex(normalizedColorHex);
        category.setUser(user);
        category.setIsActive(true);

        Category savedCategory = categoryRepository.save(category);

        return ResponseEntity.status(HttpStatus.CREATED).body(new CategoryResponseDTO(savedCategory));
    }

    /**
     * Lấy danh sách nhóm active của user
     */
    public ResponseEntity<?> getCategoriesByUserId(Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        // Lấy chỉ categories active từ database
        List<Category> categories = categoryRepository.findByUserIdAndIsActiveTrue(userId);
        List<CategoryResponseDTO> result = categories.stream()
                .map(CategoryResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * Lấy chi tiết một nhóm (bao gồm danh sách tasks trong nhóm)
     */
    public ResponseEntity<?> getCategoryById(Long categoryId, Long userId) {
        Optional<Category> categoryOpt = categoryRepository.findById(categoryId);
        if (categoryOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
        }

        Category category = categoryOpt.get();

        // Kiểm tra IDOR: Chỉ user sở hữu category mới được xem
        if (!category.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền xem nhóm này!");
        }

        // Lấy danh sách tasks từ repository thay vì entity relationship
        List<Tasks> tasks = taskRepository.findByCategoryIdAndIsActiveTrue(categoryId);
        List<TaskResponseDTO> taskDTOs = tasks.stream()
                .map(TaskResponseDTO::new)
                .collect(Collectors.toList());

        // Build response DTO
        java.util.LinkedHashMap<String, Object> response = new java.util.LinkedHashMap<>();
        response.put("id", category.getId());
        response.put("name", category.getName());
        response.put("isActive", category.getIsActive());
        response.put("colorHex", category.getColorHex());
        response.put("tasks", taskDTOs);
        response.put("taskCount", (long) taskDTOs.size());

        return ResponseEntity.ok(response);
    }

    /**
     * Cập nhật nhóm
     */
    public ResponseEntity<?> updateCategory(Long categoryId, Long userId, CreateCategoryRequest request) {
        if (request.getName() == null || request.getName().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tên nhóm không được để trống!");
        }

        Optional<Category> categoryOpt = categoryRepository.findById(categoryId);
        if (categoryOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
        }

        Category category = categoryOpt.get();

        // IDOR check
        if (!category.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền sửa nhóm này!");
        }

        // Kiểm tra trùng tên Category (nếu tên mới khác tên cũ)
        if (!category.getName().equals(request.getName().trim())) {
            if (categoryRepository.existsByNameAndUserIdAndIsActiveTrue(request.getName().trim(), userId)) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tên nhóm đã tồn tại!");
            }
        }

        final String normalizedColorHex;
        try {
            normalizedColorHex = normalizeColorHex(request.getColorHex());
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ex.getMessage());
        }

        category.setName(request.getName().trim());
        category.setColorHex(normalizedColorHex);
        Category updated = categoryRepository.save(category);

        return ResponseEntity.ok(new CategoryResponseDTO(updated));
    }

    /**
     * Xóa nhóm (soft delete)
     */
    public ResponseEntity<?> deleteCategory(Long categoryId, Long userId) {
        Optional<Category> categoryOpt = categoryRepository.findById(categoryId);
        if (categoryOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
        }

        Category category = categoryOpt.get();

        // IDOR check
        if (!category.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền xóa nhóm này!");
        }

        // Soft delete category
        category.setIsActive(false);
        categoryRepository.save(category);

        // Cascade soft delete: xóa tất cả task active của category này
        List<Tasks> activeTasks = taskRepository.findByCategoryIdAndIsActiveTrue(categoryId);
        for (Tasks task : activeTasks) {
            task.setIsActive(false);
            taskRepository.save(task);
        }

        return ResponseEntity.ok("Xóa nhóm thành công!");
    }

    /**
     * Khôi phục nhóm đã bị xoá
     */
    public ResponseEntity<?> restoreCategory(Long categoryId, Long userId) {
        Optional<Category> categoryOpt = categoryRepository.findById(categoryId);
        if (categoryOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhóm không tồn tại!");
        }

        Category category = categoryOpt.get();

        // IDOR check
        if (!category.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền khôi phục nhóm này!");
        }

        if (Boolean.TRUE.equals(category.getIsActive())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Nhóm này hiện đang hoạt động!");
        }

        // Kiểm tra xem có một category khác cùng tên đang active không
        if (categoryRepository.existsByNameAndUserIdAndIsActiveTrue(category.getName(), userId)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Tên nhóm này (" + category.getName() + ") đã được sử dụng bởi một nhóm khác đang hoạt động. Vui lòng đổi tên hoặc xoá nhóm hiện có trước khi khôi phục nhóm này!");
        }

        category.setIsActive(true);
        categoryRepository.save(category);

        // Cascade restore: Khôi phục toàn bộ các công việc thuộc nhóm này
        List<Tasks> tasksInGroup = taskRepository.findByCategoryId(categoryId);
        for (Tasks task : tasksInGroup) {
            task.setIsActive(true);
            taskRepository.save(task);
        }

        return ResponseEntity.ok(new CategoryResponseDTO(category));
    }

    /**
     * Tìm kiếm nhóm theo tên
     */
    public ResponseEntity<?> searchCategories(String keyword, Long userId) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Người dùng không tồn tại!");
        }

        List<Category> categories = categoryRepository.findByNameContainingIgnoreCaseAndUserIdAndIsActiveTrue(keyword, userId);
        List<CategoryResponseDTO> result = categories.stream()
                .map(CategoryResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }
}

