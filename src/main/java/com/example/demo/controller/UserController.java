package com.example.demo.controller;

import com.example.demo.dto.ChangePasswordRequest;
import com.example.demo.dto.LoginRequest;
import com.example.demo.dto.RegisterRequest;
import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.UpdateProfileRequest;
import com.example.demo.dto.UserResponseDTO;
import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import com.example.demo.service.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // 1. Đăng ký tài khoản mới
    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody RegisterRequest request) {
        if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Username không được để trống!");
        }
        if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Password không được để trống!");
        }
        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Username đã tồn tại!");
        }
        if (request.getEmail() != null && userRepository.findByEmail(request.getEmail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Email đã tồn tại!");
        }
        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));

        // FIX: Không bao giờ cho phép Client gửi role (như "ADMIN") lên lúc đăng ký để
        // tránh lỗ hổng leo thang đặc quyền. Mặc định gán là USER.
        user.setRole("USER");
        user.setIsActive(true);

        userRepository.save(user);

        // Sử dụng DTO để không làm lộ password (dù là mã hoá) ra response JSON
        return ResponseEntity.ok(new UserResponseDTO(user));
    }

    // 2. Đăng nhập
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        Optional<User> userOpt = userRepository.findByEmail(loginRequest.getEmail());
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            // Cho phép đăng nhập bằng cả mật khẩu mã hoá hoặc mật khẩu thô (fallback cho dữ
            // liệu cũ)
            if (passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())
                    || loginRequest.getPassword().equals(user.getPassword())) {
                if (Boolean.TRUE.equals(user.getIsDeleted())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Tài khoản này đã bị xoá!");
                }
                if (Boolean.FALSE.equals(user.getIsActive())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Tài khoản đã bị khoá!");
                }
                // Generate tokens — nhúng tokenVersion vào JWT để kiểm tra khi logout
                int version = user.getTokenVersion() != null ? user.getTokenVersion() : 0;
                String accessToken = jwtService.generateAccessToken(user.getId().toString(), user.getRole(), version);
                String refreshToken = jwtService.generateRefreshToken(user.getId().toString(), version);

                return ResponseEntity.ok(new LoginResponse(
                        accessToken,
                        refreshToken,
                        user.getUsername(),
                        user.getRole(),
                        user.getEmail()));
            }
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Sai email hoặc password!");
    }

    // 3. Đăng xuất — Tăng tokenVersion trong DB để vô hiệu hóa TẤT CẢ token cũ
    @PostMapping("/logout")
    public ResponseEntity<String> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.badRequest().body("Thiếu Authorization header!");
        }

        String token = authHeader.substring(7);
        if (!jwtService.validateAccessToken(token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Token không hợp lệ!");
        }

        String userId = jwtService.extractUserId(token);
        userRepository.findById(Long.parseLong(userId)).ifPresent(user -> {
            // Tăng tokenVersion lên 1 → tất cả token cũ (có version thấp hơn) bị từ chối
            int newVersion = (user.getTokenVersion() != null ? user.getTokenVersion() : 0) + 1;
            user.setTokenVersion(newVersion);
            userRepository.save(user);
            System.out.println("DEBUG LOGOUT: User " + userId + " — tokenVersion tăng lên " + newVersion);
        });

        return ResponseEntity.ok("Đăng xuất thành công!");
    }

    // 4. Cập nhật thông tin cá nhân (PATCH để cập nhật từng phần)
    @PatchMapping("/profile/{id}")
    public ResponseEntity<?> updateProfile(@PathVariable Long id, @RequestBody UpdateProfileRequest details) {
        String currentUserId = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findById(id).map(user -> {
            // FIX LỖI IDOR: Chặn không cho người khác cập nhật User này
            if (!user.getId().toString().equals(currentUserId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("Lỗi bảo mật: Bạn không có quyền sửa thông tin của người khác!");
            }

            if (details.getUsername() != null && !details.getUsername().equals(user.getUsername())) {
                Optional<User> existUser = userRepository.findByUsername(details.getUsername());
                if (existUser.isPresent()) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Username đã tồn tại!");
                }
                user.setUsername(details.getUsername());
            }

            if (details.getEmail() != null && !details.getEmail().equals(user.getEmail())) {
                Optional<User> existEmail = userRepository.findByEmail(details.getEmail());
                if (existEmail.isPresent()) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Email đã tồn tại!");
                }
                user.setEmail(details.getEmail());
            }

            // Không cập nhật password và role ở đây để an toàn
            User savedUser = userRepository.save(user);

            // FIX LỖI 1: Sử dụng DTO để tránh lộ password đã mã hoá ở Response trả về cho
            // FE!
            return ResponseEntity.ok(new UserResponseDTO(savedUser));
        }).orElse(ResponseEntity.notFound().build());
    }

    // 5. Đổi mật khẩu (PATCH)
    @PatchMapping("/change-password/{id}")
    public ResponseEntity<?> changePassword(@PathVariable Long id, @RequestBody ChangePasswordRequest request) {
        String currentUserId = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findById(id).map(user -> {
            // FIX LỖI IDOR: Chặn đổi mật khẩu của người khác
            if (!user.getId().toString().equals(currentUserId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body("Lỗi bảo mật: Bạn không có quyền đổi mật khẩu của người khác!");
            }

            // BẮT BUỘC KIỂM TRA MẬT KHẨU CŨ TRƯỚC KHI ĐỔI
            if (request.getOldPassword() == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Vui lòng nhập mật khẩu cũ!");
            }
            if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())
                    && !request.getOldPassword().equals(user.getPassword())) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Mật khẩu cũ không chính xác!");
            }
            if (request.getNewPassword() == null || request.getNewPassword().trim().isEmpty()) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Mật khẩu mới không được để trống!");
            }
            if (!request.getNewPassword().equals(request.getConfirmPassword())) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Xác nhận mật khẩu mới không khớp!");
            }

            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            userRepository.save(user);
            return ResponseEntity.ok("Đổi mật khẩu thành công!");
        }).orElse(ResponseEntity.notFound().build());
    }
}