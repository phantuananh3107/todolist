package com.example.demo.service;

import org.springframework.stereotype.Service;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TokenBlacklistService {
    // Sử dụng Set từ ConcurrentHashMap để đảm bảo thread-safe
    private final Set<String> blacklist = ConcurrentHashMap.newKeySet();

    /**
     * Thêm token vào danh sách đen
     */
    public void blacklistToken(String token) {
        if (token != null && token.startsWith("Bearer ")) {
            blacklist.add(token.substring(7));
        } else {
            blacklist.add(token);
        }
    }

    /**
     * Kiểm tra xem token có nằm trong danh sách đen không
     */
    public boolean isBlacklisted(String token) {
        if (token == null) return false;
        if (token.startsWith("Bearer ")) {
            return blacklist.contains(token.substring(7));
        }
        return blacklist.contains(token);
    }
}
