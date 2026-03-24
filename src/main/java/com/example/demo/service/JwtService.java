package com.example.demo.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.access.secret}")
    private String accessSecret;

    @Value("${jwt.refresh.secret}")
    private String refreshSecret;

    @Value("${jwt.expires.in}")
    private long accessExpiration;

    @Value("${jwt.refresh.expires.in}")
    private long refreshExpiration;

    public String generateAccessToken(String userId) {
        return generateToken(userId, null, null, accessSecret, accessExpiration);
    }

    // Overload để truyền thêm role và tokenVersion vào token
    public String generateAccessToken(String userId, String role) {
        return generateToken(userId, role, null, accessSecret, accessExpiration);
    }

    public String generateAccessToken(String userId, String role, Integer tokenVersion) {
        return generateToken(userId, role, tokenVersion, accessSecret, accessExpiration);
    }

    public String generateRefreshToken(String userId) {
        return generateToken(userId, null, null, refreshSecret, refreshExpiration);
    }

    public String generateRefreshToken(String userId, Integer tokenVersion) {
        return generateToken(userId, null, tokenVersion, refreshSecret, refreshExpiration);
    }

    private String generateToken(String userId, String role, Integer tokenVersion, String secret, long expiration) {
        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        var builder = Jwts.builder()
                .subject(userId)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiration));
        if (role != null) {
            builder.claim("role", role);
        }
        if (tokenVersion != null) {
            builder.claim("tokenVersion", tokenVersion);
        }
        return builder.signWith(key).compact();
    }

    // Xác thực access token
    public boolean validateAccessToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(accessSecret.getBytes(StandardCharsets.UTF_8));
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    // Lấy userId từ access token
    public String extractUserId(String token) {
        return extractClaims(token, accessSecret).getSubject();
    }

    // Lấy role từ access token
    public String extractRole(String token) {
        Claims claims = extractClaims(token, accessSecret);
        return claims.get("role", String.class);
    }

    // Lấy tokenVersion từ access token
    public Integer extractTokenVersion(String token) {
        Claims claims = extractClaims(token, accessSecret);
        return claims.get("tokenVersion", Integer.class);
    }

    private Claims extractClaims(String token, String secret) {
        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
