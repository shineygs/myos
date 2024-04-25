//
// Created by yang on 24-3-7.
//

#include "../include/idt.h"
#include "../include/syscall.h"
#include "../include/debug.h"
#include "../include/task.h"
#include "../include/stdio.h"
#include "../include/arena.h"
#include "../include/fs.h"

#define LOGK(fmt, args...) DEBUGK(fmt, ##args)

void idle_thread()
{
    set_interrupt_state(true);
    u32 counter = 0;
    while (true)
    {
//        LOGK("idle task.... %d\n", counter++);
        asm volatile(
                "sti\n" // 开中断
                "hlt\n" // 关闭 CPU，进入暂停状态，等待外中断的到来
                );
        yield(); // 放弃执行权，调度执行其他任务
    }
}

static void user_init_thread()
{

    fd_t fd = open("/world.txt", O_CREAT | O_RDWR, 0755);
    close(fd);

    while (true)
    {
        sleep(1000);
    }
}

extern task_t *running_task();

#include "../include/mutex.h"

lock_t lock;

extern u32 keyboard_read(char *buf, u32 count);

void init_thread()
{
    char temp[100]; // 为栈顶有足够的空间

//    set_interrupt_state(true);
//    test();

    task_to_user_mode(user_init_thread);
}

void test_thread()
{
    set_interrupt_state(true);
//     test();
//    link("/hello.txt", "/world.txt");
//    unlink("/hello.txt");

    while (true)
    {
        test();
        sleep(10);
    }
}