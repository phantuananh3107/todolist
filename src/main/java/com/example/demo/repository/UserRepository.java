package com.example.demo.repository;

import com.example.demo.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Tìm người dùng bằng username để phục vụ Đăng nhập
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);

    // Tìm kiếm người dùng theo username hoặc email (có phân trang và lọc xoá mềm)
    @Query("SELECT u FROM User u WHERE (u.isDeleted IS NULL OR u.isDeleted = false) AND u.id <> :adminId AND " +
           "(:keyword IS NULL OR :keyword = '' OR " +
           "LOWER(u.username) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<User> searchUsers(@Param("keyword") String keyword, @Param("adminId") Long adminId, Pageable pageable);

}