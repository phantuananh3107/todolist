package com.example.demo.dto;

import com.example.demo.entity.User;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UserResponseDTO {
    private Long id;
    private String username;
    private String email;
    private String role;
    private Boolean isActive;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private List<CategoryResponseDTO> categories;

    public UserResponseDTO(User user) {
        this.id = user.getId();
        this.username = user.getUsername();
        this.email = user.getEmail();
        this.role = user.getRole();
        this.isActive = user.getIsActive();
        this.isDeleted = user.getIsDeleted();
        this.createdAt = user.getCreatedAt();
        
        // Lọc các category chưa bị xoá (isActive = true)
        if (user.getCategories() != null) {
            this.categories = user.getCategories().stream()
                    .filter(c -> c.getIsActive() != null && c.getIsActive())
                    .map(CategoryResponseDTO::new)
                    .collect(Collectors.toList());
        }
    }
}
