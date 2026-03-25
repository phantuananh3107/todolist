package com.example.demo.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateCategoryRequest {
    private String name; // Tên nhóm (Học tập, Công việc, Cá nhân...)
}

