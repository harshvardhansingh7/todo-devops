package com.example.todo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.example.todo.model.Todo;

public interface TodoRepository extends JpaRepository<Todo, Long> {
}
