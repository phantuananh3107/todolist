package com.example.demo.repository;

import com.example.demo.entity.Tasks;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Tasks, Long> {
    // Tìm kiếm task theo tiêu đề (Phục vụ chức năng Search của Tuấn Anh)
    List<Tasks> findByTitleContainingIgnoreCase(String title);

    // Lấy danh sách task của một user cụ thể và sắp xếp theo ngày (Sort)
    // Tasks entity dùng @ManyToOne User user, nên Spring Data JPA sẽ join qua user.id
    List<Tasks> findByUserIdOrderByDueDateAsc(Long userId);

    // Đếm số task của một user (dùng cho Admin stats, tối ưu hơn load toàn bộ list)
    long countByUserId(Long userId);
}