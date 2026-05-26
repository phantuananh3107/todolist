package com.example.demo.controller;

import com.example.demo.dto.ChatRequest;
import com.example.demo.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@PreAuthorize("isAuthenticated()")
public class ChatController {

    @Autowired
    private ChatService chatService;

    /**
     * Gửi tin nhắn cho chatbot AI
     * POST /api/chat
     */
    @PostMapping
    public ResponseEntity<?> chat(@RequestBody ChatRequest request) {
        String userIdStr = SecurityContextHolder.getContext().getAuthentication().getName();
        Long userId = Long.parseLong(userIdStr);
        
        String response = chatService.generateChatResponse(userId, request);
        
        // Trả về định dạng JSON { "response": "..." }
        return ResponseEntity.ok(Map.of("response", response));
    }
}
