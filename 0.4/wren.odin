/** name: wren */
package wren_0_4

/** header

# Wren API Bindings

Wren is a small, fast, class-based concurrent scripting language

Think Smalltalk in a Lua-sized package with a dash of Erlang and wrapped up in
a familiar, modern syntax.

```js
System.print("Hello, world!")

class Wren {
  flyTo(city) {
    System.print("Flying to %(city)")
  }
}

var adjectives = Fiber.new {
  ["small", "clean", "fast"].each {|word| Fiber.yield(word) }
}

while (!adjectives.isDone) System.print(adjectives.call())
```

## Usage

See more complete examples at `example.odin` and `tests/wren_tests.odin`

```go
package main

import "core:fmt"

import wren "../vendor/wren/0.4"

main :: proc() {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    vm := wren.NewVM(&config)

    module : cstring = "main"
    script : cstring = `System.print("Hello Wren from Odin!")`
    result := wren.Interpret(vm, module, script)

    switch result {
        case .WREN_RESULT_COMPILE_ERROR:
            fmt.println("Compile error")
        case .WREN_RESULT_RUNTIME_ERROR:
            fmt.println("Runtime error")
        case .WREN_RESULT_SUCCESS:
            fmt.println("Success!")
    }
}
```
*/

import _c "core:c"

when ODIN_OS == .Windows do foreign import "lib/windows/wren.lib"
when ODIN_OS == .Linux   do foreign import "lib/linux/wren.a"
when ODIN_OS == .Darwin && ODIN_ARCH == .amd64 do foreign import "lib/macos/wren.a"
when ODIN_OS == .Darwin && ODIN_ARCH == .arm64 do foreign import "lib/macos-arm64/wren.a"

wren_h :: 1

/**
### Wren Constants
These constants contains information about the version.
*/

/**
Major version number
*/
VERSION_MAJOR       :: 0

/**
Minor version number
*/
VERSION_MINOR       :: 4

/**
Release version number
*/
VERSION_RELEASE     :: 0

VERSION_RELEASE_STRING :: "0"

VERSION_NUMBER      :: VERSION_MAJOR * 1000000 + VERSION_MINOR * 1000 + VERSION_RELEASE
VERSION_STRING      :: "0.4"

/**
A version with release number in string format
*/
VERSION_FULL_STRING :: "0.4.0"

VERSION             :: "Wren " + VERSION_STRING
RELEASE             :: VERSION + "." + VERSION_RELEASE_STRING
COPYRIGHT           :: RELEASE + "  Copyright (C) Wren.io, Bob Nystrom"
AUTHORS             :: "Made with ❤ by Bob Nystrom and friends."

// Mark for precompiled code ('<esc>Wren')
SIGNATURE :: "\x1bWren"

// Inspired by https://github.com/lumi-c/odin-wren

/**
### Enums
These enums hold different values used in Wren
*/

/**
Contains the errors types of Wren

- `WREN_ERROR_COMPILE`: A syntax or resolution error detected at compile time.
- `WREN_ERROR_RUNTIME`: The error message for a runtime error.
- `WREN_ERROR_STACK_TRACE`: One entry of a runtime error's stack trace.
*/
ErrorTypeEnum :: enum i32 {
	WREN_ERROR_COMPILE,
	WREN_ERROR_RUNTIME,
	WREN_ERROR_STACK_TRACE,
}

/**
Contains the result status when interpreting Wren code

- `WREN_RESULT_SUCCESS`: The result was completed successfully.
- `WREN_RESULT_COMPILE_ERROR`: The result could not be compiled. No interpretation of the code.
- `WREN_RESULT_RUNTIME_ERROR`: The code completed but something in the execution caused a runtime error.
*/
InterpretResultEnum :: enum i32 {
	WREN_RESULT_SUCCESS,
	WREN_RESULT_COMPILE_ERROR,
	WREN_RESULT_RUNTIME_ERROR,
}

/**
The type of an object stored in a slot.
This is not necessarily the object's *class*, but instead its low level
representation type.

- `WREN_TYPE_BOOL`: Boolean type.
- `WREN_TYPE_NUM`: Numeric type.
- `WREN_TYPE_FOREIGN`: Foreign type.
- `WREN_TYPE_LIST`: List type.
- `WREN_TYPE_MAP`: Map type.
- `WREN_TYPE_NULL`: NULL type.
- `WREN_TYPE_STRING`: String type.
- `WREN_TYPE_UNKNOWN`: The object is of a type that isn't accessible by the C API.
*/
WrenTypeEnum :: enum i32 {
	WREN_TYPE_BOOL,
	WREN_TYPE_NUM,
	WREN_TYPE_FOREIGN,
	WREN_TYPE_LIST,
	WREN_TYPE_MAP,
	WREN_TYPE_NULL,
	WREN_TYPE_STRING,
	WREN_TYPE_UNKNOWN,
}

/**
#### Enum Aliases
These aliases can be used in Odin.

- `ErrorType`: ErrorTypeEnum
- `InterpretResult`: InterpretResultEnum
- `Type`: WrenTypeEnum
*/

ErrorType :: ErrorTypeEnum
InterpretResult :: InterpretResultEnum
Type :: WrenTypeEnum


/**
### Structs
Contains the structs used by _Wren_.
*/

/**
A handle to a Wren object.
This lets code outside of the VM hold a persistent reference to an object.
After a handle is acquired, and until it is released, this ensures the
garbage collector will not reclaim the object it references.
*/
Handle :: struct {}

/**
The result of a loadModuleFn call.
- Description:
	- `source`: `cstring`: the source code for the module, or NULL if the module is not found.
 	- `onComplete`: `LoadModuleCompleteFn`: an optional callback that will be called once Wren is done with the result.
 	- `userData`: `rawptr`: an optional data holder created when calling _NewVM_.
*/
LoadModuleResult :: struct {
	source : cstring,
	onComplete : LoadModuleCompleteFn,
	userData : rawptr,
}

/**
A pair of pointers to the foreign methods used to allocate and
finalize the data for instances of `className` in resolved `module`.

- Description:
	- `allocate`: `ForeignMethodFn`: The callback invoked when the foreign object is created.
This must be provided. Inside the body of this, it must call
`wrenSetSlotNewForeign()` exactly once.

	- `finalize`: `FinalizerFn`: The callback invoked when the garbage collector is about to collect a foreign object's memory.
This may be `NULL` if the foreign class does not need to finalize.

*/
ForeignClassMethodsStruct :: struct {
	allocate : ForeignMethodFn,
	finalize : FinalizerFn,
}

/**
The Configuration structure to hold the data passed to the VM initialization.

- Description:
	- `reallocateFn`: `ReallocateFn`: The callback Wren will use to allocate, reallocate, and deallocate memory.
  If `NULL`, defaults to a built-in function that uses `realloc` and `free`.

	- `resolveModuleFn` : `ResolveModuleFn`: The callback Wren uses to resolve a module name.
	Some host applications may wish to support "relative" imports, where the
  meaning of an import string depends on the module that contains it. To
  support that without baking any policy into Wren itself, the VM gives the
  host a chance to resolve an import string.
	Before an import is loaded, it calls this, passing in the name of the
  module that contains the import and the import string. The host app can
  look at both of those and produce a new "canonical" string that uniquely
  identifies the module. This string is then used as the name of the module
  going forward. It is what is passed to [loadModuleFn], how duplicate
  imports of the same module are detected, and how the module is reported in
  stack traces.
	If you leave this function NULL, then the original import string is
  treated as the resolved string.
	If an import cannot be resolved by the embedder, it should return NULL and
  Wren will report that as a runtime error.
	Wren will take ownership of the string you return and free it for you, so
  it should be allocated using the same allocation function you provide
  above.

	- `loadModuleFn` : `LoadModuleFn`: The callback Wren uses to load a module.
	Since Wren does not talk directly to the file system, it relies on the
  embedder to physically locate and read the source code for a module. The
  first time an import appears, Wren will call this and pass in the name of
  the module being imported. The method will return a result, which contains
  the source code for that module. Memory for the source is owned by the
  host application, and can be freed using the onComplete callback.
	This will only be called once for any given module name. Wren caches the
  result internally so subsequent imports of the same module will use the
  previous source and not call this.
	If a module with the given name could not be found by the embedder, it
  should return NULL and Wren will report that as a runtime error.

	- `bindForeignMethodFn` : `BindForeignMethodFn`: The callback Wren uses to find a foreign method and bind it to a class.
	When a foreign method is declared in a class, this will be called with the
	foreign method's module, class, and signature when the class body is
	executed. It should return a pointer to the foreign function that will be
	bound to that method.
	If the foreign function could not be found, this should return NULL and
	Wren will report it as runtime error.

	- `bindForeignClassFn` : `BindForeignClassFn`: The callback Wren uses to find a foreign class and get its foreign methods.
	When a foreign class is declared, this will be called with the class's
	module and name when the class body is executed. It should return the
  foreign functions uses to allocate and (optionally) finalize the bytes
  stored in the foreign object when an instance is created.

	- `writeFn` : `WriteFn`: The callback Wren uses to display text when `System.print()` or the other
	related functions are called. If this is `NULL`, Wren discards any printed text.

	- `errorFn` : `ErrorFn`: The callback Wren uses to report errors.
	When an error occurs, this will be called with the module name, line
	number, and an error message. If this is `NULL`, Wren doesn't report any
  errors.

	- `initialHeapSize` : `_c.size_t`: The number of bytes Wren will allocate before triggering the first garbage
	collection. If zero, defaults to 10MB.

	- `minHeapSize` : `_c.size_t`: After a collection occurs, the threshold for the next collection is
	determined based on the number of bytes remaining in use. This allows Wren
  to shrink its memory usage automatically after reclaiming a large amount
  of memory.
	This can be used to ensure that the heap does not get too small, which can
  in turn lead to a large number of collections afterwards as the heap grows
  back to a usable size.
	If zero, defaults to 1MB.

	- `heapGrowthPercent` : `_c.int`: Wren will resize the heap automatically as the number of bytes
  remaining in use after a collection changes. This number determines the
  amount of additional memory Wren will use after a collection, as a
  percentage of the current heap size.
  For example, say that this is 50. After a garbage collection, when there
  are 400 bytes of memory still in use, the next collection will be triggered
  after a total of 600 bytes are allocated (including the 400 already in
  use.)
  Setting this to a smaller number wastes less memory, but triggers more
  frequent garbage collections.
  If zero, defaults to 50.

	- `userData` : `rawptr`: User-defined data associated with the VM.
*/
ConfigurationStruct :: struct {
	reallocateFn : ReallocateFn,
	resolveModuleFn : ResolveModuleFn,
	loadModuleFn : LoadModuleFn,
	bindForeignMethodFn : BindForeignMethodFn,
	bindForeignClassFn : BindForeignClassFn,
	writeFn : WriteFn,
	errorFn : ErrorFn,
	initialHeapSize : _c.size_t,
	minHeapSize : _c.size_t,
	heapGrowthPercent : _c.int,
	userData : rawptr,
}

/**
A single virtual machine for executing Wren code.
Wren has no global state, so all state stored by a running interpreter lives
here.

- Description:
	- `config`: The configuration struct filled with data.
*/
VM :: struct {
	config: Configuration
}

/**
#### Struct aliases

These aliases can be used for the structs.

- `ForeignClassMethods` : ForeignClassMethodsStruct
- `Configuration` : ConfigurationStruct
*/

ForeignClassMethods :: ForeignClassMethodsStruct
Configuration :: ConfigurationStruct

/**
### Callback Procedures
These procedures are called by Wren on its lifecycle
*/

/**
A generic allocation function that handles all explicit memory management
used by Wren. It's optional, if not set Wren will use a default one.
It's used like so:

- To allocate new memory, [memory] is NULL and [newSize] is the desired
  size. It should return the allocated memory or NULL on failure.

- To attempt to grow an existing allocation, [memory] is the memory, and
  [newSize] is the desired size. It should return [memory] if it was able to
  grow it in place, or a new pointer if it had to move it.

- To shrink memory, [memory] and [newSize] are the same as above but it will
  always return [memory].

- To free memory, [memory] will be the memory to free and [newSize] will be
  zero. It should return NULL.
*/
ReallocateFn :: #type proc "c" (memory: rawptr, newSize: u64, userData: rawptr) -> rawptr

/**
A function callable from Wren code, but implemented in C.
*/
ForeignMethodFn :: #type proc "c" (vm: ^VM)

/**
A finalizer function for freeing resources owned by an instance of a foreign
class. Unlike most foreign methods, finalizers do not have access to the VM
and should not interact with it since it's in the middle of a garbage
collection.
*/
FinalizerFn :: #type proc "c" (data: rawptr)

/**
Gives the host a chance to canonicalize the imported module name,
potentially taking into account the (previously resolved) name of the module
that contains the import. Typically, this is used to implement relative
imports.
*/
ResolveModuleFn :: #type proc "c" (vm: ^VM, importer: cstring, name: cstring) -> cstring

/**
Called after loadModuleFn is called for module [name]. The original returned result
is handed back to you in this callback, so that you can free memory if appropriate.
*/
LoadModuleCompleteFn :: #type proc "c" (vm: ^VM, name: cstring, result: LoadModuleResult)

/**
Loads and returns the source code for the module [name].
*/
LoadModuleFn :: #type proc "c" (vm: ^VM, name: cstring) -> LoadModuleResult

/**
Returns a pointer to a foreign method on [className] in [module] with
[signature].
*/
BindForeignMethodFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring, isStatic: bool, signature: cstring) -> ForeignMethodFn

/**
Displays a string of text to the user.
*/
WriteFn :: #type proc "c" (vm: ^VM, message: cstring)

/**
Reports an error to the user.

An error detected during compile time is reported by calling this once with
[type] `WREN_ERROR_COMPILE`, the resolved name of the [module] and [line]
where the error occurs, and the compiler's error [message].

A runtime error is reported by calling this once with [type]
`WREN_ERROR_RUNTIME`, no [module] or [line], and the runtime error's
[message]. After that, a series of [type] `WREN_ERROR_STACK_TRACE` calls are
made for each line in the stack trace. Each of those has the resolved
[module] and [line] where the method or function is defined and [message] is
the name of the method or function.
*/
ErrorFn :: #type proc "c" (vm: ^VM, type: ErrorType, module: cstring, line: _c.int, message: cstring)

/**
Returns a pair of pointers to the foreign methods used to allocate and
finalize the data for instances of [className] in resolved [module].
*/
BindForeignClassFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring) -> ForeignClassMethods


/**
### Procedures
Use the following procedures to interact with Wren's API.
*/

@(default_calling_convention="c")
foreign wren {

    @(link_name="wrenInitConfiguration")
		/**
		Initializes [configuration] with all of its default values.
		Call this before setting the particular fields you care about.
		*/
    InitConfiguration :: proc(configuration : ^Configuration) ---

    @(link_name="wrenNewVM")
		/**
		Creates a new Wren virtual machine using the given [configuration]. Wren
		will copy the configuration data, so the argument passed to this can be
		freed after calling this. If [configuration] is `NULL`, uses a default
		configuration.
		*/
    NewVM :: proc(configuration : ^Configuration) -> ^VM ---

    @(link_name="wrenFreeVM")
		/**
		Disposes of all resources is use by [vm], which was previously created by a
		call to [wrenNewVM].
		*/
    FreeVM :: proc(vm : ^VM) ---

    @(link_name="wrenCollectGarbage")
		/**
		Immediately run the garbage collector to free unused memory.
		*/
    CollectGarbage :: proc(vm : ^VM) ---

    @(link_name="wrenInterpret")
		/**
		Runs [source], a string of Wren source code in a new fiber in [vm] in the
		context of resolved [module].
		*/
    Interpret :: proc(vm : ^VM, module : cstring, source : cstring) -> InterpretResult ---

    @(link_name="wrenMakeCallHandle")
		/**
		Creates a handle that can be used to invoke a method with [signature] on
		using a receiver and arguments that are set up on the stack.

		This handle can be used repeatedly to directly invoke that method from C
		code using [wrenCall].

		When you are done with this handle, it must be released using
		[wrenReleaseHandle].
		*/
    MakeCallHandle :: proc(vm : ^VM, signature : cstring) -> ^Handle ---

    @(link_name="wrenCall")
		/**
		Calls [method], using the receiver and arguments previously set up on the stack.

		[method] must have been created by a call to [wrenMakeCallHandle]. The
		arguments to the method must be already on the stack. The receiver should be
		in slot 0 with the remaining arguments following it, in order. It is an
		error if the number of arguments provided does not match the method's
		signature.

		After this returns, you can access the return value from slot 0 on the stack.
		*/
    Call :: proc(vm : ^VM, method : ^Handle) -> InterpretResult ---

    @(link_name="wrenReleaseHandle")
		/**
		Releases the reference stored in [handle]. After calling this, [handle] can
		no longer be used.
		*/
    ReleaseHandle :: proc(vm : ^VM, handle : ^Handle) ---

    @(link_name="wrenGetSlotCount")
		/**
		The following functions are intended to be called from foreign methods or
		finalizers. The interface Wren provides to a foreign method is like a
		register machine: you are given a numbered array of slots that values can be
		read from and written to. Values always live in a slot (unless explicitly
		captured using wrenGetSlotHandle(), which ensures the garbage collector can
		find them.

		When your foreign function is called, you are given one slot for the receiver
		and each argument to the method. The receiver is in slot 0 and the arguments
		are in increasingly numbered slots after that. You are free to read and
		write to those slots as you want. If you want more slots to use as scratch
		space, you can call wrenEnsureSlots() to add more.

		When your function returns, every slot except slot zero is discarded and the
		value in slot zero is used as the return value of the method. If you don't
		store a return value in that slot yourself, it will retain its previous
		value, the receiver.

		While Wren is dynamically typed, C is not. This means the C interface has to
		support the various types of primitive values a Wren variable can hold: bool,
		double, string, etc. If we supported this for every operation in the C API,
		there would be a combinatorial explosion of functions, like "get a
		double-valued element from a list", "insert a string key and double value
		into a map", etc.

		To avoid that, the only way to convert to and from a raw C value is by going
		into and out of a slot. All other functions work with values already in a
		slot. So, to add an element to a list, you put the list in one slot, and the
		element in another. Then there is a single API function wrenInsertInList()
		that takes the element out of that slot and puts it into the list.

		The goal of this API is to be easy to use while not compromising performance.
		The latter means it does not do type or bounds checking at runtime except
		using assertions which are generally removed from release builds. C is an
		unsafe language, so it's up to you to be careful to use it correctly. In
		return, you get a very fast FFI.

		Returns the number of slots available to the current foreign method.
		*/
    GetSlotCount :: proc(vm : ^VM) -> _c.int ---

    @(link_name="wrenEnsureSlots")
		/**
		Ensures that the foreign method stack has at least [numSlots] available for
		use, growing the stack if needed.

		Does not shrink the stack if it has more than enough slots.
		It is an error to call this from a finalizer.
		*/
    EnsureSlots :: proc(vm : ^VM, numSlots : _c.int) ---

    @(link_name="wrenGetSlotType")
		/**
		Gets the type of the object in [slot].
		*/
    GetSlotType :: proc(vm : ^VM, slot : _c.int) -> Type ---

    @(link_name="wrenGetSlotBool")
		/**
		Reads a boolean value from [slot].
		It is an error to call this if the slot does not contain a boolean value.
		*/
    GetSlotBool :: proc(vm : ^VM, slot : _c.int) -> bool ---

    @(link_name="wrenGetSlotBytes")
		/**
		Reads a byte array from [slot].

		The memory for the returned string is owned by Wren. You can inspect it
		while in your foreign method, but cannot keep a pointer to it after the
		function returns, since the garbage collector may reclaim it.

		Returns a pointer to the first byte of the array and fill [length] with the
		number of bytes in the array.

		It is an error to call this if the slot does not contain a string.
		*/
    GetSlotBytes :: proc(vm : ^VM, slot : _c.int, length : ^_c.int) -> cstring ---

    @(link_name="wrenGetSlotDouble")
		/**
		Reads a number from [slot].
		It is an error to call this if the slot does not contain a number.
		*/
    GetSlotDouble :: proc(vm : ^VM, slot : _c.int) -> _c.double ---

    @(link_name="wrenGetSlotForeign")
		/**
		Reads a foreign object from [slot] and returns a pointer to the foreign data
		stored with it.

		It is an error to call this if the slot does not contain an instance of a
		foreign class.
		*/
    GetSlotForeign :: proc(vm : ^VM, slot : _c.int) -> rawptr ---

    @(link_name="wrenGetSlotString")
		/**
		Reads a string from [slot].

		The memory for the returned string is owned by Wren. You can inspect it
		while in your foreign method, but cannot keep a pointer to it after the
		function returns, since the garbage collector may reclaim it.

		It is an error to call this if the slot does not contain a string.
		*/
    GetSlotString :: proc(vm : ^VM, slot : _c.int) -> cstring ---

    @(link_name="wrenGetSlotHandle")
		/**
		Creates a handle for the value stored in [slot].

		This will prevent the object that is referred to from being garbage collected
		until the handle is released by calling [wrenReleaseHandle()].
		*/
    GetSlotHandle :: proc(vm : ^VM, slot : _c.int) -> ^Handle ---

    @(link_name="wrenSetSlotBool")
		/**
		Stores the boolean [value] in [slot].
		*/
    SetSlotBool :: proc(vm : ^VM, slot : _c.int, value : bool) ---

    @(link_name="wrenSetSlotBytes")
		/**
		Stores the array [length] of [bytes] in [slot].

		The bytes are copied to a new string within Wren's heap, so you can free
		memory used by them after this is called.
		*/
    SetSlotBytes :: proc(vm : ^VM, slot : _c.int, bytes : cstring, length : _c.size_t) ---

    @(link_name="wrenSetSlotDouble")
		/**
		Stores the numeric [value] in [slot].
		*/
    SetSlotDouble :: proc(vm : ^VM, slot : _c.int, value : _c.double) ---

    @(link_name="wrenSetSlotNewForeign")
		/**
		Creates a new instance of the foreign class stored in [classSlot] with [size]
		bytes of raw storage and places the resulting object in [slot].

		This does not invoke the foreign class's constructor on the new instance. If
		you need that to happen, call the constructor from Wren, which will then
		call the allocator foreign method. In there, call this to create the object
		and then the constructor will be invoked when the allocator returns.

		Returns a pointer to the foreign object's data.
		*/
    SetSlotNewForeign :: proc(vm : ^VM, slot : _c.int, classSlot : _c.int, size : _c.size_t) -> rawptr ---

    @(link_name="wrenSetSlotNewList")
		/**
		Stores a new empty list in [slot].
		*/
    SetSlotNewList :: proc(vm : ^VM, slot : _c.int) ---

    @(link_name="wrenSetSlotNewMap")
		/**
		Stores a new empty map in [slot].
		*/
    SetSlotNewMap :: proc(vm : ^VM, slot : _c.int) ---

    @(link_name="wrenSetSlotNull")
		/**
		Stores null in [slot].
		*/
    SetSlotNull :: proc(vm : ^VM, slot : _c.int) ---

    @(link_name="wrenSetSlotString")
		/**
		Stores the string [text] in [slot].

		The [text] is copied to a new string within Wren's heap, so you can free
		memory used by it after this is called. The length is calculated using
		[strlen()]. If the string may contain any null bytes in the middle, then you
		should use [wrenSetSlotBytes()] instead.
		*/
    SetSlotString :: proc(vm : ^VM, slot : _c.int, text : cstring) ---

    @(link_name="wrenSetSlotHandle")
		/**
		Stores the value captured in [handle] in [slot].

		This does not release the handle for the value.
		*/
    SetSlotHandle :: proc(vm : ^VM, slot : _c.int, handle : ^Handle) ---

    @(link_name="wrenGetListCount")
		/**
		Returns the number of elements in the list stored in [slot].
		*/
    GetListCount :: proc(vm : ^VM, slot : _c.int) -> _c.int ---

    @(link_name="wrenGetListElement")
		/**
		Reads element [index] from the list in [listSlot] and stores it in [elementSlot].
		*/
    GetListElement :: proc(vm : ^VM, listSlot : _c.int, index : _c.int, elementSlot : _c.int) ---

    @(link_name="wrenSetListElement")
		/**
		Sets the value stored at [index] in the list at [listSlot],
		to the value from [elementSlot].
		*/
    SetListElement :: proc(vm : ^VM, listSlot : _c.int, index : _c.int, elementSlot : _c.int) ---

    @(link_name="wrenInsertInList")
		/**
		Takes the value stored at [elementSlot] and inserts it into the list stored at [listSlot] at [index].
		As in Wren, negative indexes can be used to insert from the end. To append
		an element, use `-1` for the index.
		*/
    InsertInList :: proc(vm : ^VM, listSlot : _c.int, index : _c.int, elementSlot : _c.int) ---

    @(link_name="wrenGetMapCount")
		/**
		Returns the number of entries in the map stored in [slot].
		*/
    GetMapCount :: proc(vm : ^VM, slot : _c.int) -> _c.int ---

    @(link_name="wrenGetMapContainsKey")
		/**
		Returns true if the key in [keySlot] is found in the map placed in [mapSlot].
		*/
    GetMapContainsKey :: proc(vm : ^VM, mapSlot : _c.int, keySlot : _c.int) -> bool ---

    @(link_name="wrenGetMapValue")
		/**
		Retrieves a value with the key in [keySlot] from the map in [mapSlot] and
		stores it in [valueSlot].
		*/
    GetMapValue :: proc(vm : ^VM, mapSlot : _c.int, keySlot : _c.int, valueSlot : _c.int) ---

    @(link_name="wrenSetMapValue")
		/**
		Takes the value stored at [valueSlot] and inserts it into the map stored
		at [mapSlot] with key [keySlot].
		*/
    SetMapValue :: proc(vm : ^VM, mapSlot : _c.int, keySlot : _c.int, valueSlot : _c.int) ---

    @(link_name="wrenRemoveMapValue")
		/**
		Removes a value from the map in [mapSlot], with the key from [keySlot],
		and place it in [removedValueSlot]. If not found, [removedValueSlot] is
		set to null, the same behaviour as the Wren Map API.
		*/
    RemoveMapValue :: proc(vm : ^VM, mapSlot : _c.int, keySlot : _c.int, removedValueSlot : _c.int) ---

    @(link_name="wrenGetVariable")
		/**
		Looks up the top level variable with [name] in resolved [module] and stores
		it in [slot].
		*/
    GetVariable :: proc(vm : ^VM, module : cstring, name : cstring, slot : _c.int) ---

    @(link_name="wrenHasVariable")
		/**
		Looks up the top level variable with [name] in resolved [module],
		returns false if not found. The module must be imported at the time,
		use wrenHasModule to ensure that before calling.
		*/
    HasVariable :: proc(vm : ^VM, module : cstring, name : cstring) -> bool ---

    @(link_name="wrenHasModule")
		/**
		Returns true if [module] has been imported/resolved before, false if not.
		*/
    HasModule :: proc(vm : ^VM, module : cstring) -> bool ---

    @(link_name="wrenAbortFiber")
		/**
		Sets the current fiber to be aborted, and uses the value in [slot] as the
		runtime error object.
		*/
    AbortFiber :: proc(vm : ^VM, slot : _c.int) ---

    @(link_name="wrenGetUserData")
		/**
		Returns the user data associated with the WrenVM.
		*/
    GetUserData :: proc(vm : ^VM) -> rawptr ---

    @(link_name="wrenSetUserData")
		/**
		Sets user data associated with the WrenVM.
		*/
    SetUserData :: proc(vm : ^VM, userData : rawptr) ---

		@(link_name="wrenGetVersionNumber")
		/**
		Get the current wren version number.
		Can be used to range checks over versions.
		*/
		GetVersionNumber :: proc() ---
}
