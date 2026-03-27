package com.example.demo.controller;

import com.example.demo.dto.AdminUserRequest;
import com.example.demo.dto.UserResponseDTO;
import com.example.demo.entity.User;
import com.example.demo.repository.TaskRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // 1. Xem danh sách người dùng (ẩn password trước khi trả về)
    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<UserResponseDTO>> getAllUsers(
            @RequestParam(defaultValue = "") String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit
    ) {
        String currentUserId = SecurityContextHolder.getContext().getAuthentication().getName();
        Long adminId = Long.parseLong(currentUserId);
        
        // Spring Pageable tính từ 0, nên page 1 -> index 0
        Pageable pageable = PageRequest.of(page - 1, limit);
        
        Page<User> userPage = userRepository.searchUsers(keyword, adminId, pageable);
        
        // Chuyển đổi Page<User> sang Page<UserResponseDTO>
        Page<UserResponseDTO> result = userPage.map(UserResponseDTO::new);
        
        return ResponseEntity.ok(result);
    }

    // 2. Khoá tài khoản người dùng (PATCH)
    @PatchMapping("/users/{id}/lock")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserResponseDTO> lockUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            user.setIsActive(false);
            userRepository.save(user);
            return ResponseEntity.ok(new UserResponseDTO(user));
        }).orElse(ResponseEntity.notFound().build());
    }

    // 3. Mở khoá tài khoản người dùng (PATCH)
    @PatchMapping("/users/{id}/unlock")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserResponseDTO> unlockUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            user.setIsActive(true);
            userRepository.save(user);
            return ResponseEntity.ok(new UserResponseDTO(user));
        }).orElse(ResponseEntity.notFound().build());
    }

    // 3.5 Xoá mềm người dùng (PATCH)
    @PatchMapping("/users/{id}/soft-delete")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserResponseDTO> softDeleteUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            user.setIsDeleted(true);
            user.setIsActive(false); // Khi xoá mềm thì cũng khoá luôn
            userRepository.save(user);
            return ResponseEntity.ok(new UserResponseDTO(user));
        }).orElse(ResponseEntity.notFound().build());
    }

    // 4. Xoá cứng người dùng (Xoá hẳn khỏi Database)
    @DeleteMapping("/users/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            userRepository.delete(user);
            return ResponseEntity.ok("Xóa người dùng thành công!");
        }).orElse(ResponseEntity.notFound().build());
    }

    // 5. Xem thống kê chi tiết (gồm Category và Task) của từng người dùng
    @GetMapping("/stats/tasks")
    public List<UserResponseDTO> getUserTaskStats() {
        // Lấy tất cả user chưa xoá (ngoại trừ chính mình nếu cần, nhưng thường stats thì lấy hết)
        List<User> users = userRepository.findAll().stream()
                .filter(u -> u.getIsDeleted() == null || !u.getIsDeleted())
                .toList();
        
        return users.stream()
                .map(UserResponseDTO::new)
                .toList();
    }

    // --- MỚI: FULL CRUD CHO ADMIN ---

    // 6. Tạo người dùng mới (Admin có thể gán luôn Role)
    @PostMapping("/users")
    public ResponseEntity<?> createUser(@RequestBody AdminUserRequest request) {
        if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Username không được để trống!");
        }
        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            return ResponseEntity.badRequest().body("Username đã tồn tại!");
        }
        if (request.getEmail() != null && userRepository.findByEmail(request.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email đã tồn tại!");
        }

        // Kiểm tra xác nhận mật khẩu
        if (request.getPassword() != null && !request.getPassword().equals(request.getConfirmPassword())) {
            return ResponseEntity.badRequest().body("Xác nhận mật khẩu không khớp!");
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());

        // Mã hóa mật khẩu nếu có gửi lên, nếu không để mặc định 123456
        String rawPassword = (request.getPassword() != null) ? request.getPassword() : "123456";
        user.setPassword(passwordEncoder.encode(rawPassword));

        user.setRole(request.getRole() != null ? request.getRole() : "USER");
        user.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);

        User savedUser = userRepository.save(user);
        return ResponseEntity.ok(new UserResponseDTO(savedUser));
    }

    // 7. Cập nhật thông tin bất kỳ User nào (PATCH)
    @PatchMapping("/users/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody AdminUserRequest details) {
        return userRepository.findById(id).map(user -> {
            if (details.getUsername() != null) {
                user.setUsername(details.getUsername());
            }
            if (details.getEmail() != null) {
                user.setEmail(details.getEmail());
            }
            if (details.getRole() != null) {
                user.setRole(details.getRole());
            }
            if (details.getIsActive() != null) {
                user.setIsActive(details.getIsActive());
            }
            // Admin cũng có thể đổi mật khẩu nếu cần
            if (details.getPassword() != null && !details.getPassword().trim().isEmpty()) {
                if (!details.getPassword().equals(details.getConfirmPassword())) {
                    return ResponseEntity.badRequest().body("Xác nhận mật khẩu mới không khớp!");
                }
                user.setPassword(passwordEncoder.encode(details.getPassword()));
            }

            User updatedUser = userRepository.save(user);
            return ResponseEntity.ok(new UserResponseDTO(updatedUser));
        }).orElse(ResponseEntity.notFound().build());
    }
}
