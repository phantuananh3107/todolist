package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Entity
@Table(name = "Category")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Category {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // Học tập, Công việc, Cá nhân [cite: 140]

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user; // Chủ sở hữu loại công việc này [cite: 140]

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    private List<Tasks> tasks;
}