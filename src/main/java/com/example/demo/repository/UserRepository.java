package com.example.demo.repository;

import com.example.demo.dto.UserStatsDTO;
import com.example.demo.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Tìm người dùng bằng username để phục vụ Đăng nhập
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);

    // Tìm kiếm người dùng theo username hoặc email (có phân trang và lọc xoá mềm)
    @Query("SELECT u FROM User u WHERE u.isDeleted = false AND u.id <> :adminId AND " +
           "(:keyword IS NULL OR :keyword = '' OR " +
           "LOWER(u.username) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<User> searchUsers(@Param("keyword") String keyword, @Param("adminId") Long adminId, Pageable pageable);

    // Tối ưu API đếm task bằng cách đếm thẳng từ database (tránh N+1 Query)
    @Query("SELECT new com.example.demo.dto.UserStatsDTO(u.username, COUNT(t.id), " +
           "SUM(CASE WHEN t.status = com.example.demo.entity.Tasks$Status.DONE THEN 1L ELSE 0L END), " +
           "SUM(CASE WHEN t.status != com.example.demo.entity.Tasks$Status.DONE AND t.id IS NOT NULL THEN 1L ELSE 0L END)) " +
           "FROM User u LEFT JOIN Tasks t ON t.user.id = u.id " +
           "WHERE u.isDeleted = false " +
           "GROUP BY u.username")
    List<UserStatsDTO> getUserTaskStats();
}