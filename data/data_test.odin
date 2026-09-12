package data

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:sync"
import "core:testing"
import "core:thread"

// Regression tests for the two defects this module used to have, both fixed at
// the same time (they are documented in lib-day-trade-c/docs/arquitectura.md):
//
//  1. `load_data` / `save_data` freed their temporaries with `context.allocator`
//     instead of the allocator they had been given in the argument (`delete(x)`
//     on a slice uses the ambient allocator, because slices do not carry their
//     allocator). A caller that passes its own arena while the context stays on
//     the heap got the arena's whole block handed back to the heap, and
//     destroying the arena aborted the process: "free(): invalid pointer".
//  2. `_init_json_marshalers` guarded the one-time registration of the float
//     marshaler with a plain boolean, so two threads saving at the same time both
//     registered and the second one aborted the process:
//     "set_user_marshalers must not be called more than once".
//
// Both tests fail (the second one by aborting) if either fix is reverted, but they
// have to be run serially:
//
//     odin test data -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_TRACK_MEMORY=false
//
// With the default four test threads, the malloc traffic of the concurrent test
// hides the corruption the first one is looking for (checked: with one thread it
// aborts with "double free or corruption", with four it slips through).

TEST_DIR :: #directory + "../build/tmp"

_test_dir :: proc(t: ^testing.T) {
	if os.exists(TEST_DIR) {
		return
	}
	err := os.make_directory_all(TEST_DIR)
	if err != os.ERROR_NONE && !os.exists(TEST_DIR) {
		testing.fail_now(t, "cannot create " + TEST_DIR)
	}
}

// The context stays on the heap while the module gets an arena of its own: that
// mismatch is what used to go wrong. The load below has to be the *first*
// allocation in a brand-new arena, because that is the case that fails hard: the
// file contents start at the arena's block, so handing them back to the heap
// frees the whole block, and destroying the arena then frees it a second time and
// the process aborts. (Freeing an interior allocation with the wrong allocator is
// also undefined behaviour, but it only *sometimes* blows up, so it would be a
// flaky test.)
@(test)
load_and_save_with_a_foreign_allocator :: proc(t: ^testing.T) {
	_test_dir(t)
	path := TEST_DIR + "/foreign_allocator.json"
	defer os.remove(path)

	json_text :: `{"accounts":[{"name":"Default","broker_index":0,"trades":[]}],` +
		`"active_account":0,` +
		`"brokers":[{"name":"broker","alias":"b","futures_database":[],"cfds_database":[],"forex_database":[]}],` +
		`"active_broker":0}`
	testing.expect_value(t, os.write_entire_file(path, json_text), os.ERROR_NONE)

	previous_allocator := context.allocator
	context.allocator = runtime.heap_allocator()
	defer context.allocator = previous_allocator

	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, runtime.heap_allocator(), runtime.heap_allocator())
	alloc := mem.dynamic_arena_allocator(&arena)

	loaded, ok := load_data(path, alloc)
	testing.expect(t, ok, "load_data with a foreign allocator")
	testing.expect_value(t, len(loaded.accounts), 1)
	testing.expect_value(t, len(loaded.brokers), 1)

	// Reaching here means the temporaries were given back to the allocator they
	// came from; otherwise the arena's block would already be gone and freeing it
	// here would abort. That is exactly what the old `defer delete(content)` did.
	//
	// This test deliberately does NOT call save_data: the marshaler registration
	// can only happen once per process, so the test below (which does save, from
	// eight threads) has to be the one that gets there first. Otherwise the race
	// it exercises would already be over.
	mem.dynamic_arena_destroy(&arena)
}

_SAVE_THREADS :: 8

_save_job :: struct {
	data:  Data,
	path:  string,
	gate:  ^bool,
	arena: ^mem.Dynamic_Arena,
}

_save_paths: [_SAVE_THREADS][96]u8
_save_arenas: [_SAVE_THREADS]mem.Dynamic_Arena

_save_worker :: proc(job: ^_save_job) {
	// The barrier matters: without it the threads arrive one by one and the first
	// one registers the marshaler before the others get there, so the race does
	// not show. With it, all of them call save_data at the same moment.
	//
	// Everything else is prepared by the test beforehand on purpose. If the worker
	// had to build its arena and its data first, the threads would drift apart
	// (each malloc serialises them) and by the time the second one reached the
	// registration the first one would already be done: the race is a few
	// microseconds wide.
	for !sync.atomic_load(job.gate) {
		thread.yield()
	}
	save_data(job.path, job.data, mem.dynamic_arena_allocator(job.arena))
}

@(test)
concurrent_saves_register_the_marshaler_once :: proc(t: ^testing.T) {
	_test_dir(t)

	// Each worker gets its own arena and its own data, with the context left on
	// the heap: that also covers the allocator fix on the way out (save_data used
	// to free the JSON buffer with context.allocator).
	jobs: [_SAVE_THREADS]_save_job
	gate := false
	for i in 0 ..< _SAVE_THREADS {
		mem.dynamic_arena_init(&_save_arenas[i], runtime.heap_allocator(), runtime.heap_allocator())
		alloc := mem.dynamic_arena_allocator(&_save_arenas[i])
		path := fmt.bprintf(_save_paths[i][:], "%s/thread_%d.json", TEST_DIR, i)
		jobs[i] = {
			data  = new_default_data(alloc),
			path  = path,
			gate  = &gate,
			arena = &_save_arenas[i],
		}
	}

	threads: [_SAVE_THREADS]^thread.Thread
	for i in 0 ..< _SAVE_THREADS {
		threads[i] = thread.create_and_start_with_poly_data(&jobs[i], _save_worker)
	}
	sync.atomic_store(&gate, true)

	for i in 0 ..< _SAVE_THREADS {
		thread.join(threads[i])
		thread.destroy(threads[i])
	}

	// Reaching this point is the assertion: with the boolean guard the process
	// aborted before. Each thread's file also has to be there.
	for i in 0 ..< _SAVE_THREADS {
		testing.expect(t, os.exists(jobs[i].path), "every thread wrote its file")
		os.remove(jobs[i].path)
		mem.dynamic_arena_destroy(&_save_arenas[i])
	}
}
