// This may look like C code, but it is really -*- C++ -*-
/* 
Copyright (C) 1988 Free Software Foundation
    written by Doug Lea (dl@rocky.oswego.edu)

This file is part of the GNU C++ Library.  This library is free
software; you can redistribute it and/or modify it under the terms of
the GNU Library General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your
option) any later version.  This library is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See the GNU Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifdef __GNUG__
#pragma implementation
#endif
#include <stream.h>
#include "<T>.<C>.RAVLMap.h"


/*
 constants & inlines for maintaining balance & thread status in tree nodes
*/

#define AVLBALANCEMASK    3
#define AVLBALANCED       0
#define AVLLEFTHEAVY      1
#define AVLRIGHTHEAVY     2

#define LTHREADBIT        4
#define RTHREADBIT        8


static inline int bf(<T><C>RAVLNode* t)
{
  return t->stat & AVLBALANCEMASK;
}

static inline void set_bf(<T><C>RAVLNode* t, int b)
{
  t->stat = (t->stat & ~AVLBALANCEMASK) | (b & AVLBALANCEMASK);
}


static inline int rthread(<T><C>RAVLNode* t)
{
  return t->stat & RTHREADBIT;
}

static inline void set_rthread(<T><C>RAVLNode* t, int b)
{
  if (b)
    t->stat |= RTHREADBIT;
  else
    t->stat &= ~RTHREADBIT;
}

static inline int lthread(<T><C>RAVLNode* t)
{
  return t->stat & LTHREADBIT;
}

static inline void set_lthread(<T><C>RAVLNode* t, int b)
{
  if (b)
    t->stat |= LTHREADBIT;
  else
    t->stat &= ~LTHREADBIT;
}

/*
 traversal primitives
*/


<T><C>RAVLNode* <T><C>RAVLMap::leftmost()
{
  <T><C>RAVLNode* t = root;
  if (t != 0) while (t->lt != 0) t = t->lt;
  return t;
}

<T><C>RAVLNode* <T><C>RAVLMap::rightmost()
{
  <T><C>RAVLNode* t = root;
  if (t != 0) while (t->rt != 0) t = t->rt;
  return t;
}

<T><C>RAVLNode* <T><C>RAVLMap::succ(<T><C>RAVLNode* t)
{
  <T><C>RAVLNode* r = t->rt;
  if (!rthread(t)) while (!lthread(r)) r = r->lt;
  return r;
}

<T><C>RAVLNode* <T><C>RAVLMap::pred(<T><C>RAVLNode* t)
{
  <T><C>RAVLNode* l = t->lt;
  if (!lthread(t)) while (!rthread(l)) l = l->rt;
  return l;
}


Pix <T><C>RAVLMap::seek(<T&> key)
{
  <T><C>RAVLNode* t = root;
  if (t == 0)
    return 0;
  for (;;)
  {
    int cmp = <T>CMP(key, t->item);
    if (cmp == 0)
      return Pix(t);
    else if (cmp < 0)
    {
      if (lthread(t))
        return 0;
      else
        t = t->lt;
    }
    else if (rthread(t))
      return 0;
    else
      t = t->rt;
  }
}


int <T><C>RAVLMap::rankof(<T&> key)
{
  int r;
  <T><C>RAVLNode* t = root;
  if (t == 0)
    return 0;
  for (r=t->rank; t != 0; r+=t->rank)
  {
    int cmp = <T>CMP(key, t->item);
    if (cmp == 0)
      return r;
    else if (cmp < 0)
    {
      if (lthread(t))
        return 0;
      else
      {
        r -= t->rank;  
        t = t->lt;
      }
    }
    else if (rthread(t))
      return 0;
    else
    {
      t = t->rt;
    }
  }
  return 0;
}

Pix <T><C>RAVLMap::ranktoPix(int i)
{
  int r;
  <T><C>RAVLNode* t = root;

  if ((i<1)||(i>count))
    return 0;
  for (r=t->rank; r!=i; r+=t->rank)
  {
    if (r>i)
    {
      r -= t->rank;
      t = t->lt;
    }
    else
      t = t->rt;
  }
  return Pix(t);
}

/*
 The combination of threads and AVL bits make adding & deleting
 interesting, but very awkward.

 We use the following statics to avoid passing them around recursively
*/

static int _need_rebalancing;   // to send back balance info from rec. calls
static <T>*   _target_item;     // add/del_item target
static <T><C>RAVLNode* _found_node; // returned added/deleted node
static int    _already_found;   // for deletion subcases
static int    _rank_changed;    // for rank computation


void <T><C>RAVLMap:: _add(<T><C>RAVLNode*& t)
{
  int cmp = <T>CMP(*_target_item, t->item);
  if (cmp == 0)
  {
    _found_node = t;
    return;
  }
  else if (cmp < 0)
  {
    if (lthread(t))
    {
      ++count;
      _found_node = new <T><C>RAVLNode(*_target_item, def);
      set_lthread(_found_node, 1);
      set_rthread(_found_node, 1);
      _found_node->lt = t->lt;
      _found_node->rt = t;
      t->lt = _found_node;
      set_lthread(t, 0);
      _need_rebalancing = 1;
      _rank_changed = 1;
    }
    else
      _add(t->lt);
    if (_rank_changed) ++t->rank;
    if (_need_rebalancing)
    {
      switch(bf(t))
      {
      case AVLRIGHTHEAVY:
        set_bf(t, AVLBALANCED);
        _need_rebalancing = 0;
        return;
      case AVLBALANCED:
        set_bf(t, AVLLEFTHEAVY);
        return;
      case AVLLEFTHEAVY:
	{
        <T><C>RAVLNode* l = t->lt;
        if (bf(l) == AVLLEFTHEAVY)
        {
	  t->rank -= l->rank;
          if (rthread(l))
            t->lt = l;
          else
            t->lt = l->rt;
          set_lthread(t, rthread(l));
          l->rt = t;
          set_rthread(l, 0);
          set_bf(t, AVLBALANCED);
          set_bf(l, AVLBALANCED);
          t = l;
          _need_rebalancing = 0;
        }
        else
        {
          <T><C>RAVLNode* r = l->rt;
	  r->rank += l->rank;
	  t->rank -= r->rank;
          set_rthread(l, lthread(r));
          if (lthread(r))
            l->rt = r;
          else
            l->rt = r->lt;
          r->lt = l;
          set_lthread(r, 0);
          set_lthread(t, rthread(r));
          if (rthread(r))
            t->lt = r;
          else
            t->lt = r->rt;
          r->rt = t;
          set_rthread(r, 0);
          if (bf(r) == AVLLEFTHEAVY)
            set_bf(t, AVLRIGHTHEAVY);
          else
            set_bf(t, AVLBALANCED);
          if (bf(r) == AVLRIGHTHEAVY)
            set_bf(l, AVLLEFTHEAVY);
          else
            set_bf(l, AVLBALANCED);
          set_bf(r, AVLBALANCED);
          t = r;
          _need_rebalancing = 0;
          return;
        }
	}
      }
    }
  }
  else
  {
    if (rthread(t))
    {
      ++count;
      _found_node = new <T><C>RAVLNode(*_target_item, def);
      set_rthread(t, 0);
      set_lthread(_found_node, 1);
      set_rthread(_found_node, 1);
      _found_node->lt = t;
      _found_node->rt = t->rt;
      t->rt = _found_node;
      _need_rebalancing = 1;
      _rank_changed = 1;
    }
    else
      _add(t->rt);
    if (_need_rebalancing)
    {
      switch(bf(t))
      {
      case AVLLEFTHEAVY:
        set_bf(t, AVLBALANCED);
        _need_rebalancing = 0;
        return;
      case AVLBALANCED:
        set_bf(t, AVLRIGHTHEAVY);
        return;
      case AVLRIGHTHEAVY:
	{
        <T><C>RAVLNode* r = t->rt;
        if (bf(r) == AVLRIGHTHEAVY)
        {
	  r->rank += t->rank;
          if (lthread(r))
            t->rt = r;
          else
            t->rt = r->lt;
          set_rthread(t, lthread(r));
          r->lt = t;
          set_lthread(r, 0);
          set_bf(t, AVLBALANCED);
          set_bf(r, AVLBALANCED);
          t = r;
          _need_rebalancing = 0;
        }
        else
        {
          <T><C>RAVLNode* l = r->lt;
	  r->rank -= l->rank;
	  l->rank += t->rank;
          set_lthread(r, rthread(l));
          if (rthread(l))
            r->lt = l;
          else
            r->lt = l->rt;
          l->rt = r;
          set_rthread(l, 0);
          set_rthread(t, lthread(l));
          if (lthread(l))
            t->rt = l;
          else
            t->rt = l->lt;
          l->lt = t;
          set_lthread(l, 0);
          if (bf(l) == AVLRIGHTHEAVY)
            set_bf(t, AVLLEFTHEAVY);
          else
            set_bf(t, AVLBALANCED);
          if (bf(l) == AVLLEFTHEAVY)
            set_bf(r, AVLRIGHTHEAVY);
          else
            set_bf(r, AVLBALANCED);
          set_bf(l, AVLBALANCED);
          t = l;
          _need_rebalancing = 0;
          return;
        }
	}
      }
    }
  }
}

    
<C>& <T><C>RAVLMap::operator [] (<T&> item)
{
  if (root == 0)
  {
    ++count;
    root = new <T><C>RAVLNode(item, def);
    set_rthread(root, 1);
    set_lthread(root, 1);
    return root->cont;
  }
  else
  {
    _target_item = &item;
    _need_rebalancing = 0;
    _rank_changed = 0;
    _add(root);
    return _found_node->cont;
  }
}


void <T><C>RAVLMap::_del(<T><C>RAVLNode* par, <T><C>RAVLNode*& t)
{
  int comp;
  if (_already_found)
  {
    if (rthread(t))
      comp = 0;
    else
      comp = 1;
  }
  else 
    comp = <T>CMP(*_target_item, t->item);
  if (comp == 0)
  {
    if (lthread(t) && rthread(t))
    {
      _found_node = t;
      if (t == par->lt)
      {
        set_lthread(par, 1);
        par->lt = t->lt;
      }
      else
      {
        set_rthread(par, 1);
        par->rt = t->rt;
      }
      _need_rebalancing = 1;
      _rank_changed = 1;
      return;
    }
    else if (lthread(t))
    {
      _found_node = t;
      <T><C>RAVLNode* s = succ(t);
      if (s != 0 && lthread(s))
        s->lt = t->lt;
      t = t->rt;
      _need_rebalancing = 1;
      _rank_changed = 1;
      return;
    }
    else if (rthread(t))
    {
      _found_node = t;
      <T><C>RAVLNode* p = pred(t);
      if (p != 0 && rthread(p))
        p->rt = t->rt;
      t = t->lt;
      _need_rebalancing = 1;
      _rank_changed = 1;
      return;
    }
    else                        // replace item & find someone deletable
    {
      <T><C>RAVLNode* p = pred(t);
      t->item = p->item;
      t->cont = p->cont;
      _already_found = 1;
      comp = -1;                // fall through below to left
    }
  }

  if (comp < 0)
  {
    if (lthread(t))
      return;
    _del(t, t->lt);
    if (_rank_changed) --t->rank;
    if (!_need_rebalancing)
      return;
    switch (bf(t))
    {
    case AVLLEFTHEAVY:
      set_bf(t, AVLBALANCED);
      return;
    case AVLBALANCED:
      set_bf(t, AVLRIGHTHEAVY);
      _need_rebalancing = 0;
      return;
    case AVLRIGHTHEAVY:
      {
      <T><C>RAVLNode* r = t->rt;
      switch (bf(r))
      {
      case AVLBALANCED:
	r->rank += t->rank;
        if (lthread(r))
          t->rt = r;
        else
          t->rt = r->lt;
        set_rthread(t, lthread(r));
        r->lt = t;
        set_lthread(r, 0);
        set_bf(t, AVLRIGHTHEAVY);
        set_bf(r, AVLLEFTHEAVY);
        _need_rebalancing = 0;
        t = r;
        return;
      case AVLRIGHTHEAVY:
	r->rank += t->rank;
        if (lthread(r))
          t->rt = r;
        else
          t->rt = r->lt;
        set_rthread(t, lthread(r));
        r->lt = t;
        set_lthread(r, 0);
        set_bf(t, AVLBALANCED);
        set_bf(r, AVLBALANCED);
        t = r;
        return;
      case AVLLEFTHEAVY:
	{
        <T><C>RAVLNode* l = r->lt;
	r->rank -= l->rank;
	l->rank += t->rank;
        set_lthread(r, rthread(l));
        if (rthread(l))
          r->lt = l;
        else
          r->lt = l->rt;
        l->rt = r;
        set_rthread(l, 0);
        set_rthread(t, lthread(l));
        if (lthread(l))
          t->rt = l;
        else
          t->rt = l->lt;
        l->lt = t;
        set_lthread(l, 0);
        if (bf(l) == AVLRIGHTHEAVY)
          set_bf(t, AVLLEFTHEAVY);
        else
          set_bf(t, AVLBALANCED);
        if (bf(l) == AVLLEFTHEAVY)
          set_bf(r, AVLRIGHTHEAVY);
        else
          set_bf(r, AVLBALANCED);
        set_bf(l, AVLBALANCED);
        t = l;
        return;
	}
      }
    }
    }
  }
  else
  {
    if (rthread(t))
      return;
    _del(t, t->rt);
    if (!_need_rebalancing)
      return;
    switch (bf(t))
    {
    case AVLRIGHTHEAVY:
      set_bf(t, AVLBALANCED);
      return;
    case AVLBALANCED:
      set_bf(t, AVLLEFTHEAVY);
      _need_rebalancing = 0;
      return;
    case AVLLEFTHEAVY:
      {
      <T><C>RAVLNode* l = t->lt;
      switch (bf(l))
      {
      case AVLBALANCED:
	t->rank -= l->rank;
        if (rthread(l))
          t->lt = l;
        else
          t->lt = l->rt;
        set_lthread(t, rthread(l));
        l->rt = t;
        set_rthread(l, 0);
        set_bf(t, AVLLEFTHEAVY);
        set_bf(l, AVLRIGHTHEAVY);
        _need_rebalancing = 0;
        t = l;
        return;
      case AVLLEFTHEAVY:
	t->rank -= l->rank;
        if (rthread(l))
          t->lt = l;
        else
          t->lt = l->rt;
        set_lthread(t, rthread(l));
        l->rt = t;
        set_rthread(l, 0);
        set_bf(t, AVLBALANCED);
        set_bf(l, AVLBALANCED);
        t = l;
        return;
      case AVLRIGHTHEAVY:
	{
        <T><C>RAVLNode* r = l->rt;
	r->rank += l->rank;
	t->rank -= r->rank;
        set_rthread(l, lthread(r));
        if (lthread(r))
          l->rt = r;
        else
          l->rt = r->lt;
        r->lt = l;
        set_lthread(r, 0);
        set_lthread(t, rthread(r));
        if (rthread(r))
          t->lt = r;
        else
          t->lt = r->rt;
        r->rt = t;
        set_rthread(r, 0);
        if (bf(r) == AVLLEFTHEAVY)
          set_bf(t, AVLRIGHTHEAVY);
        else
          set_bf(t, AVLBALANCED);
        if (bf(r) == AVLRIGHTHEAVY)
          set_bf(l, AVLLEFTHEAVY);
        else
          set_bf(l, AVLBALANCED);
        set_bf(r, AVLBALANCED);
        t = r;
        return;
	}
      }
      }
    }
  }
}


void <T><C>RAVLMap::del(<T&> item)
{
  if (root == 0) return;
  _need_rebalancing = 0;
  _already_found = 0;
  _found_node = 0;
  _rank_changed = 0;
  _target_item = &item;
  _del(root, root);
  if (_found_node)
  {
    delete(_found_node);
    if (--count == 0)
      root = 0;
  }
}

void <T><C>RAVLMap::_kill(<T><C>RAVLNode* t)
{
  if (t != 0)
  {
    if (!lthread(t)) _kill(t->lt);
    if (!rthread(t)) _kill(t->rt);
    delete t;
  }
}


<T><C>RAVLMap::<T><C>RAVLMap(<T><C>RAVLMap& b) :<T><C>Map(b.def)
{
  root = 0;
  count = 0;
  for (Pix i = b.first(); i != 0; b.next(i)) 
    (*this)[b.key(i)] = b.contents(i);
}


int <T><C>RAVLMap::OK()
{
  int v = 1;
  if (root == 0) 
    v = count == 0;
  else
  {
    int n = 1;
    <T><C>RAVLNode* trail = leftmost();
    v &= rankof(trail->item) == n;
    <T><C>RAVLNode* t = succ(trail);
    while (t != 0)
    {
      ++n;
      v &= <T>CMP(trail->item, t->item) < 0;
      v &= rankof(t->item) == n;
      trail = t;
      t = succ(t);
    }
    v &= n == count;
  }
  if (!v) error("invariant failure");
  return v;
}
