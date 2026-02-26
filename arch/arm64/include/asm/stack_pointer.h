/* SPDX-License-Identifier: GPL-2.0 */
#ifndef __ASM_STACK_POINTER_H
#define __ASM_STACK_POINTER_H

/*
 * how to get the current stack pointer from C
 */
#if defined(__GNUC__) && !defined(__clang__)
register unsigned long current_stack_pointer asm ("sp");
#endif

#endif /* __ASM_STACK_POINTER_H */
