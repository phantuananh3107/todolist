package com.example.demo.controller;

import com.example.demo.dto.CreateCategoryRequest;
import com.example.demo.service.CategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/categories")
@PreAuthorize("isAuthenticated()")  // Yêu cầu đăng nhập
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    /**
     * Tạo nhóm công việc mới
     * POST /api/categories
     */
    @PostMapping
    public ResponseEntity<?> createCategory(@RequestBody CreateCategoryRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.createCategory(Long.parseLong(userId), request);
    }

    /**
     * Lấy danh sách nhóm của user hiện tại
     * GET /api/categories
     */
    @GetMapping
    public ResponseEntity<?> getCategories() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.getCategoriesByUserId(Long.parseLong(userId));
    }

    /**
     * Lấy chi tiết một nhóm
     * GET /api/categories/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getCategoryById(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.getCategoryById(id, Long.parseLong(userId));
    }

    /**
     * Cập nhật nhóm
     * PATCH /api/categories/{id}
     */
    @PatchMapping("/{id}")
    public ResponseEntity<?> updateCategory(
            @PathVariable Long id,
            @RequestBody CreateCategoryRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.updateCategory(id, Long.parseLong(userId), request);
    }

    /**
     * Xóa nhóm
     * DELETE /api/categories/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCategory(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.deleteCategory(id, Long.parseLong(userId));
    }

    /**
     * Tìm kiếm nhóm theo tên
     * GET /api/categories/search?keyword=...
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchCategories(@RequestParam String keyword) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.searchCategories(keyword, Long.parseLong(userId));
    }

    /**
     * Khôi phục nhóm đã bị xoá
     * PATCH /api/categories/{id}/restore
     */
    @PatchMapping("/{id}/restore")
    public ResponseEntity<?> restoreCategory(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.restoreCategory(id, Long.parseLong(userId));
    }
}

