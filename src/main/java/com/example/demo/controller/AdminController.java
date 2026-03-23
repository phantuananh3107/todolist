package com.example.demo.controller;

import com.example.demo.dto.UserStatsDTO;
import com.example.demo.entity.User;
import com.example.demo.repository.TaskRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TaskRepository taskRepository;

    // 1. Xem danh sách người dùng
    @GetMapping("/users")
    public List<User> getAllUsers() {
        // Có thể ẩn password trong thực tế, nhưng hiện tại User entity trả về hết
        return userRepository.findAll();
    }

    // 2. CRUD khoá/mở khoá tài khoản người dùng
    @PutMapping("/users/{id}/toggle-status")
    public ResponseEntity<User> toggleUserStatus(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            user.setIsActive(!user.getIsActive());
            userRepository.save(user);
            return ResponseEntity.ok(user);
        }).orElse(ResponseEntity.notFound().build());
    }

    // 3. Xoá người dùng (Phần thêm cho đủ CRUD)
    @DeleteMapping("/users/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            userRepository.delete(user);
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // 4. Xem thống kê tổng số task trong hệ thống của từng người dùng
    @GetMapping("/stats/tasks")
    public List<UserStatsDTO> getUserTaskStats() {
        List<User> users = userRepository.findAll();
        return users.stream().map(user -> {
            // Đếm số lượng task của user từ TaskRepository
            // findByUserIdOrderByDueDateAsc trả về List, ta có thể lấy size()
            long taskCount = taskRepository.findByUserIdOrderByDueDateAsc(user.getId()).size();
            return new UserStatsDTO(user.getUsername(), taskCount);
        }).collect(Collectors.toList());
    }
}
