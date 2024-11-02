/** doc-name: wren */
package wren_0_4

/** doc-header

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
when ODIN_OS == .Darwin  do foreign import "lib/macos/wren.a"

wren_h :: 1

VERSION_MAJOR       :: 0
VERSION_MINOR       :: 4
VERSION_RELEASE     :: 0
VERSION_RELEASE_STRING :: "0"

VERSION_NUMBER      :: VERSION_MAJOR * 1000000 + VERSION_MINOR * 1000 + VERSION_RELEASE
VERSION_STRING      :: "0.4"

VERSION             :: "Wren " + VERSION_STRING
RELEASE             :: VERSION + "." + VERSION_RELEASE_STRING
COPYRIGHT           :: RELEASE + "  Copyright (C) Wren.io, Bob Nystrom"
AUTHORS             :: "Made with ❤ by Bob Nystrom and friends."

// Mark for precompiled code ('<esc>Wren')
SIGNATURE :: "\x1bWren"

// Inspired by https://github.com/lumi-c/odin-wren

/**
A generic allocation function that handles all explicit memory management
used by Wren. It's used like so:

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

ErrorType :: ErrorTypeEnum

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

ForeignClassMethods :: ForeignClassMethodsStruct

/**
Returns a pair of pointers to the foreign methods used to allocate and
finalize the data for instances of [className] in resolved [module].
*/
BindForeignClassFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring) -> ForeignClassMethods

Configuration :: ConfigurationStruct
InterpretResult :: InterpretResultEnum
Type :: WrenTypeEnum

ErrorTypeEnum :: enum i32 {
    WREN_ERROR_COMPILE,
    WREN_ERROR_RUNTIME,
    WREN_ERROR_STACK_TRACE,
}

InterpretResultEnum :: enum i32 {
    WREN_RESULT_SUCCESS,
    WREN_RESULT_COMPILE_ERROR,
    WREN_RESULT_RUNTIME_ERROR,
}

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

VM :: struct {
    config: Configuration
}

Handle :: struct {}

LoadModuleResult :: struct {
    source : cstring,
    onComplete : LoadModuleCompleteFn,
    userData : rawptr,
}

ForeignClassMethodsStruct :: struct {
    allocate : ForeignMethodFn,
    finalize : FinalizerFn,
}

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


@(default_calling_convention="c")
/**
Main container for the Wren API.
- Since: 1.0.0
*/
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
    ReleaseHandle :: proc(vm : ^VM, handle : ^Handle) ---

    @(link_name="wrenGetSlotCount")
    GetSlotCount :: proc(vm : ^VM) -> _c.int ---

    @(link_name="wrenEnsureSlots")
    EnsureSlots :: proc(vm : ^VM, numSlots : _c.int) ---

    @(link_name="wrenGetSlotType")
    GetSlotType :: proc(vm : ^VM, slot : _c.int) -> Type ---

    @(link_name="wrenGetSlotBool")
    GetSlotBool :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> bool ---

    @(link_name="wrenGetSlotBytes")
    GetSlotBytes :: proc(
        vm : ^VM,
        slot : _c.int,
        length : ^_c.int,
    ) -> cstring ---

    @(link_name="wrenGetSlotDouble")
    GetSlotDouble :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> _c.double ---

    @(link_name="wrenGetSlotForeign")
    GetSlotForeign :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> rawptr ---

    @(link_name="wrenGetSlotString")
    GetSlotString :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> cstring ---

    @(link_name="wrenGetSlotHandle")
    GetSlotHandle :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> ^Handle ---

    @(link_name="wrenSetSlotBool")
    SetSlotBool :: proc(
        vm : ^VM,
        slot : _c.int,
        value : bool,
    ) ---

    @(link_name="wrenSetSlotBytes")
    SetSlotBytes :: proc(
        vm : ^VM,
        slot : _c.int,
        bytes : cstring,
        length : _c.size_t,
    ) ---

    @(link_name="wrenSetSlotDouble")
    SetSlotDouble :: proc(
        vm : ^VM,
        slot : _c.int,
        value : _c.double,
    ) ---

    @(link_name="wrenSetSlotNewForeign")
    SetSlotNewForeign :: proc(
        vm : ^VM,
        slot : _c.int,
        classSlot : _c.int,
        size : _c.size_t,
    ) -> rawptr ---

    @(link_name="wrenSetSlotNewList")
    SetSlotNewList :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenSetSlotNewMap")
    SetSlotNewMap :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenSetSlotNull")
    SetSlotNull :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenSetSlotString")
    SetSlotString :: proc(
        vm : ^VM,
        slot : _c.int,
        text : cstring,
    ) ---

    @(link_name="wrenSetSlotHandle")
    SetSlotHandle :: proc(
        vm : ^VM,
        slot : _c.int,
        handle : ^Handle,
    ) ---

    @(link_name="wrenGetListCount")
    GetListCount :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> _c.int ---

    @(link_name="wrenGetListElement")
    GetListElement :: proc(
        vm : ^VM,
        listSlot : _c.int,
        index : _c.int,
        elementSlot : _c.int,
    ) ---

    @(link_name="wrenSetListElement")
    SetListElement :: proc(
        vm : ^VM,
        listSlot : _c.int,
        index : _c.int,
        elementSlot : _c.int,
    ) ---

    @(link_name="wrenInsertInList")
    InsertInList :: proc(
        vm : ^VM,
        listSlot : _c.int,
        index : _c.int,
        elementSlot : _c.int,
    ) ---

    @(link_name="wrenGetMapCount")
    GetMapCount :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> _c.int ---

    @(link_name="wrenGetMapContainsKey")
    GetMapContainsKey :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
    ) -> bool ---

    @(link_name="wrenGetMapValue")
    GetMapValue :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
        valueSlot : _c.int,
    ) ---

    @(link_name="wrenSetMapValue")
    SetMapValue :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
        valueSlot : _c.int,
    ) ---

    @(link_name="wrenRemoveMapValue")
    RemoveMapValue :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
        removedValueSlot : _c.int,
    ) ---

    @(link_name="wrenGetVariable")
    GetVariable :: proc(
        vm : ^VM,
        module : cstring,
        name : cstring,
        slot : _c.int,
    ) ---

    @(link_name="wrenHasVariable")
    HasVariable :: proc(
        vm : ^VM,
        module : cstring,
        name : cstring,
    ) -> bool ---

    @(link_name="wrenHasModule")
    HasModule :: proc(
        vm : ^VM,
        module : cstring,
    ) -> bool ---

    @(link_name="wrenAbortFiber")
    AbortFiber :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenGetUserData")
    GetUserData :: proc(vm : ^VM) -> rawptr ---

    @(link_name="wrenSetUserData")
    SetUserData :: proc(
        vm : ^VM,
        userData : rawptr,
    ) ---

}
