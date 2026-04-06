package com.example.demo.controller;

import com.example.demo.dto.CreateCategoryRequest;
import com.example.demo.dto.CategorySuggestionRequest;
import com.example.demo.service.CategoryService;
import com.example.demo.service.CategorySuggestionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/categories")
@PreAuthorize("isAuthenticated()")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private CategorySuggestionService categorySuggestionService;

    @PostMapping
    public ResponseEntity<?> createCategory(@RequestBody CreateCategoryRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.createCategory(Long.parseLong(userId), request);
    }

    @GetMapping
    public ResponseEntity<?> getCategories() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.getCategoriesByUserId(Long.parseLong(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getCategoryById(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.getCategoryById(id, Long.parseLong(userId));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<?> updateCategory(
            @PathVariable Long id,
            @RequestBody CreateCategoryRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.updateCategory(id, Long.parseLong(userId), request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCategory(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.deleteCategory(id, Long.parseLong(userId));
    }

    @PostMapping("/suggest")
    public ResponseEntity<?> suggestCategory(@RequestBody CategorySuggestionRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(categorySuggestionService.suggestCategories(Long.parseLong(userId), request));
    }

    @GetMapping("/search")
    public ResponseEntity<?> searchCategories(@RequestParam String keyword) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.searchCategories(keyword, Long.parseLong(userId));
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<?> restoreCategory(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return categoryService.restoreCategory(id, Long.parseLong(userId));
    }
}

