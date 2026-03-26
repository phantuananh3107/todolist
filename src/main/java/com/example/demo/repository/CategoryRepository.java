package com.example.demo.repository;

import com.example.demo.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
    // Lấy danh sách categories active của user
    List<Category> findByUserIdAndIsActiveTrue(Long userId);

    // Lấy categories của user (không filter active)
    List<Category> findByUserId(Long userId);

    // Kiểm tra trùng tên Category cho một User
    boolean existsByNameAndUserIdAndIsActiveTrue(String name, Long userId);

    // Tìm kiếm Category theo tên (ignore case)
    List<Category> findByNameContainingIgnoreCaseAndUserIdAndIsActiveTrue(String name, Long userId);
}