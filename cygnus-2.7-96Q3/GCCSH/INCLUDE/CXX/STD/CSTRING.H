// The -*- C++ -*- null-terminated string header.
// This file is part of the GNU ANSI C++ Library.

#ifndef __CSTRING__
#define __CSTRING__

#include <string.h>

#if 0 // Let's not bother with this just yet.
#include <std/cstddef.h>

#ifdef __GNUG__
#pragma interface "std/cstring.h"
#endif

// The ANSI C prototypes for these functions have a const argument type and
// non-const return type, so we can't use them.

extern "C++" {
extern inline const char *
_G_strchr (const char *s, int c)
{
  return strchr (s, c);
}

extern inline char *
_G_strchr (char *s, int c)
{
  return const_cast<char *> (strchr (s, c));
}

extern inline const char *
_G_strpbrk (const char *s1, const char *s2)
{
  return strpbrk (s1, s2);
}

extern inline char *
_G_strpbrk (char *s1, const char *s2)
{
  return const_cast<char *> (strpbrk (s1, s2));
}

extern inline const char *
_G_strrchr (const char *s, int c)
{
  return strrchr (s, c);
}

extern inline char *
_G_strrchr (char *s, int c)
{
  return const_cast<char *> (strrchr (s, c));
}

extern inline const char *
_G_strstr (const char *s1, const char *s2)
{
  return strstr (s1, s2);
}

extern inline char *
_G_strstr (char *s1, const char *s2)
{
  return const_cast<char *> (strstr (s1, s2));
}

extern inline const void *
_G_memchr (const void *s, int c, size_t n)
{
  return memchr (s, c, n);
}

extern inline void *
_G_memchr (void *s, int c, size_t n)
{
  return const_cast<void *> (memchr (s, c, n));
}
} // extern "C++"

// Lose any vendor macros for these functions.
#undef strchr
#undef strpbrk
#undef strrchr
#undef strstr
#undef memchr

// Ewww, namespace pollution.  Anyone have a better idea?
#define strchr  _G_strchr
#define strpbrk _G_strpbrk
#define strrchr _G_strrchr
#define strstr  _G_strstr
#define memchr  _G_memchr
#endif // 0

#endif // !defined (__CSTRING__)
