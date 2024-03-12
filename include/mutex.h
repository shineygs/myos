//
// Created by yang on 24-3-9.
//

#ifndef MYOS_MUTEX_H
#define MYOS_MUTEX_H

#include "types.h"
#include "list.h"

typedef struct mutex_t
{
    bool value;     // 信号量
    list_t waiters; // 等待队列
} mutex_t;

typedef struct lock_t
{
    struct task_t *holder; // 持有者
    mutex_t mutex;         // 互斥量
    u32 repeat;            // 重入次数
} lock_t;

void lock_init(lock_t *lock);   // 锁初始化
void lock_acquire(lock_t *lock);   // 加锁
void lock_release(lock_t *lock); // 解锁

void mutex_init(mutex_t *mutex);   // 初始化互斥量
void mutex_lock(mutex_t *mutex);   // 尝试持有互斥量
void mutex_unlock(mutex_t *mutex); // 释放互斥量

#endif //MYOS_MUTEX_H
