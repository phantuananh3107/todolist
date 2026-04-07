package com.example.demo.dto;

import lombok.*;

@Getter 
@Setter 
@NoArgsConstructor 
@AllArgsConstructor
public class ChatMessage {
    private String role; // "user", "assistant", hoặc "system"
    private String content;
}
