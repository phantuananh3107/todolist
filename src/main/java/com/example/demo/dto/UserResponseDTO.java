package com.example.demo.dto;

import com.example.demo.entity.User;
import java.time.LocalDateTime;

public record UserResponseDTO(
        Long id,
        String username,
        String email,
        String role,
        Boolean isActive,
        Boolean isDeleted,
        LocalDateTime createdAt
) {
    public UserResponseDTO(User user) {
        this(
             user.getId(), 
             user.getUsername(), 
             user.getEmail(), 
             user.getRole(), 
             user.getIsActive(), 
             user.getIsDeleted(),
             user.getCreatedAt()
        );
    }
}
