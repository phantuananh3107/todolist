package com.example.demo.repository;

import com.example.demo.entity.Tasks;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Tasks, Long> {
    // Tìm kiếm task theo tiêu đề (Phục vụ chức năng Search của Tuấn Anh)
    List<Tasks> findByTitleContainingIgnoreCase(String title);

    // Lấy danh sách task active của một user cụ thể và sắp xếp theo ngày (Sort)
    List<Tasks> findByUserIdAndIsActiveTrueOrderByDueDateAsc(Long userId);

    // Lấy danh sách task của user (không filter active)
    List<Tasks> findByUserIdOrderByDueDateAsc(Long userId);

    // Đếm số task active của một user
    long countByUserIdAndIsActiveTrue(Long userId);

    // Đếm số task của một user (không filter active)
    long countByUserId(Long userId);

    // Kiểm tra trùng tên Task trong cùng một Category
    boolean existsByTitleAndCategoryIdAndIsActiveTrue(String title, Long categoryId);

    // Lấy tất cả task active của một Category
    List<Tasks> findByCategoryIdAndIsActiveTrue(Long categoryId);

    // Tìm kiếm task theo tiêu đề cho user cụ thể
    List<Tasks> findByTitleContainingIgnoreCaseAndUserIdAndIsActiveTrue(String title, Long userId);

    // Tìm task theo priority và user
    List<Tasks> findByUserIdAndIsActiveTrueAndPriority(Long userId, String priority);

    // Tìm task theo status và user
    List<Tasks> findByUserIdAndIsActiveTrueAndStatus(Long userId, String status);
}