package com.example.demo.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class AdminUserRequest {
    private String username;
    private String email;
    private String role;
    private Boolean isActive;
    private String password;
    private String confirmPassword;
}
