package com.example.demo.security;

import com.example.demo.repository.UserRepository;
import com.example.demo.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);

            if (jwtService.validateAccessToken(token)) {
                String userId = jwtService.extractUserId(token);
                Integer tokenVersionInJwt = jwtService.extractTokenVersion(token);

                // Lấy tokenVersion hiện tại từ DB
                var userOpt = userRepository.findById(Long.parseLong(userId));
                if (userOpt.isPresent()) {
                    int currentVersion = userOpt.get().getTokenVersion() != null
                            ? userOpt.get().getTokenVersion() : 0;

                    // Nếu version trong token KHÁC version trong DB → token đã bị logout
                    if (tokenVersionInJwt == null || tokenVersionInJwt != currentVersion) {
                        System.out.println("DEBUG: Token VERSION MISMATCH for user " + userId
                                + " — JWT version: " + tokenVersionInJwt
                                + ", DB version: " + currentVersion + " → Rejected 401");
                        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                        response.setContentType("application/json;charset=UTF-8");
                        response.getWriter().write("{\"error\": \"Token đã bị vô hiệu hóa. Vui lòng đăng nhập lại!\"}");
                        return;
                    }

                    String role = jwtService.extractRole(token);
                    if (role != null) {
                        role = role.toUpperCase();
                    }

                    System.out.println("DEBUG: Authenticated UserId: " + userId + ", Role: " + role
                            + ", TokenVersion: " + tokenVersionInJwt);

                    UsernamePasswordAuthenticationToken auth =
                            new UsernamePasswordAuthenticationToken(
                                    userId,
                                    null,
                                    List.of(new SimpleGrantedAuthority("ROLE_" + role))
                            );
                    SecurityContextHolder.getContext().setAuthentication(auth);
                } else {
                    // User không tồn tại trong DB
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write("{\"error\": \"User không tồn tại!\"}");
                    return;
                }
            }
        }

        filterChain.doFilter(request, response);
    }
}
