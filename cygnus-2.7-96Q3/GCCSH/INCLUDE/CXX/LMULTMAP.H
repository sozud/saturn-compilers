/*
 *
 * Copyright (c) 1994
 * Hewlett-Packard Company
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Hewlett-Packard Company makes no
 * representations about the suitability of this software for any
 * purpose.  It is provided "as is" without express or implied warranty.
 *
 */

#ifndef LMULTIMAP_H
#define LMULTIMAP_H

#ifdef MULTIMAP_H
#undef MULTIMAP_H
#undef TREE_H
#define __MULTIMAP_WAS_DEFINED
#endif

#define Allocator long_allocator
#define multimap long_multimap
#define rb_tree long_rb_tree
#include <lngalloc.h>
#include <multimap.h>

#undef MULTIMAP_H
#undef TREE_H

#ifdef __MULTIMAP_WAS_DEFINED
#define MULTIMAP_H
#define TREE_H
#undef  __MULTIMAP_WAS_DEFINED
#endif

#undef Allocator
#undef multimap
#undef rb_tree

#endif
